import pytest
from app.models import CD
from sqlalchemy import select, func

@pytest.mark.asyncio
async def test_create_cd(auth_client, db_session):
    resp = await auth_client.post("/cd", data={"artist": "Radiohead", "title": "OK Computer", "year": 1997, "format": "CD", "genre": "Rock"})
    assert resp.status_code == 303
    cd = (await db_session.execute(select(CD))).scalars().first()
    assert cd.artist == "Radiohead"

@pytest.mark.asyncio
async def test_list_collection_empty(auth_client):
    resp = await auth_client.get("/collection")
    assert resp.status_code == 200

@pytest.mark.asyncio
async def test_search_by_artist(auth_client, db_session):
    db_session.add(CD(artist="Pink Floyd", title="Wish You Were Here", format="Vinyle"))
    await db_session.commit()
    resp = await auth_client.get("/collection?q=Pink")
    assert "Pink Floyd" in resp.text

@pytest.mark.asyncio
async def test_delete_cd(auth_client, db_session):
    cd = CD(artist="To Delete", title="Gone", format="CD")
    db_session.add(cd); await db_session.commit(); await db_session.refresh(cd)
    resp = await auth_client.delete(f"/cd/{cd.id}")
    assert resp.status_code == 303
    count = (await db_session.execute(select(func.count()).select_from(CD))).scalar()
    assert count == 0
