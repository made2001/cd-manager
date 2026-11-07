from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from io import BytesIO
from pathlib import Path
from PIL import Image as PILImage
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from app.database import get_db
from app.models import CD
from app.config import settings
from xml.sax.saxutils import escape as esc

router = APIRouter(prefix="/export", tags=["export"])
COL_WIDTHS = [30 * mm, 50 * mm, 55 * mm, 15 * mm, 20 * mm]

def _resize_cover(path, size=(28 * mm, 28 * mm)):
    full_path = Path(settings.db_path).parent / path
    if not full_path.exists():
        return None
    img = PILImage.open(full_path).convert("RGB")
    img.thumbnail((200, 200))
    buf = BytesIO(); img.save(buf, format="JPEG", quality=80); buf.seek(0)
    return Image(buf, width=size[0], height=size[1])

@router.get("/pdf")
async def export_pdf(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(CD).where(CD.in_wantlist == 0).order_by(CD.artist, CD.year))
    cds = result.scalars().all()
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=10*mm, leftMargin=10*mm,
                            topMargin=15*mm, bottomMargin=15*mm, title="Ma Collection")
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("TitleCustom", parent=styles["Title"], fontSize=18, spaceAfter=12)
    cell_style = ParagraphStyle("Cell", parent=styles["Normal"], fontSize=8, leading=10)
    elements = [Paragraph("Ma Collection", title_style),
                Paragraph(f"{len(cds)} supports", styles["Normal"]), Spacer(1, 8*mm)]
    rows = [["", "Artiste", "Titre", "Année", "Format"]]
    for cd in cds:
        cover = _resize_cover(cd.cover_image_path) if cd.cover_image_path else ""
        rows.append([cover, Paragraph(esc(cd.artist), cell_style), Paragraph(esc(cd.title), cell_style),
                     Paragraph(esc(str(cd.year or "")), cell_style), Paragraph(esc(cd.format or ""), cell_style)])
    table = Table(rows, colWidths=COL_WIDTHS, repeatRows=1)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,0), colors.HexColor("#6366f1")),
        ("TEXTCOLOR", (0,0), (-1,0), colors.white),
        ("FONTNAME", (0,0), (-1,0), "Helvetica-Bold"), ("FONTSIZE", (0,0), (-1,0), 9),
        ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
        ("GRID", (0,0), (-1,-1), 0.3, colors.HexColor("#cccccc")),
        ("ROWBACKGROUNDS", (0,1), (-1,-1), [colors.white, colors.HexColor("#f5f5f7")]),
        ("TOPPADDING", (0,0), (-1,-1), 3), ("BOTTOMPADDING", (0,0), (-1,-1), 3)]))
    elements.append(table)
    doc.build(elements); buffer.seek(0)
    return StreamingResponse(buffer, media_type="application/pdf",
        headers={"Content-Disposition": "attachment; filename=collection.pdf"})
