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

_tenant_engines: dict[tuple[str, int, str], AsyncEngine] = {}
_DATABASE_NAME_PATTERN = re.compile(r"^[A-Za-z0-9_.-]+$")
_DATABASE_HOST_PATTERN = re.compile(r"^[A-Za-z0-9_.:-]+$")


def get_tenant_engine(
    database_host: str,
    database_port: int,
    database_name: str,
) -> AsyncEngine:
    if not _DATABASE_HOST_PATTERN.fullmatch(database_host):
        raise ValueError("Host database tenant tidak valid.")
    if not 1 <= database_port <= 65535:
        raise ValueError("Port database tenant tidak valid.")
    if not _DATABASE_NAME_PATTERN.fullmatch(database_name):
        raise ValueError("Nama database tenant tidak valid.")

    cache_key = (database_host, database_port, database_name)
    engine = _tenant_engines.get(cache_key)
    if engine is None:
        tenant_url = make_url(settings.DATABASE_URL).set(
            host=database_host,
            port=database_port,
            database=database_name,
        )
        engine = create_async_engine(
            tenant_url,
            echo=False,
            pool_size=5,
            max_overflow=10,
            pool_timeout=30,
            pool_recycle=1800,
            pool_pre_ping=True,
        )
        _tenant_engines[cache_key] = engine
    return engine


async def dispose_database_engines() -> None:
    for engine in _tenant_engines.values():
        await engine.dispose()
    _tenant_engines.clear()
    await registry_engine.dispose()


async def get_registry_db() -> AsyncGenerator[AsyncSession, None]:
    async with RegistrySessionLocal() as session:
        yield session


def create_tenant_session_factory(
    database_host: str,
    database_port: int,
    database_name: str,
):
    return sessionmaker(
        bind=get_tenant_engine(database_host, database_port, database_name),
        class_=AsyncSession,
        expire_on_commit=False,
    )
