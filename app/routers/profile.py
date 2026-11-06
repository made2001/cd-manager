from fastapi import APIRouter, Depends, Request, Form
from fastapi.responses import HTMLResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import bcrypt
from app.database import get_db
from app.auth import require_auth
from app.models import Setting

router = APIRouter(tags=["profile"])

@router.get("/profile", response_class=HTMLResponse)
async def profile_page(request: Request, db: AsyncSession = Depends(get_db)):
    require_auth(request)
    return request.app.state.templates.TemplateResponse(
        "profile.html", {"request": request, "msg": None, "err": None})

@router.post("/profile/password")
async def change_password(request: Request, db: AsyncSession = Depends(get_db),
    current: str = Form(...), new: str = Form(...), confirm: str = Form(...)):
    require_auth(request)
    s = (await db.execute(select(Setting).where(Setting.key == "password_hash"))).scalar_one_or_none()
    if not s or not bcrypt.checkpw(current.encode(), s.value.encode()):
        return request.app.state.templates.TemplateResponse(
            "profile.html", {"request": request, "msg": None, "err": "Mot de passe actuel incorrect"})
    if len(new) < 6:
        return request.app.state.templates.TemplateResponse(
            "profile.html", {"request": request, "msg": None, "err": "Le nouveau mot de passe doit faire au moins 6 caractères"})
    if new != confirm:
        return request.app.state.templates.TemplateResponse(
            "profile.html", {"request": request, "msg": None, "err": "La confirmation ne correspond pas"})
    s.value = bcrypt.hashpw(new.encode(), bcrypt.gensalt()).decode()
    await db.commit()
    return request.app.state.templates.TemplateResponse(
        "profile.html", {"request": request, "msg": "✅ Mot de passe mis à jour", "err": None})
