import os
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

os.environ.setdefault("DISCOGS_TOKEN", "test_token")
os.environ.setdefault("SECRET_KEY", "test_secret_key")
os.environ.setdefault("ADMIN_PASSWORD", "testpassword")
os.environ.setdefault("DISCOGS_USER_AGENT", "Test/1.0")
os.environ.setdefault("MUSICBRAINZ_USER_AGENT", "Test/1.0")

from app.database import Base, get_db
from app.main import app

@pytest_asyncio.fixture
async def db_engine():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()

@pytest_asyncio.fixture
async def db_session(db_engine):
    factory = sessionmaker(db_engine, class_=AsyncSession, expire_on_commit=False)
    async with factory() as session:
        yield session

@pytest_asyncio.fixture
async def client(db_session):
    async def override_get_db():
        yield db_session
    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()

@pytest_asyncio.fixture
async def auth_client(client):
    resp = await client.post("/login", data={"password": "testpassword"})
    assert resp.status_code == 303
    return client
