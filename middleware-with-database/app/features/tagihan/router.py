# app/features/tagihan/router.py
import logging
from fastapi import APIRouter, Depends, Query, HTTPException, status
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_current_user_credentials
from app.features.tagihan.schemas import APIResponseInvoiceSummary
from app.features.tagihan.repository import TagihanRepository
from app.features.tagihan.service import TagihanService

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/tagihan",
    tags=["Menu Tagihan & Pembayaran"]
)

@router.get("/summary", response_model=APIResponseInvoiceSummary)
async def get_tagihan_summary(
    payment_state: Optional[str] = Query(None, description="Filter: 'not_paid', 'paid', atau 'partial'"),
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    partner_id = creds.get("partner_id")
    if not partner_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Data akun partner tidak ditemukan dalam sesi Anda."
        )

    try:
        repo = TagihanRepository(db)
        service = TagihanService(repo)
        data = await service.get_student_tagihan_summary(
            partner_id=partner_id,
            payment_state=payment_state
        )
        return APIResponseInvoiceSummary(
            success=True,
            message="Berhasil mengambil ringkasan tagihan siswa",
            data=data
        )
    except Exception as e:
        logger.error(f"[tagihan/summary] Error partner_id={partner_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data tagihan: {str(e)}"
        )