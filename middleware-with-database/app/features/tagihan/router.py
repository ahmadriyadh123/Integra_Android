import logging
from fastapi import APIRouter, Depends, Query, HTTPException, status
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_current_user_credentials
from app.features.tagihan.schemas import (
    APIResponseInvoiceSummary,
    APIResponseInvoiceSync,
)
from app.features.tagihan.repository import TagihanRepository
from app.features.tagihan.service import TagihanService

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/tagihan",
    tags=["Menu Tagihan & Pembayaran"],
)


@router.get("/summary", response_model=APIResponseInvoiceSummary)
async def get_tagihan_summary(
    payment_state: Optional[str] = Query(
        None, description="Filter: 'not_paid', 'paid', atau 'partial'"
    ),
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    partner_id = creds.get("partner_id")
    if not partner_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data akun partner tidak ditemukan dalam sesi Anda.",
        )
    try:
        service = TagihanService(TagihanRepository(db))
        data = await service.get_student_tagihan_summary(
            partner_id=partner_id, payment_state=payment_state
        )
        return APIResponseInvoiceSummary(
            success=True,
            message="Berhasil mengambil ringkasan tagihan siswa",
            data=data,
        )
    except Exception as e:
        logger.exception("[tagihan/summary] Error partner_id=%s", partner_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Informasi tagihan belum dapat dimuat. Silakan coba lagi.",
        ) from e


@router.get("/sync", response_model=APIResponseInvoiceSync)
async def sync_tagihan(
    cursor: Optional[str] = Query(
        None,
        description="Timestamp ISO terakhir sync. Null = full sync.",
    ),
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    """
    Delta sync tagihan.
    - cursor=null  → full sync, kembalikan semua faktur aktif
    - cursor=<iso> → delta sync, kembalikan hanya yang write_date >= cursor
                     beserta all_active_ids agar client bisa deteksi removed
    """
    partner_id = creds.get("partner_id")
    if not partner_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data akun partner tidak ditemukan dalam sesi Anda.",
        )
    try:
        service = TagihanService(TagihanRepository(db))
        data = await service.sync_tagihan(partner_id=partner_id, cursor=cursor)
        return APIResponseInvoiceSync(
            success=True,
            message="Berhasil sinkronisasi tagihan",
            data=data,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
        ) from exc
    except Exception as e:
        logger.exception("[tagihan/sync] Error partner_id=%s", partner_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal sinkronisasi tagihan. Silakan coba lagi.",
        ) from e
