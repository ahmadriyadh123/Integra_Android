import re
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, create_async_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.engine import make_url

from app.core.config import settings

Base = declarative_base()

registry_engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    pool_size=5,
    max_overflow=10,
    pool_timeout=30,
    pool_recycle=1800,
    pool_pre_ping=True,
)

RegistrySessionLocal = sessionmaker(
    bind=registry_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

_tenant_engines: dict[str, AsyncEngine] = {}
_DATABASE_NAME_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+$")


def get_tenant_engine(database_name: str) -> AsyncEngine:
    if not _DATABASE_NAME_PATTERN.fullmatch(database_name):
        raise ValueError("Nama database tenant tidak valid.")

    engine = _tenant_engines.get(database_name)
    if engine is None:
        tenant_url = make_url(settings.DATABASE_URL).set(database=database_name)
        engine = create_async_engine(
            tenant_url,
            echo=False,
            pool_size=5,
            max_overflow=10,
            pool_timeout=30,
            pool_recycle=1800,
            pool_pre_ping=True,
        )
        _tenant_engines[database_name] = engine
    return engine


async def dispose_database_engines() -> None:
    for engine in _tenant_engines.values():
        await engine.dispose()
    _tenant_engines.clear()
    await registry_engine.dispose()


async def get_registry_db() -> AsyncGenerator[AsyncSession, None]:
    async with RegistrySessionLocal() as session:
        yield session


def create_tenant_session_factory(database_name: str):
    return sessionmaker(
        bind=get_tenant_engine(database_name),
        class_=AsyncSession,
        expire_on_commit=False,
    )
