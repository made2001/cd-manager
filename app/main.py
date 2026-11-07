from fastapi import FastAPI, Request, Depends
from fastapi.responses import RedirectResponse
from app.auth import require_auth
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from starlette.middleware.sessions import SessionMiddleware
from contextlib import asynccontextmanager
from sqlalchemy import func, select
import bcrypt
from app.database import engine, Base, async_session
from app.config import settings
from app.models import CD, Setting
from app.routers import auth_routes, collection, import_discogs, lookup, search, export, export_pdf, profile

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with async_session() as db:
        existing = (await db.execute(select(Setting).where(Setting.key == "password_hash"))).scalar_one_or_none()
        if not existing:
            h = bcrypt.hashpw(settings.admin_password.encode(), bcrypt.gensalt()).decode()
            db.add(Setting(key="password_hash", value=h))
            await db.commit()
    yield

app = FastAPI(title="CD Manager", lifespan=lifespan, docs_url=None, openapi_url=None)
app.add_middleware(SessionMiddleware, secret_key=settings.secret_key, https_only=True)
app.mount("/static", StaticFiles(directory="app/static"), name="static")
app.mount("/covers", StaticFiles(directory=settings.covers_path), name="covers")
app.state.templates = Jinja2Templates(directory="app/templates")

app.include_router(auth_routes.router)
app.include_router(collection.router)
app.include_router(import_discogs.router)
app.include_router(lookup.router, dependencies=[Depends(require_auth)])
app.include_router(search.router)
app.include_router(export.router, dependencies=[Depends(require_auth)])
app.include_router(export_pdf.router, dependencies=[Depends(require_auth)])
app.include_router(profile.router)
@app.get("/health")
async def health():
    return {"status": "ok"}
@app.exception_handler(401)
async def auth_redirect(request: Request, exc):
    return RedirectResponse(url="/login", status_code=303)
@app.get("/")
async def root(request: Request):
    require_auth(request)
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
