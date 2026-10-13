from datetime import datetime, timezone
from unittest.mock import AsyncMock

import pytest
from fastapi import FastAPI

from app.features.weekly_plan.repository import WeeklyPlanRepository
from app.api import api_router
from app.features.weekly_plan.service import WeeklyPlanService


class _Result:
    def __init__(self, rows=None):
        self.rows = rows or []

    def mappings(self):
        return self

    def all(self):
        return self.rows


@pytest.mark.asyncio
async def test_weekly_plan_sync_returns_full_snapshot_contract():
    repository = AsyncMock()
    repository.parse_sync_cursor = WeeklyPlanRepository.parse_sync_cursor
    repository.get_weekly_plans.return_value = [
        {
            "id": 8,
            "course_name": "Kelas 1",
            "semester_name": "Gasal",
            "tahun_ajaran_name": "2026/2027",
            "pekan": "Pekan 1",
            "tema": "Lingkunganku",
            "nama_guru": "Guru",
            "status": "submitted",
        }
    ]

    result = await WeeklyPlanService(repository).sync_weekly_plan_list(
        jenjang="sd",
        course_id=3,
        cursor=None,
    )

    assert result["full_sync"] is True
    assert result["removed_ids"] == []
    assert result["items"][0]["id"] == 8
    assert result["next_cursor"]
    repository.get_weekly_plans.assert_awaited_once_with(
        jenjang="sd",
        course_id=3,
        cursor=None,
    )


@pytest.mark.asyncio
async def test_weekly_plan_delta_parses_cursor_and_maps_items():
    repository = AsyncMock()
    repository.parse_sync_cursor = WeeklyPlanRepository.parse_sync_cursor
    repository.get_weekly_plans.return_value = [
        {
            "id": 12,
            "course_name": "Kelas 2",
            "semester_name": "Gasal",
            "tahun_ajaran_name": "2026/2027",
            "pekan": "Pekan 4",
            "tema": "Air",
            "nama_guru": "Guru",
            "status": "draft",
        }
    ]

    result = await WeeklyPlanService(repository).sync_weekly_plan_list(
        jenjang="smp",
        course_id=6,
        cursor="2026-10-12T00:00:00Z",
    )

    assert result["full_sync"] is False
    assert result["items"][0]["id"] == 12
    repository.get_weekly_plans.assert_awaited_once_with(
        jenjang="smp",
        course_id=6,
        cursor=datetime(2026, 10, 12, tzinfo=timezone.utc),
    )


@pytest.mark.asyncio
async def test_weekly_plan_repository_filters_delta_by_class_and_overlap():
    db = AsyncMock()
    db.execute.return_value = _Result(rows=[])
    cursor = datetime(2026, 10, 12, tzinfo=timezone.utc)

    await WeeklyPlanRepository(db).get_weekly_plans(
        jenjang="sd",
        course_id=3,
        cursor=cursor,
    )

    query = str(db.execute.await_args.args[0])
    params = db.execute.await_args.args[1]
    assert "wp.write_date >= :since" in query
    assert "wp.course_id = :course_id" in query
    assert "weekly_plan_sd" in query
    assert params["course_id"] == 3
    assert params["since"] == datetime(2026, 10, 11, 23, 58)


@pytest.mark.asyncio
async def test_weekly_plan_sync_rejects_invalid_cursor():
    with pytest.raises(ValueError, match="Cursor Weekly Plan tidak valid"):
        await WeeklyPlanService(WeeklyPlanRepository(AsyncMock())).sync_weekly_plan_list(
            jenjang="sd",
            course_id=None,
            cursor="not-a-date",
        )


def test_weekly_plan_sync_route_is_registered():
    app = FastAPI()
    app.include_router(api_router)

    assert "/api/v1/weekly-plan/list/sync" in app.openapi()["paths"]
