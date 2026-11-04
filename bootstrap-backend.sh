et -e
mkdir -p app/routers app/services app/templates/partials app/static/css

cat > app/config.py <<'EOF'
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    discogs_token: str
    discogs_user_agent: str = "CDManager/1.0"
    secret_key: str
    admin_password: str
    musicbrainz_user_agent: str = "CDManager/1.0"
    db_path: str = "data/cd_manager.db"
    covers_path: str = "data/covers"

    class Config:
        env_file = ".env"

settings = Settings()
EOF

cat > app/database.py <<'EOF'
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from app.config import settings

engine = create_async_engine(f"sqlite+aiosqlite:///{settings.db_path}")
async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

class Base(DeclarativeBase):
    pass

async def get_db():
    async with async_session() as session:
        yield session
EOF

cat > app/models.py <<'EOF'
from sqlalchemy import Column, Integer, String, Float, Text, DateTime, ForeignKey, Table
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

cd_tags = Table(
    "cd_tags", Base.metadata,
    Column("cd_id", Integer, ForeignKey("cds.id"), primary_key=True),
    Column("tag_id", Integer, ForeignKey("tags.id"), primary_key=True),
)

class CD(Base):
    __tablename__ = "cds"
    id = Column(Integer, primary_key=True, autoincrement=True)
    discogs_release_id = Column(Integer, nullable=True, index=True)
    title = Column(String, nullable=False)
    artist = Column(String, nullable=False, index=True)
    label = Column(String, nullable=True)
    catalog_number = Column(String, nullable=True)
    year = Column(Integer, nullable=True, index=True)
    format = Column(String, nullable=True)
    genre = Column(String, nullable=True, index=True)
    style = Column(String, nullable=True)
    condition = Column(String, nullable=True)
    price_paid = Column(Float, nullable=True)
    currency = Column(String, default="EUR")
    notes = Column(Text, nullable=True)
    cover_image_path = Column(String, nullable=True)
    discogs_url = Column(String, nullable=True)
    ean = Column(String, nullable=True, index=True)
    in_wantlist = Column(Integer, default=0)
    date_added = Column(DateTime, default=datetime.utcnow)
    date_purchased = Column(DateTime, nullable=True)
    tracks = relationship("Track", back_populates="cd", cascade="all, delete-orphan")
    tags = relationship("Tag", secondary=cd_tags, back_populates="cds")

class Track(Base):
    __tablename__ = "tracks"
    id = Column(Integer, primary_key=True, autoincrement=True)
    cd_id = Column(Integer, ForeignKey("cds.id"), nullable=False)
    position = Column(String, nullable=True)
    title = Column(String, nullable=False)
    duration = Column(String, nullable=True)
    cd = relationship("CD", back_populates="tracks")

class Tag(Base):
    __tablename__ = "tags"
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String, unique=True, nullable=False)
    cds = relationship("CD", secondary=cd_tags, back_populates="tags")
EOF

cat > app/auth.py <<'EOF'
from fastapi import Request, HTTPException

def require_auth(request: Request):
    if not request.session.get("authenticated"):
        raise HTTPException(status_code=401, detail="Non authentifié")
EOF

cat > app/services/discogs_client.py <<'EOF'
import httpx
from app.config import settings

DISCOGS_API = "https://api.discogs.com"

def _headers():
    return {
        "Authorization": f"Discogs token={settings.discogs_token}",
        "User-Agent": settings.discogs_user_agent,
    }

async def get_user_collection(username, page=1, per_page=100):
    url = f"{DISCOGS_API}/users/{username}/collection/folders/0/releases"
    params = {"page": page, "per_page": per_page}
    async with httpx.AsyncClient() as client:
        resp = await client.get(url, params=params, headers=_headers())
        resp.raise_for_status()
        return resp.json()

async def get_release(release_id):
    url = f"{DISCOGS_API}/releases/{release_id}"
    async with httpx.AsyncClient() as client:
        resp = await client.get(url, headers=_headers())
        resp.raise_for_status()
        return resp.json()

async def search_by_barcode(barcode):
    url = f"{DISCOGS_API}/database/search"
    params = {"barcode": barcode, "type": "release"}
    async with httpx.AsyncClient() as client:
        resp = await client.get(url, params=params, headers=_headers())
        resp.raise_for_status()
        return resp.json()
EOF

cat > app/services/musicbrainz_client.py <<'EOF'
import httpx
from app.config import settings

MB_API = "https://musicbrainz.org/ws/2"

def _headers():
    return {"User-Agent": settings.musicbrainz_user_agent}

async def lookup_by_barcode(barcode):
    url = f"{MB_API}/release"
    params = {"query": f'barcode:"{barcode}"', "fmt": "json", "limit": 5}
    async with httpx.AsyncClient() as client:
        resp = await client.get(url, params=params, headers=_headers())
        resp.raise_for_status()
        return resp.json()

async def get_release_details(release_mbid):
    url = f"{MB_API}/release/{release_mbid}"
    params = {"fmt": "json", "inc": "recordings+labels+media"}
    async with httpx.AsyncClient() as client:
        resp = await client.get(url, params=params, headers=_headers())
        resp.raise_for_status()
        return resp.json()
EOF

cat > app/services/image_downloader.py <<'EOF'
import httpx
import hashlib
from pathlib import Path
from app.config import settings

async def download_cover(url):
    if not url:
        return None
    try:
        async with httpx.AsyncClient(follow_redirects=True) as client:
            resp = await client.get(url, timeout=30)
            resp.raise_for_status()
        ext = ".png" if "png" in resp.headers.get("content-type", "") else ".jpg"
        filename = hashlib.md5(url.encode()).hexdigest() + ext
        filepath = Path(settings.covers_path) / filename
        filepath.write_bytes(resp.content)
        return f"covers/{filename}"
    except Exception:
        return None
EOF

cat > app/routers/auth_routes.py <<'EOF'
from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse
import bcrypt
from app.config import settings

router = APIRouter(tags=["auth"])
_PASSWORD_HASH = bcrypt.hashpw(settings.admin_password.encode(), bcrypt.gensalt())

@router.get("/login", response_class=HTMLResponse)
async def login_form(request: Request):
    return request.app.state.templates.TemplateResponse(
        "login.html", {"request": request, "error": None})

@router.post("/login")
async def login(request: Request, password: str = Form(...)):
    if bcrypt.checkpw(password.encode(), _PASSWORD_HASH):
        request.session["authenticated"] = True
        return RedirectResponse("/", status_code=303)
    return request.app.state.templates.TemplateResponse(
        "login.html", {"request": request, "error": "Mot de passe incorrect"},
        status_code=401)

@router.get("/logout")
async def logout(request: Request):
    request.session.clear()
    return RedirectResponse("/login", status_code=303)
EOF

cat > app/routers/lookup.py <<'EOF'
from fastapi import APIRouter
from app.services.discogs_client import search_by_barcode, get_release
from app.services.musicbrainz_client import lookup_by_barcode, get_release_details
from app.services.image_downloader import download_cover

router = APIRouter(prefix="/lookup", tags=["lookup"])

@router.get("/ean/{ean}")
async def lookup_ean(ean: str):
    mb_result = await lookup_by_barcode(ean)
    releases = mb_result.get("releases", [])
    if releases:
        details = await get_release_details(releases[0]["id"])
        caa_url = f"https://coverartarchive.org/release/{releases[0]['id']}/front"
        cover_path = await download_cover(caa_url)
        tracks = []
        for medium in details.get("media", []):
            for track in medium.get("tracks", []):
                length = track.get("length") or 0
                tracks.append({
                    "position": str(track.get("position", "")),
                    "title": track.get("recording", {}).get("title", ""),
                    "duration": f"{length // 60000}:{(length % 60000) // 1000:02d}" if length else "",
                })
        return {
            "source": "musicbrainz",
            "title": details.get("title", ""),
            "artist": details.get("artist-credit", [{}])[0].get("name", "") if details.get("artist-credit") else "",
            "label": details.get("label-info", [{}])[0].get("label", {}).get("name", "") if details.get("label-info") else "",
            "year": details.get("date", "")[:4] if details.get("date") else None,
            "ean": ean, "tracks": tracks, "cover_path": cover_path,
        }
    discogs_result = await search_by_barcode(ean)
    results = discogs_result.get("results", [])
    if results:
        details = await get_release(results[0]["id"])
        cover_url = details.get("images", [{}])[0].get("resource_url", "") if details.get("images") else ""
        cover_path = await download_cover(cover_url)
        tracks = [{"position": t.get("position", ""), "title": t.get("title", ""), "duration": t.get("duration", "")} for t in details.get("tracklist", [])]
        return {
            "source": "discogs",
            "title": details.get("title", ""),
            "artist": details.get("artists", [{}])[0].get("name", "") if details.get("artists") else "",
            "label": details.get("labels", [{}])[0].get("name", "") if details.get("labels") else "",
            "year": details.get("year"), "ean": ean, "tracks": tracks, "cover_path": cover_path,
        }
    return {"error": "Aucun résultat trouvé pour cet EAN"}
EOF

cat > app/routers/import_discogs.py <<'EOF'
import asyncio
from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.auth import require_auth
from app.models import CD, Track
from app.services.discogs_client import get_user_collection, get_release
from app.services.image_downloader import download_cover

router = APIRouter(prefix="/import", tags=["import"])

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
            release_id = item["release_id"]
            existing = await db.execute(select(CD).where(CD.discogs_release_id == release_id))
            if existing.scalar_one_or_none():
                skipped += 1
                continue
            await asyncio.sleep(1.1)
            details = await get_release(release_id)
            cover_url = details["images"][0].get("resource_url", "") if details.get("images") else ""
            cover_path = await download_cover(cover_url)
            formats = details.get("formats", [])
            main_format = "CD"
            for f in formats:
                if "Vinyl" in f or "LP" in f:
                    main_format = "Vinyle"; break
                elif "Cassette" in f:
                    main_format = "Cassette"; break
                elif "MiniDisc" in f or "MD" in f:
                    main_format = "MiniDisc"; break
            cd = CD(
                discogs_release_id=release_id,
                title=details.get("title", "Unknown"),
                artist=details.get("artists", [{}])[0].get("name", "Unknown") if details.get("artists") else "Unknown",
                label=details.get("labels", [{}])[0].get("name", "") if details.get("labels") else "",
                catalog_number=details.get("labels", [{}])[0].get("cat_no", "") if details.get("labels") else "",
                year=details.get("year"), format=main_format,
                genre=", ".join(details.get("genres", [])),
                style=", ".join(details.get("styles", [])),
                condition=item.get("rating", None), notes=item.get("notes", ""),
                cover_image_path=cover_path, discogs_url=details.get("uri", ""),
                ean=next((b["value"] for b in details.get("identifiers", []) if b.get("type") == "Barcode"), None),
            )
            db.add(cd)
            await db.flush()
            for track in details.get("tracklist", []):
                db.add(Track(cd_id=cd.id, position=track.get("position", ""),
                             title=track.get("title", ""), duration=track.get("duration", "")))
            imported += 1
        pagination = data.get("pagination", {})
        if page >= pagination.get("pages", 1):
            break
        page += 1
        await asyncio.sleep(1.1)
    await db.commit()
    return {"imported": imported, "skipped": skipped}
EOF

cat > app/routers/collection.py <<'EOF'
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
PAGE_SIZE = 24

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
    sort: str = Query("date_desc"), page: int = Query(1, ge=1)):
    require_auth(request)
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
    sort_map = {"date_desc": desc(CD.date_added), "date_asc": asc(CD.date_added),
                "artist_asc": asc(CD.artist), "artist_desc": desc(CD.artist),
                "year_desc": desc(CD.year), "year_asc": asc(CD.year), "title_asc": asc(CD.title)}
    query = query.order_by(sort_map.get(sort, desc(CD.date_added)))
    total = (await db.execute(count_query)).scalar() or 0
    total_pages = max(1, (total + PAGE_SIZE - 1) // PAGE_SIZE)
    page = min(page, total_pages)
    query = query.offset((page - 1) * PAGE_SIZE).limit(PAGE_SIZE)
    cds = (await db.execute(query)).scalars().all()
    genres = [g for (g,) in (await db.execute(select(CD.genre).where(CD.genre.isnot(None)).distinct())).all() if g]
    context = {"request": request, "cds": cds, "query": q or "", "format_filter": format or "",
               "genre_filter": genre or "", "sort": sort, "page": page,
               "total_pages": total_pages, "genres": sorted(genres)}
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
    catalog_number: str = Form(None), year: int = Form(None), format: str = Form("CD"),
    genre: str = Form(None), style: str = Form(None), condition: str = Form(None),
    ean: str = Form(None), price_paid: float = Form(None), currency: str = Form("EUR"), notes: str = Form(None)):
    require_auth(request)
    cd = CD(artist=artist, title=title, label=label, catalog_number=catalog_number, year=year,
            format=format, genre=genre, style=style, condition=condition, ean=ean,
            price_paid=price_paid, currency=currency, notes=notes)
    db.add(cd); await db.commit(); await db.refresh(cd)
    return RedirectResponse(f"/cd/{cd.id}", status_code=303)

@router.put("/cd/{cd_id}")
async def update_cd(cd_id: int, request: Request, db: AsyncSession = Depends(get_db),
    artist: str = Form(...), title: str = Form(...), label: str = Form(None),
    catalog_number: str = Form(None), year: int = Form(None), format: str = Form("CD"),
    genre: str = Form(None), style: str = Form(None), condition: str = Form(None),
    ean: str = Form(None), price_paid: float = Form(None), currency: str = Form("EUR"), notes: str = Form(None)):
    require_auth(request)
    cd = await get_cd_with_relations(db, cd_id)
    if not cd:
        return HTMLResponse("Support introuvable", status_code=404)
    cd.artist, cd.title, cd.label, cd.catalog_number = artist, title, label, catalog_number
    cd.year, cd.format, cd.genre, cd.style = year, format, genre, style
    cd.condition, cd.ean, cd.price_paid, cd.currency, cd.notes = condition, ean, price_paid, currency, notes
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
EOF

cat > app/routers/search.py <<'EOF'
from fastapi import APIRouter, Depends, Request
from fastapi.responses import HTMLResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.auth import require_auth
from app.models import CD

router = APIRouter(tags=["search"])

@router.get("/wantlist", response_class=HTMLResponse)
async def wantlist(request: Request, db: AsyncSession = Depends(get_db)):
    require_auth(request)
    cds = (await db.execute(select(CD).where(CD.in_wantlist == 1).order_by(CD.date_added.desc()))).scalars().all()
    return request.app.state.templates.TemplateResponse("wantlist.html", {"request": request, "cds": cds})
EOF

cat > app/routers/export.py <<'EOF'
import csv, io, json
from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.database import get_db
from app.models import CD

router = APIRouter(prefix="/export", tags=["export"])
FIELDS = ["title", "artist", "label", "catalog_number", "year", "format", "genre",
          "style", "condition", "price_paid", "currency", "ean", "discogs_url", "notes"]

@router.get("/csv")
async def export_csv(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(CD).options(selectinload(CD.tracks)).where(CD.in_wantlist == 0))
    cds = result.scalars().all()
    output = io.StringIO()
    writer = csv.writer(output, delimiter=";")
    writer.writerow(FIELDS + ["tracks"])
    for cd in cds:
        tracks = " | ".join(f"{t.position}. {t.title}" for t in cd.tracks)
        writer.writerow([getattr(cd, f, "") or "" for f in FIELDS] + [tracks])
    output.seek(0)
    return StreamingResponse(iter([output.getvalue()]), media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": "attachment; filename=collection.csv"})

@router.get("/json")
async def export_json(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(CD).options(selectinload(CD.tracks)).where(CD.in_wantlist == 0))
    cds = result.scalars().all()
    data = []
    for cd in cds:
        item = {f: getattr(cd, f, None) for f in FIELDS}
        item["tracks"] = [{"position": t.position, "title": t.title, "duration": t.duration} for t in cd.tracks]
        data.append(item)
    return StreamingResponse(iter([json.dumps(data, ensure_ascii=False, indent=2)]),
        media_type="application/json",
        headers={"Content-Disposition": "attachment; filename=collection.json"})
EOF

cat > app/routers/export_pdf.py <<'EOF'
from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from io import BytesIO
from pathlib import Path
from PIL import Image as PILImage
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from app.database import get_db
from app.models import CD
from app.config import settings

router = APIRouter(prefix="/export", tags=["export"])
COL_WIDTHS = [30 * mm, 50 * mm, 55 * mm, 15 * mm, 20 * mm]

def _resize_cover(path, size=(28 * mm, 28 * mm)):
    full_path = Path(settings.db_path).parent / path
    if not full_path.exists():
        return None
    img = PILImage.open(full_path).convert("RGB")
    img.thumbnail((200, 200))
    buf = BytesIO(); img.save(buf, format="JPEG", quality=80); buf.seek(0)
    return Image(buf, width=size[0], height=size[1])

@router.get("/pdf")
async def export_pdf(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(CD).where(CD.in_wantlist == 0).order_by(CD.artist, CD.year))
    cds = result.scalars().all()
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=10*mm, leftMargin=10*mm,
                            topMargin=15*mm, bottomMargin=15*mm, title="Ma Collection")
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("TitleCustom", parent=styles["Title"], fontSize=18, spaceAfter=12)
    cell_style = ParagraphStyle("Cell", parent=styles["Normal"], fontSize=8, leading=10)
    elements = [Paragraph("Ma Collection", title_style),
                Paragraph(f"{len(cds)} supports", styles["Normal"]), Spacer(1, 8*mm)]
    rows = [["", "Artiste", "Titre", "Année", "Format"]]
    for cd in cds:
        cover = _resize_cover(cd.cover_image_path) if cd.cover_image_path else ""
        rows.append([cover, Paragraph(cd.artist, cell_style), Paragraph(cd.title, cell_style),
                     Paragraph(str(cd.year or ""), cell_style), Paragraph(cd.format or "", cell_style)])
    table = Table(rows, colWidths=COL_WIDTHS, repeatRows=1)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,0), colors.HexColor("#6366f1")),
        ("TEXTCOLOR", (0,0), (-1,0), colors.white),
        ("FONTNAME", (0,0), (-1,0), "Helvetica-Bold"), ("FONTSIZE", (0,0), (-1,0), 9),
        ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
        ("GRID", (0,0), (-1,-1), 0.3, colors.HexColor("#cccccc")),
        ("ROWBACKGROUNDS", (0,1), (-1,-1), [colors.white, colors.HexColor("#f5f5f7")]),
        ("TOPPADDING", (0,0), (-1,-1), 3), ("BOTTOMPADDING", (0,0), (-1,-1), 3)]))
    elements.append(table)
    doc.build(elements); buffer.seek(0)
    return StreamingResponse(buffer, media_type="application/pdf",
        headers={"Content-Disposition": "attachment; filename=collection.pdf"})
EOF

cat > app/main.py <<'EOF'
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from starlette.middleware.sessions import SessionMiddleware
from contextlib import asynccontextmanager
from sqlalchemy import func, select
from app.database import engine, Base, async_session
from app.config import settings
from app.models import CD
from app.routers import auth_routes, collection, import_discogs, lookup, search, export, export_pdf

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield

app = FastAPI(title="CD Manager", lifespan=lifespan)
app.add_middleware(SessionMiddleware, secret_key=settings.secret_key)
app.mount("/static", StaticFiles(directory="app/static"), name="static")
app.mount("/covers", StaticFiles(directory=settings.covers_path), name="covers")
app.state.templates = Jinja2Templates(directory="app/templates")

app.include_router(auth_routes.router)
app.include_router(collection.router)
app.include_router(import_discogs.router)
app.include_router(lookup.router)
app.include_router(search.router)
app.include_router(export.router)
app.include_router(export_pdf.router)

@app.get("/")
async def root(request: Request):
    async with async_session() as db:
        total = (await db.execute(select(func.count()).select_from(CD).where(CD.in_wantlist == 0))).scalar() or 0
        wantlist = (await db.execute(select(func.count()).select_from(CD).where(CD.in_wantlist == 1))).scalar() or 0
        formats = (await db.execute(select(CD.format, func.count()).group_by(CD.format))).all()
        recent = (await db.execute(select(CD).order_by(CD.date_added.desc()).limit(12))).scalars().all()
    format_counts = {}
    for fmt, count in formats:
        key = fmt or "Autre"
        if "Vinyl" in key or "LP" in key: format_counts["Vinyle"] = format_counts.get("Vinyle", 0) + count
        elif "Cassette" in key: format_counts["Cassette"] = format_counts.get("Cassette", 0) + count
        elif "MiniDisc" in key or "MD" in key: format_counts["MiniDisc"] = format_counts.get("MiniDisc", 0) + count
        elif "CD" in key: format_counts["CD"] = format_counts.get("CD", 0) + count
    return app.state.templates.TemplateResponse("dashboard.html", {
        "request": request, "total_count": total, "wantlist_count": wantlist,
        "format_counts": format_counts, "recent_cds": recent})
EOF

# fichiers __init__.py pour que les packages soient importables
touch app/__init__.py app/routers/__init__.py app/services/__init__.py

echo "✅ Backend régénéré."
echo "→ Vérifie : find app -type f | sort"
