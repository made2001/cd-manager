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
