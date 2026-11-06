from fastapi import APIRouter, Request, Form, Depends
from fastapi.responses import HTMLResponse, RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import bcrypt
from app.database import get_db
from app.models import Setting

router = APIRouter(tags=["auth"])

async def get_password_hash(db: AsyncSession):
    s = (await db.execute(select(Setting).where(Setting.key == "password_hash"))).scalar_one_or_none()
    return s.value if s else None

@router.get("/login", response_class=HTMLResponse)
async def login_form(request: Request):
    return request.app.state.templates.TemplateResponse(
        "login.html", {"request": request, "error": None})

@router.post("/login")
async def login(request: Request, password: str = Form(...), db: AsyncSession = Depends(get_db)):
    h = await get_password_hash(db)
    if h and bcrypt.checkpw(password.encode(), h.encode()):
        request.session["authenticated"] = True
        return RedirectResponse("/", status_code=303)
    return request.app.state.templates.TemplateResponse(
        "login.html", {"request": request, "error": "Mot de passe incorrect"}, status_code=401)

@router.get("/logout")
async def logout(request: Request):
    request.session.clear()
    return RedirectResponse("/login", status_code=303)
