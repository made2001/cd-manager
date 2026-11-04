from fastapi import APIRouter
from app.services.discogs_client import search_by_barcode, get_release
from app.services.musicbrainz_client import lookup_by_barcode, get_release_details
from app.services.image_downloader import download_cover

router = APIRouter(prefix="/lookup", tags=["lookup"])

@router.get("/ean/{ean}")
async def lookup_ean(ean: str):
    mb_result = await lookup_by_barcode(ean)
    releases = mb_result.get("releases", [])
    if releases:
        details = await get_release_details(releases[0]["id"])
        caa_url = f"https://coverartarchive.org/release/{releases[0]['id']}/front"
        cover_path = await download_cover(caa_url)
        tracks = []
        for medium in details.get("media", []):
            for track in medium.get("tracks", []):
                length = track.get("length") or 0
                tracks.append({
                    "position": str(track.get("position", "")),
                    "title": track.get("recording", {}).get("title", ""),
                    "duration": f"{length // 60000}:{(length % 60000) // 1000:02d}" if length else "",
                })
        return {
            "source": "musicbrainz",
            "title": details.get("title", ""),
            "artist": details.get("artist-credit", [{}])[0].get("name", "") if details.get("artist-credit") else "",
            "label": details.get("label-info", [{}])[0].get("label", {}).get("name", "") if details.get("label-info") else "",
            "year": details.get("date", "")[:4] if details.get("date") else None,
            "ean": ean, "tracks": tracks, "cover_path": cover_path,
        }
    discogs_result = await search_by_barcode(ean)
    results = discogs_result.get("results", [])
    if results:
        details = await get_release(results[0]["id"])
        cover_url = details.get("images", [{}])[0].get("resource_url", "") if details.get("images") else ""
        cover_path = await download_cover(cover_url)
        tracks = [{"position": t.get("position", ""), "title": t.get("title", ""), "duration": t.get("duration", "")} for t in details.get("tracklist", [])]
        return {
            "source": "discogs",
            "title": details.get("title", ""),
            "artist": details.get("artists", [{}])[0].get("name", "") if details.get("artists") else "",
            "label": details.get("labels", [{}])[0].get("name", "") if details.get("labels") else "",
            "year": details.get("year"), "ean": ean, "tracks": tracks, "cover_path": cover_path,
        }
    return {"error": "Aucun résultat trouvé pour cet EAN"}
