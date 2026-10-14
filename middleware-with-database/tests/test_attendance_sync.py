from datetime import date
from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest
from fastapi import FastAPI

from app.features.attendance import router as attendance_router
from app.features.attendance.router import router
from app.api import api_router


@pytest.mark.asyncio
async def test_attendance_sync_returns_full_snapshot_contract(monkeypatch):
    service = SimpleNamespace(
        get_student_history=AsyncMock(
            return_value=[
                SimpleNamespace(
                    model_dump=lambda mode: {
                        "id": 12,
                        "student_id": 4,
                        "student_name": "Siswa",
                        "attendance_date": date(2026, 10, 14).isoformat(),
                        "present": True,
                        "excused": False,
                        "absent": False,
                        "sick": False,
                        "status": "hadir",
                        "remark": None,
                    }
                )
            ]
        )
    )
    monkeypatch.setattr(
        attendance_router,
        "AttendanceService",
        lambda _repository: service,
    )

    result = await attendance_router.sync_attendance_history(
        limit=500,
        creds={"uid": 8, "student_id": 4},
        db=object(),
    )

    assert result["success"] is True
    assert result["data"]["items"][0]["id"] == 12
    assert result["data"]["removed_ids"] == []
    assert result["data"]["full_sync"] is True
    assert result["data"]["next_cursor"]
    service.get_student_history.assert_awaited_once_with(
        student_id=4,
        limit=500,
    )


def test_attendance_sync_route_is_registered():
    app = FastAPI()
    app.include_router(api_router)

    assert "/api/v1/attendance/history/sync" in app.openapi()["paths"]
