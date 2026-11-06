import asyncio
from fastapi import APIRouter, Depends, Request
from fastapi.responses import HTMLResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.auth import require_auth
from app.models import CD, Track
from app.services.discogs_client import get_user_collection, get_release
from app.services.image_downloader import download_cover

router = APIRouter(prefix="/import", tags=["import"])

def _notes_to_str(notes):
    if not notes:
        return None
    if isinstance(notes, str):
        return notes or None
    if isinstance(notes, list):
        parts = [str(n.get("value", "")).strip() for n in notes if isinstance(n, dict) and n.get("value")]
        return " | ".join(parts) or None
    return str(notes)

def _detect_format(formats):
    import re
    names = []
    for f in formats or []:
        if isinstance(f, dict):
            name = (f.get("name") or "").lower()
            descs = " ".join(str(d).lower() for d in f.get("descriptions", []))
            names.append(f"{name} {descs}")
    blob = " ".join(names)
    tokens = set(re.findall(r"[a-z0-9]+", blob))
    if "vinyl" in tokens or "lp" in tokens or '12"' in blob or '7"' in blob:
        return "Vinyle"
    if "cassette" in tokens or "cass" in tokens:
        return "Cassette"
    if "minidisc" in tokens or ("mini" in tokens and "disc" in tokens):
        return "MiniDisc"
    if "cd" in tokens or "cdp" in tokens:
        return "CD"
    if "dvd" in tokens:
        return "DVD"
    return "CD"


@router.get("/discogs", response_class=HTMLResponse)
async def import_page(request: Request):
    require_auth(request)
    return request.app.state.templates.TemplateResponse("import_discogs.html", {"request": request})

@router.post("/discogs/{username}")
async def import_collection(username: str, request: Request, db: AsyncSession = Depends(get_db)):
    require_auth(request)
    imported = 0
    skipped = 0
    page = 1
    while True:
        data = await get_user_collection(username, page=page)
        releases = data.get("releases", [])
        if not releases:
            break
        for item in releases:
            bi = item.get("basic_information") if item else None
            if not bi or "id" not in bi:
                continue
            release_id = bi["id"]
            existing = await db.execute(select(CD).where(CD.discogs_release_id == release_id))
            if existing.scalar_one_or_none():
                skipped += 1
                continue
            await asyncio.sleep(1.1)
            details = await get_release(release_id)
            cover_url = details["images"][0].get("resource_url", "") if details.get("images") else ""
            cover_path = await download_cover(cover_url)
            main_format = _detect_format(details.get("formats", []))
            cd = CD(
                discogs_release_id=release_id,
                title=details.get("title", "Unknown"),
                artist=details.get("artists", [{}])[0].get("name", "Unknown") if details.get("artists") else "Unknown",
                label=details.get("labels", [{}])[0].get("name", "") if details.get("labels") else "",
                catalog_number=details.get("labels", [{}])[0].get("cat_no", "") if details.get("labels") else "",
                year=details.get("year"), format=main_format,
                genre=", ".join(details.get("genres", [])),
                style=", ".join(details.get("styles", [])),
                condition=item.get("rating", None),
                notes=_notes_to_str(item.get("notes")),
                cover_image_path=cover_path, discogs_url=details.get("uri", ""),
                ean=next((b["value"] for b in details.get("identifiers", []) if b.get("type") == "Barcode"), None),
            )
            db.add(cd)
            await db.flush()
            for track in details.get("tracklist", []):
                db.add(Track(cd_id=cd.id, position=track.get("position", ""),
                             title=track.get("title", ""), duration=track.get("duration", "")))
            imported += 1
        await db.commit()
        pagination = data.get("pagination", {})
        if page >= pagination.get("pages", 1):
            break
        page += 1
        await asyncio.sleep(1.1)
    await db.commit()
    return {"imported": imported, "skipped": skipped}
