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
