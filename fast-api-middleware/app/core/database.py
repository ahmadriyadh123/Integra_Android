from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.orm import Session, declarative_base, sessionmaker

from app.core.config import settings

Base = declarative_base()

registry_url = URL.create(
    drivername="postgresql+psycopg2",
    username=settings.REGISTRY_DB_USER,
    password=settings.REGISTRY_DB_PASSWORD,
    host=settings.REGISTRY_DB_HOST,
    port=settings.REGISTRY_DB_PORT,
    database=settings.REGISTRY_DB_NAME,
)

engine = create_engine(
    registry_url,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
