import asyncio
import logging
import io
import re
from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_current_user_credentials
from app.features.weekly_plan.schemas import (
    APIResponseWeeklyPlanList,
    APIResponseWeeklyPlanDetail
)
from app.features.weekly_plan.repository import WeeklyPlanRepository
from app.features.weekly_plan.service import WeeklyPlanService
from app.features.weekly_plan.pdf_generator import generate_weekly_plan_pdf  # 👈 Import Generator

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/weekly-plan",
    tags=["Menu Weekly Plan"]
)

@router.get("/list/sync")
async def sync_weekly_plans(
    cursor: str | None = Query(None),
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    try:
        service = WeeklyPlanService(WeeklyPlanRepository(db))
        data = await service.sync_weekly_plan_list(
            jenjang=creds.get("jenjang", "sd"),
            course_id=creds.get("course_id"),
            cursor=cursor,
        )
        return {
            "success": True,
            "data": data,
        }
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Daftar rencana mingguan perlu dimuat ulang. "
                "Silakan coba perbarui halaman."
            ),
        ) from exc
    except Exception as exc:
        logger.exception(
            "[weekly-plan/list/sync] Error uid=%s",
            creds.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Rencana mingguan belum dapat diperbarui. Silakan coba lagi.",
        ) from exc

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
        logger.exception(
            "[weekly-plan/list] Error uid=%s",
            creds.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Rencana mingguan belum dapat dimuat. Silakan coba lagi.",
        ) from e

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
        logger.exception(
            "[weekly-plan/detail/%s] Error uid=%s",
            plan_id,
            creds.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Detail rencana mingguan belum dapat dimuat. Silakan coba lagi.",
        ) from e

@router.get("/pdf/{plan_id}")
async def get_weekly_plan_pdf(
    plan_id: int,
    creds: dict = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    """
    Mengambil PDF Weekly Plan:
    1. Coba ambil dari ir_attachment jika ketersediaan attachment_id valid.
    2. Jika attachment kosong, render template Word dan konversi ke PDF.
    """
    try:
        repo = WeeklyPlanRepository(db)
        service = WeeklyPlanService(repo)
        jenjang = creds.get("jenjang", "sd")

        header = await repo.get_weekly_plan_by_id(plan_id=plan_id, jenjang=jenjang)
        if not header:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Rencana mingguan tidak ditemukan."
            )

        safe_part = lambda value: str(value or '').strip().replace(' ', '_').replace('/', '-').replace('\\', '-')
        semester = safe_part(header.get('semester_name') or 'Semester')
        kelas = safe_part(header.get('course_name') or 'SD')
        minggu = str(header.get('pekan') or '').strip()
        minggu = re.sub(r'^(pekan|minggu)\s+', '', minggu, flags=re.IGNORECASE)
        filename = f"Weekly_Plan_{semester}_{kelas}_{safe_part(minggu)}.pdf"

        pdf_bytes = None
        attachment_id = header.get('message_main_attachment_id')

        # 1. Coba fetch dari ir_attachment
        if attachment_id:
            pdf_bytes = await repo.get_attachment_pdf(attachment_id=attachment_id)
            if pdf_bytes:
                logger.info(f"[weekly-plan/pdf/{plan_id}] Served dari ir_attachment id={attachment_id}")

        # 2. Fallback: Generate PDF dinamis via ReportLab
        if not pdf_bytes:
            logger.info(
                "[weekly-plan/pdf/%s] Attachment tidak ditemukan/kosong. "
                "Generating PDF dari template Word...",
                plan_id,
            )
            detail_data = await service.get_weekly_plan_detail(plan_id=plan_id, jenjang=jenjang)
            if not detail_data:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Data detail Weekly Plan tidak dapat dimuat untuk pembuatan PDF."
                )
            detail_data["jenjang"] = jenjang
            pdf_bytes = await asyncio.to_thread(
                generate_weekly_plan_pdf,
                detail_data,
            )

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
        logger.exception(
            "[weekly-plan/pdf/%s] Error uid=%s",
            plan_id,
            creds.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Dokumen rencana mingguan belum dapat dibuka. Silakan coba lagi.",
        ) from e
