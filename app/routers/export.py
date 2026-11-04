import csv, io, json
from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.database import get_db
from app.models import CD

router = APIRouter(prefix="/export", tags=["export"])
FIELDS = ["title", "artist", "label", "catalog_number", "year", "format", "genre",
          "style", "condition", "price_paid", "currency", "ean", "discogs_url", "notes"]

@router.get("/csv")
async def export_csv(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(CD).options(selectinload(CD.tracks)).where(CD.in_wantlist == 0))
    cds = result.scalars().all()
    output = io.StringIO()
    writer = csv.writer(output, delimiter=";")
    writer.writerow(FIELDS + ["tracks"])
    for cd in cds:
        tracks = " | ".join(f"{t.position}. {t.title}" for t in cd.tracks)
        writer.writerow([getattr(cd, f, "") or "" for f in FIELDS] + [tracks])
    output.seek(0)
    return StreamingResponse(iter([output.getvalue()]), media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": "attachment; filename=collection.csv"})

@router.get("/json")
async def export_json(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(CD).options(selectinload(CD.tracks)).where(CD.in_wantlist == 0))
    cds = result.scalars().all()
    data = []
    for cd in cds:
        item = {f: getattr(cd, f, None) for f in FIELDS}
        item["tracks"] = [{"position": t.position, "title": t.title, "duration": t.duration} for t in cd.tracks]
        data.append(item)
    return StreamingResponse(iter([json.dumps(data, ensure_ascii=False, indent=2)]),
        media_type="application/json",
        headers={"Content-Disposition": "attachment; filename=collection.json"})
