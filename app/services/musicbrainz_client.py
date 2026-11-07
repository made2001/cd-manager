import httpx
from app.config import settings

MB_API = "https://musicbrainz.org/ws/2"

def _headers():
    return {"User-Agent": settings.musicbrainz_user_agent}

async def lookup_by_barcode(barcode):
    url = f"{MB_API}/release"
    params = {"query": f'barcode:"{barcode}"', "fmt": "json", "limit": 5}
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url, params=params, headers=_headers())
        resp.raise_for_status()
        return resp.json()

async def get_release_details(release_mbid):
    url = f"{MB_API}/release/{release_mbid}"
    params = {"fmt": "json", "inc": "recordings+labels+media"}
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(url, params=params, headers=_headers())
        resp.raise_for_status()
        return resp.json()
