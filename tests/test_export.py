import pytest
from app.models import CD, Track

@pytest.mark.asyncio
async def test_export_csv(auth_client, db_session):
    db_session.add(CD(artist="Artist", title="Title", format="CD", year=2020))
    await db_session.commit()
    resp = await auth_client.get("/export/csv")
    assert resp.status_code == 200
    assert "Artist" in resp.text

@pytest.mark.asyncio
async def test_export_json(auth_client, db_session):
    cd = CD(artist="Artist", title="Title", format="CD")
    db_session.add(cd); await db_session.commit(); await db_session.refresh(cd)
    db_session.add(Track(cd_id=cd.id, position="1", title="Song"))
    await db_session.commit()
    resp = await auth_client.get("/export/json")
    assert resp.status_code == 200
    data = resp.json()
    assert data[0]["artist"] == "Artist"
