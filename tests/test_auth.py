import pytest

@pytest.mark.asyncio
async def test_login_page(client):
    resp = await client.get("/login")
    assert resp.status_code == 200

@pytest.mark.asyncio
async def test_login_wrong_password(client):
    resp = await client.post("/login", data={"password": "mauvais"})
    assert resp.status_code == 401

@pytest.mark.asyncio
async def test_login_success(client):
    resp = await client.post("/login", data={"password": "testpassword"})
    assert resp.status_code == 303

@pytest.mark.asyncio
async def test_logout(auth_client):
    resp = await auth_client.get("/logout")
    assert resp.status_code == 303
