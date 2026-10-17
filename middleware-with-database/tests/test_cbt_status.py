from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock

import pytest

from app.features.cbt.service import CbtService


@pytest.mark.asyncio
async def test_exam_status_uses_database_status_and_schedule_window():
    repository = AsyncMock()
    repository.get_schedules.return_value = [
        {
            "id": 12,
            "name": "Ujian Test",
            "status": "published",
            "tanggal_mulai": (
                datetime.now(timezone.utc) + timedelta(hours=1)
            ).isoformat(),
            "tanggal_selesai": (
                datetime.now(timezone.utc) + timedelta(hours=2)
            ).isoformat(),
        }
    ]
    repository.get_hasil_ujian.return_value = []

    result = await CbtService(repository).get_exam_list(student_id=7)

    assert result["exams"][0]["status"] == "Belum Dimulai"
    assert result["exams"][0]["raw_status"] == "published"


@pytest.mark.asyncio
async def test_completed_exam_status_comes_from_student_results():
    repository = AsyncMock()
    repository.get_schedules.return_value = [
        {
            "id": 12,
            "name": "Ujian Test",
            "status": "published",
            "tanggal_mulai": "2026-01-01 08:00:00",
            "tanggal_selesai": "2099-01-01 08:00:00",
        }
    ]
    repository.get_hasil_ujian.return_value = [{"jadwal_ujian_id": 12}]

    result = await CbtService(repository).get_exam_list(student_id=7)

    assert result["exams"][0]["status"] == "Selesai"
    assert result["exams"][0]["raw_status"] == "published"
