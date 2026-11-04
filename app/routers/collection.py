from fastapi import APIRouter, Depends, Request, Query, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_, desc, asc
from sqlalchemy.orm import selectinload
from app.database import get_db
from app.auth import require_auth
from app.models import CD, Track
from app.services.image_downloader import download_cover
from app.services.discogs_client import get_release, search_by_barcode
from app.services.musicbrainz_client import lookup_by_barcode, get_release_details

router = APIRouter(tags=["collection"])

async def get_cd_with_relations(db, cd_id):
    result = await db.execute(
        select(CD).options(selectinload(CD.tracks), selectinload(CD.tags)).where(CD.id == cd_id))
    return result.scalar_one_or_none()

@router.get("/add", response_class=HTMLResponse)
async def add_page(request: Request, ean: str = Query(None)):
    require_auth(request)
    return request.app.state.templates.TemplateResponse("add_cd.html", {"request": request, "ean": ean})

@router.get("/scan", response_class=HTMLResponse)
async def scan_page(request: Request):
    require_auth(request)
    return request.app.state.templates.TemplateResponse("scan.html", {"request": request})

@router.get("/collection", response_class=HTMLResponse)
async def list_collection(request: Request, db: AsyncSession = Depends(get_db),
    q: str = Query(None), format: str = Query(None), genre: str = Query(None),
    artist: str = Query(None), artist_q: str = Query(None),
    sort: str = Query("date_desc"), page: int = Query(1, ge=1), per_page: int = Query(24)):
    require_auth(request)
    if per_page not in (24, 48, 96, 192):
        per_page = 24
    query = select(CD).options(selectinload(CD.tracks)).where(CD.in_wantlist == 0)
    count_query = select(func.count()).select_from(CD).where(CD.in_wantlist == 0)
    if q:
        like = f"%{q}%"
        condition = or_(CD.title.ilike(like), CD.artist.ilike(like), CD.label.ilike(like),
                        CD.catalog_number.ilike(like), CD.ean.ilike(like))
        query = query.where(condition); count_query = count_query.where(condition)
    if format:
        query = query.where(CD.format == format); count_query = count_query.where(CD.format == format)
    if genre:
        query = query.where(CD.genre.ilike(f"%{genre}%")); count_query = count_query.where(CD.genre.ilike(f"%{genre}%"))
    if artist:
        query = query.where(CD.artist == artist); count_query = count_query.where(CD.artist == artist)
    if artist_q:
        query = query.where(CD.artist.ilike(f"%{artist_q}%")); count_query = count_query.where(CD.artist.ilike(f"%{artist_q}%"))
    sort_map = {"date_desc": desc(CD.date_added), "date_asc": asc(CD.date_added),
                "artist_asc": asc(CD.artist_sort), "artist_desc": desc(CD.artist_sort),
                "year_desc": desc(CD.year), "year_asc": asc(CD.year),
                "title_asc": asc(CD.title_sort), "title_desc": desc(CD.title_sort)}
    query = query.order_by(sort_map.get(sort, desc(CD.date_added)))
    total = (await db.execute(count_query)).scalar() or 0
    total_pages = max(1, (total + per_page - 1) // per_page)
    page = min(page, total_pages)
    query = query.offset((page - 1) * per_page).limit(per_page)
    cds = (await db.execute(query)).scalars().all()
    genres = [g for (g,) in (await db.execute(select(CD.genre).where(CD.genre.isnot(None)).distinct())).all() if g]
    artists = [a for (a,) in (await db.execute(select(CD.artist).where(CD.artist.isnot(None)).distinct().order_by(CD.artist))).all() if a]
    context = {"request": request, "cds": cds, "query": q or "", "format_filter": format or "",
               "genre_filter": genre or "", "artist_filter": artist or "", "artist_q": artist_q or "",
               "sort": sort, "page": page, "total_pages": total_pages, "total_count": total,
               "per_page": per_page, "genres": sorted(genres), "artists": artists}
    if request.headers.get("HX-Request"):
        return request.app.state.templates.TemplateResponse("partials/collection_grid.html", context)
    return request.app.state.templates.TemplateResponse("collection.html", context)

@router.get("/cd/{cd_id}", response_class=HTMLResponse)
async def cd_detail(cd_id: int, request: Request, db: AsyncSession = Depends(get_db)):
    require_auth(request)
    cd = await get_cd_with_relations(db, cd_id)
    if not cd:
        return HTMLResponse("Support introuvable", status_code=404)
    return request.app.state.templates.TemplateResponse("cd_detail.html", {"request": request, "cd": cd})

@router.get("/cd/{cd_id}/edit", response_class=HTMLResponse)
async def cd_edit_form(cd_id: int, request: Request, db: AsyncSession = Depends(get_db)):
    require_auth(request)
    cd = await get_cd_with_relations(db, cd_id)
    if not cd:
        return HTMLResponse("Support introuvable", status_code=404)
    return request.app.state.templates.TemplateResponse("edit_cd.html", {"request": request, "cd": cd})

@router.post("/cd")
async def create_cd(request: Request, db: AsyncSession = Depends(get_db),
    artist: str = Form(...), title: str = Form(...), label: str = Form(None),
    catalog_number: str = Form(None), year: str = Form(None), format: str = Form("CD"),
    genre: str = Form(None), style: str = Form(None), condition: str = Form(None),
    ean: str = Form(None), price_paid: str = Form(None), currency: str = Form("EUR"), notes: str = Form(None)):
    require_auth(request)
    cd = CD(artist=artist, title=title, label=label, catalog_number=catalog_number,
            year=int(year) if year else None, format=format, genre=genre, style=style,
            condition=condition, ean=ean, price_paid=float(price_paid) if price_paid else None,
            currency=currency, notes=notes)
    db.add(cd); await db.commit(); await db.refresh(cd)
    return RedirectResponse(f"/cd/{cd.id}", status_code=303)

@router.put("/cd/{cd_id}")
async def update_cd(cd_id: int, request: Request, db: AsyncSession = Depends(get_db),
    artist: str = Form(...), title: str = Form(...), label: str = Form(None),
    catalog_number: str = Form(None), year: str = Form(None), format: str = Form("CD"),
    genre: str = Form(None), style: str = Form(None), condition: str = Form(None),
    ean: str = Form(None), price_paid: str = Form(None), currency: str = Form("EUR"), notes: str = Form(None)):
    require_auth(request)
    cd = await get_cd_with_relations(db, cd_id)
    if not cd:
        return HTMLResponse("Support introuvable", status_code=404)
    cd.artist, cd.title, cd.label, cd.catalog_number = artist, title, label, catalog_number
    cd.year = int(year) if year else None
    cd.format, cd.genre, cd.style = format, genre, style
    cd.condition, cd.ean = condition, ean
    cd.price_paid = float(price_paid) if price_paid else None
    cd.currency, cd.notes = currency, notes
    await db.commit()
    return RedirectResponse(f"/cd/{cd.id}", status_code=303)

@router.delete("/cd/{cd_id}")
async def delete_cd(cd_id: int, request: Request, db: AsyncSession = Depends(get_db)):
    require_auth(request)
    cd = await db.get(CD, cd_id)
    if cd:
        await db.delete(cd); await db.commit()
    return RedirectResponse("/collection", status_code=303)

@router.post("/cd/{cd_id}/toggle-wantlist", response_class=HTMLResponse)
async def toggle_wantlist(cd_id: int, request: Request, db: AsyncSession = Depends(get_db)):
    require_auth(request)
    cd = await get_cd_with_relations(db, cd_id)
    if cd:
        cd.in_wantlist = 0 if cd.in_wantlist else 1
        await db.commit()
    return RedirectResponse(f"/cd/{cd.id}", status_code=303)

@router.post("/cd/add-from-lookup/{ean}")
async def add_from_lookup(ean: str, request: Request, db: AsyncSession = Depends(get_db)):
    require_auth(request)
    mb_result = await lookup_by_barcode(ean)
    releases = mb_result.get("releases", [])
    if releases:
        details = await get_release_details(releases[0]["id"])
        caa_url = f"https://coverartarchive.org/release/{releases[0]['id']}/front"
        cd = CD(title=details.get("title", ""),
                artist=details.get("artist-credit", [{}])[0].get("name", "") if details.get("artist-credit") else "",
                label=details.get("label-info", [{}])[0].get("label", {}).get("name", "") if details.get("label-info") else "",
                year=int(details.get("date", "")[:4]) if details.get("date") else None,
                format="CD", ean=ean, cover_image_path=await download_cover(caa_url))
        db.add(cd); await db.flush()
        for medium in details.get("media", []):
            for track in medium.get("tracks", []):
                length = track.get("length") or 0
                db.add(Track(cd_id=cd.id, position=str(track.get("position", "")),
                             title=track.get("recording", {}).get("title", ""),
                             duration=f"{length // 60000}:{(length % 60000) // 1000:02d}" if length else ""))
        await db.commit(); await db.refresh(cd)
        return RedirectResponse(f"/cd/{cd.id}", status_code=303)
    discogs_result = await search_by_barcode(ean)
    results = discogs_result.get("results", [])
    if results:
        details = await get_release(results[0]["id"])
        cover_url = details.get("images", [{}])[0].get("resource_url", "") if details.get("images") else ""
        cd = CD(discogs_release_id=results[0]["id"], title=details.get("title", ""),
                artist=details.get("artists", [{}])[0].get("name", "") if details.get("artists") else "",
                label=details.get("labels", [{}])[0].get("name", "") if details.get("labels") else "",
                catalog_number=details.get("labels", [{}])[0].get("cat_no", "") if details.get("labels") else "",
                year=details.get("year"), format=", ".join(details.get("formats", [])),
                genre=", ".join(details.get("genres", [])), style=", ".join(details.get("styles", [])),
                ean=ean, discogs_url=details.get("uri", ""), cover_image_path=await download_cover(cover_url))
        db.add(cd); await db.flush()
        for track in details.get("tracklist", []):
            db.add(Track(cd_id=cd.id, position=track.get("position", ""),
                         title=track.get("title", ""), duration=track.get("duration", "")))
        await db.commit(); await db.refresh(cd)
        return RedirectResponse(f"/cd/{cd.id}", status_code=303)
    return HTMLResponse("Aucun résultat pour cet EAN", status_code=404)
