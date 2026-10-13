from unittest.mock import AsyncMock

import pytest

from app.features.calendar.repository import CalendarRepository
from app.features.calendar import router as calendar_router
from app.features.calendar.service import CalendarService


class _Result:
    def mappings(self):
        return self

    def all(self):
        return [
            {
                "id": 9,
                "kelas_id": 32,
                "kelas_name": "Kelas 7",
                "semester_name": "Semester 1",
                "tahun_name": "2025/2026",
                "link_dokumen": "",
                "status": "published",
            }
        ]


@pytest.mark.asyncio
async def test_calendar_query_filters_using_kelas_id_and_returns_contract_items():
    db = AsyncMock()
    db.execute.return_value = _Result()
    service = CalendarService(CalendarRepository(db))

    data = await service.get_calendars_list(course_id=32, jenjang="smp")

    query = str(db.execute.await_args.args[0])
    assert "k.kelas_id = :course_id" in query
    assert db.execute.await_args.args[1] == {"course_id": 32}
    assert data["calendars"] == [
        {
            "id": 9,
            "kelas": "Kelas 7",
            "semester": "Semester 1",
            "tahun_ajaran": "2025/2026",
            "link_dokumen": "",
            "status": "published",
        }
    ]


@pytest.mark.asyncio
async def test_calendar_repository_rejects_invalid_level_before_query():
    db = AsyncMock()
    repository = CalendarRepository(db)

    with pytest.raises(ValueError, match="Jenjang kalender tidak didukung"):
        await repository.get_academic_calendars(course_id=32, jenjang="invalid")

    db.execute.assert_not_awaited()


@pytest.mark.asyncio
async def test_calendar_sync_returns_full_snapshot_contract(monkeypatch):
    async def get_calendars_list(self, course_id, jenjang):
        assert course_id == 32
        assert jenjang == "smp"
        return {
            "total_records": 1,
            "calendars": [{"id": 9, "kelas": "Kelas 7"}],
        }

    monkeypatch.setattr(CalendarService, "get_calendars_list", get_calendars_list)

    response = await calendar_router.sync_academic_calendars(
        creds={"uid": 4, "course_id": 32, "jenjang": "smp"},
        db=AsyncMock(),
    )

    assert response["success"] is True
    assert response["data"]["items"] == [{"id": 9, "kelas": "Kelas 7"}]
    assert response["data"]["removed_ids"] == []
    assert response["data"]["full_sync"] is True
    assert response["data"]["next_cursor"]
