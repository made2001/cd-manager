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
