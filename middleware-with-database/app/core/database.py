from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
from app.core.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,                  # Nonaktifkan log SQL di production
    pool_size=5,                 # Jumlah koneksi tetap di pool
    max_overflow=10,             # Koneksi tambahan jika pool penuh
    pool_timeout=30,             # Detik menunggu koneksi tersedia
    pool_recycle=1800,           # Recycle koneksi setiap 30 menit
    pool_pre_ping=True,          # Validasi koneksi sebelum dipakai (fix stale connection)
)

AsyncSessionLocal = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False
)

Base = declarative_base()