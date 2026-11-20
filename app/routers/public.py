from fastapi import APIRouter, Depends, Request, Query
from fastapi.responses import HTMLResponse, RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_, desc, asc
from sqlalchemy.orm import selectinload
from app.database import get_db
from app.models import CD

router = APIRouter(tags=["public"])

@router.get("/public", response_class=HTMLResponse)
async def public_list(request: Request, db: AsyncSession = Depends(get_db),
    q: str = Query(None), format: str = Query(None),
    sort: str = Query("artist_asc"), page: int = Query(1, ge=1), per_page: int = Query(24)):
    query = select(CD).options(selectinload(CD.tracks))
    count_query = select(func.count()).select_from(CD)
    if q:
        like = f"%{q}%"
        cond = or_(CD.title.ilike(like), CD.artist.ilike(like), CD.label.ilike(like))
        query = query.where(cond); count_query = count_query.where(cond)
    if format:
        query = query.where(CD.format == format); count_query = count_query.where(CD.format == format)
    total = (await db.execute(count_query)).scalar() or 0
    total_pages = max(1, (total + per_page - 1) // per_page)
    if page > total_pages: page = total_pages
    sort_map = {"artist_asc": asc(func.lower(CD.artist)), "artist_desc": desc(func.lower(CD.artist)),
                "title_asc": asc(func.lower(CD.title)), "title_desc": desc(func.lower(CD.title)),
                "year_desc": desc(CD.year), "date_desc": desc(CD.date_added)}
    query = query.order_by(sort_map.get(sort, asc(func.lower(CD.artist)))).offset((page-1)*per_page).limit(per_page)
    cds = (await db.execute(query)).scalars().all()
    if request.headers.get("HX-Request"):
        return request.app.state.templates.TemplateResponse("partials/public_grid.html", {"request": request, "cds": cds, "query": q or "", "format_filter": format or "", "sort": sort, "page": page, "total_pages": total_pages, "total_count": total, "per_page": per_page})
    return request.app.state.templates.TemplateResponse("public.html", {
        "request": request, "cds": cds, "query": q or "", "format_filter": format or "",
        "sort": sort, "page": page, "total_pages": total_pages, "total_count": total, "per_page": per_page})

@router.get("/public/cd/{cd_id}", response_class=HTMLResponse)
async def public_detail(cd_id: int, request: Request, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(CD).options(selectinload(CD.tracks)).where(CD.id == cd_id))
    cd = result.scalar_one_or_none()
    if not cd:
        return RedirectResponse("/public", status_code=303)
    return request.app.state.templates.TemplateResponse("public_detail.html", {"request": request, "cd": cd})
