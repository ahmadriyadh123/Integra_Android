# app/features/weekly_plan/router.py
import logging
import io
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_current_user_credentials
from app.features.weekly_plan.schemas import (
    APIResponseWeeklyPlanList,
    APIResponseWeeklyPlanDetail
)
from app.features.weekly_plan.repository import WeeklyPlanRepository
from app.features.weekly_plan.service import WeeklyPlanService

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/weekly-plan",
    tags=["Menu Weekly Plan"]
)

@router.get("/list", response_model=APIResponseWeeklyPlanList)
async def get_weekly_plans(
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    try:
        repo = WeeklyPlanRepository(db)
        service = WeeklyPlanService(repo)

        data = await service.get_weekly_plan_list(
            jenjang=creds.get("jenjang", "sd"),
            course_id=creds.get("course_id")
        )

        return APIResponseWeeklyPlanList(
            success=True,
            message="Berhasil mengambil daftar Weekly Plan",
            data=data
        )
    except Exception as e:
        logger.error(f"[weekly-plan/list] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil daftar Weekly Plan: {str(e)}"
        )

@router.get("/detail/{plan_id}", response_model=APIResponseWeeklyPlanDetail)
async def get_weekly_plan_detail(
    plan_id: int,
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    try:
        repo = WeeklyPlanRepository(db)
        service = WeeklyPlanService(repo)

        data = await service.get_weekly_plan_detail(
            plan_id=plan_id,
            jenjang=creds.get("jenjang", "sd")
        )

        if not data:
            return APIResponseWeeklyPlanDetail(
                success=False,
                message="Dokumen Weekly Plan tidak ditemukan",
                data=None
            )

        return APIResponseWeeklyPlanDetail(
            success=True,
            message=f"Berhasil mengambil detail Weekly Plan ID {plan_id}",
            data=data
        )
    except Exception as e:
        logger.error(f"[weekly-plan/detail/{plan_id}] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil detail Weekly Plan: {str(e)}"
        )

@router.get("/pdf/{plan_id}")
async def get_weekly_plan_pdf(
    plan_id: int,
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    """
    Ambil file PDF Weekly Plan dari ir_attachment dan stream ke client.
    """
    try:
        repo = WeeklyPlanRepository(db)
        jenjang = creds.get("jenjang", "sd")
        header = await repo.get_weekly_plan_by_id(plan_id=plan_id, jenjang=jenjang)

        if not header:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Weekly Plan ID {plan_id} tidak ditemukan"
            )

        kelas = str(header.get('course_name') or 'SD').replace(' ', '_')
        pekan = str(header.get('pekan') or '').replace(' ', '_').replace('/', '-')
        filename = f"WeeklyPlan_{kelas}_{pekan}.pdf"

        attachment_id = header.get('message_main_attachment_id')

        if not attachment_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="File PDF Weekly Plan belum tersedia. Hubungi admin untuk upload file."
            )

        pdf_bytes = await repo.get_attachment_pdf(attachment_id=attachment_id)

        if not pdf_bytes:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="File PDF tidak dapat dibaca. Hubungi admin untuk upload ulang."
            )

        logger.info(f"[weekly-plan/pdf/{plan_id}] serve dari ir_attachment id={attachment_id}")

        return StreamingResponse(
            io.BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={
                "Content-Disposition": f'inline; filename="{filename}"',
                "Content-Length": str(len(pdf_bytes)),
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[weekly-plan/pdf/{plan_id}] Error uid={creds.get('uid')}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil PDF Weekly Plan: {str(e)}"
        )