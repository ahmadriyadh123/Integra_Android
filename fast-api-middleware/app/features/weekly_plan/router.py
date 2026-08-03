from fastapi import APIRouter, Depends, HTTPException, status
from app.core.dependencies import get_odoo_client, get_current_user_credentials
from app.features.weekly_plan.schemas import (
    APIResponseWeeklyPlanList,
    APIResponseWeeklyPlanDetail
)
from app.features.weekly_plan.repository import WeeklyPlanRepository
from app.features.weekly_plan.service import WeeklyPlanService

router = APIRouter(
    prefix="/weekly-plan",
    tags=["Menu Weekly Plan"]
)

@router.get("/list", response_model=APIResponseWeeklyPlanList)
def get_weekly_plans(
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = WeeklyPlanRepository(odoo_client)
        service = WeeklyPlanService(repo)

        data = service.get_weekly_plan_list(
            uid=creds["uid"],
            password=creds["password"]
        )

        return APIResponseWeeklyPlanList(
            success=True,
            message="Berhasil mengambil daftar Weekly Plan",
            data=data
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil daftar Weekly Plan dari Odoo: {str(e)}"
        )

@router.get("/detail/{plan_id}", response_model=APIResponseWeeklyPlanDetail)
def get_weekly_plan_detail(
    plan_id: int,
    creds: dict = Depends(get_current_user_credentials),
    odoo_client = Depends(get_odoo_client)
):
    try:
        repo = WeeklyPlanRepository(odoo_client)
        service = WeeklyPlanService(repo)

        data = service.get_weekly_plan_detail(
            uid=creds["uid"],
            password=creds["password"],
            plan_id=plan_id
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
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil detail Weekly Plan dari Odoo: {str(e)}"
        )