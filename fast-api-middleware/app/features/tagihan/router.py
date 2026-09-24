from fastapi import APIRouter, Depends, Query, HTTPException, status
from typing import Optional
from app.core.dependencies import get_odoo_client, get_current_user_credentials
from app.features.tagihan.schemas import APIResponseInvoiceSummary
from app.features.tagihan.repository import TagihanRepository
from app.features.tagihan.service import TagihanService

router = APIRouter(
    prefix="/tagihan",
    tags=["Menu Tagihan & Pembayaran"]
)

@router.get("/summary", response_model=APIResponseInvoiceSummary)
def get_tagihan_summary(
    payment_state: Optional[str] = Query(None, description="Filter: 'not_paid', 'paid', atau 'partial'"),
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = TagihanRepository(odoo_client)
        service = TagihanService(repo)

        data = service.get_student_tagihan_summary(
            uid=creds["uid"],
            password=creds["password"],
            payment_state=payment_state
        )

        return APIResponseInvoiceSummary(
            success=True,
            message="Berhasil mengambil ringkasan tagihan siswa",
            data=data
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data tagihan dari Odoo: {str(e)}"
        )