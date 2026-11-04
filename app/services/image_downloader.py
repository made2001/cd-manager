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
