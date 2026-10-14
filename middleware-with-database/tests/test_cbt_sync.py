from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest
from fastapi import FastAPI

from app.api import api_router
from app.features.cbt import router as cbt_router
from app.features.cbt.router import router


@pytest.mark.asyncio
async def test_cbt_sync_returns_full_snapshot_contract(monkeypatch):
    service = SimpleNamespace(
        get_exam_list=AsyncMock(
            return_value={
                "total_exams": 1,
                "exams": [
                    {
                        "id": 31,
                        "judul_ujian": "Ujian Tengah Semester",
                        "status": "published",
                        "mata_pelajaran": "Matematika",
                        "jenis_ujian": "UTS",
                        "tanggal_mulai": "2026-10-14 08:00:00",
                        "tanggal_selesai": "2026-10-14 09:00:00",
                        "rentang_waktu": "2026-10-14 08:00:00 - 2026-10-14 09:00:00",
                        "durasi_menit": 60,
                        "durasi_label": "Durasi: 60 menit",
                        "jumlah_soal": 20,
                        "passing_grade": 70.0,
                        "token_required": True,
                    }
                ],
            }
        )
    )
    monkeypatch.setattr(cbt_router, "CbtService", lambda _repository: service)

    result = await cbt_router.sync_cbt_schedules(
        creds={"uid": 8, "student_id": 4, "course_id": 3},
        db=object(),
    )

    assert result["success"] is True
    assert result["data"]["exams"][0]["id"] == 31
    assert result["data"]["removed_ids"] == []
    assert result["data"]["is_full_sync"] is True
    assert result["data"]["cursor"]
    service.get_exam_list.assert_awaited_once_with(course_id=3, student_id=4)


def test_cbt_sync_route_is_registered():
    app = FastAPI()
    app.include_router(api_router)

    assert "/api/v1/cbt/schedules/sync" in app.openapi()["paths"]
