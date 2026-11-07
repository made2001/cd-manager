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
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url, params=params, headers=_headers())
        resp.raise_for_status()
        return resp.json()

async def get_release(release_id):
    url = f"{DISCOGS_API}/releases/{release_id}"
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url, headers=_headers())
        resp.raise_for_status()
        return resp.json()

async def search_by_barcode(barcode):
    url = f"{DISCOGS_API}/database/search"
    params = {"barcode": barcode, "type": "release"}
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url, params=params, headers=_headers())
        resp.raise_for_status()
        return resp.json()
