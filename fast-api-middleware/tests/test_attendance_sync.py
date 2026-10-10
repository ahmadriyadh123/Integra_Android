from datetime import datetime, timezone
from unittest.mock import Mock

from app.features.attendance.repository import AttendanceRepository
from app.features.attendance.service import AttendanceService


def test_attendance_repository_filters_delta_by_write_date_with_overlap():
    odoo = Mock()
    odoo.search_read.return_value = [
        {
            "id": 14,
            "attendance_date": "2026-10-08",
            "write_date": "2026-10-08 09:04:00",
        }
    ]
    cursor = datetime(2026, 10, 8, 9, 5, tzinfo=timezone.utc)

    records = AttendanceRepository(odoo).get_attendance_history(
        uid=7,
        password="secret",
        student_id=19,
        cursor=cursor,
    )

    kwargs = odoo.search_read.call_args.kwargs
    assert ("student_id", "=", 19) in kwargs["domain"]
    assert (
        "write_date",
        ">=",
        "2026-10-08 09:03:00",
    ) in kwargs["domain"]
    assert "write_date" in kwargs["fields"]
    assert records[0]["id"] == 14


def test_attendance_service_preserves_write_date_for_sync_cursor():
    repository = Mock()
    repository.get_attendance_history.return_value = [
        {
            "id": 14,
            "student_id": [19, "Siswa"],
            "course_id": [3, "Kelas 1"],
            "batch_id": [4, "A"],
            "attendance_date": "2026-10-08",
            "write_date": "2026-10-08 09:04:00",
        }
    ]

    result = AttendanceService(repository).get_student_history(
        uid=7,
        password="secret",
        student_id=19,
        cursor=datetime(2026, 10, 8, 9, 5, tzinfo=timezone.utc),
    )

    assert result[0]["write_date"] == "2026-10-08 09:04:00"
    assert repository.get_attendance_history.call_args.kwargs["cursor"].minute == 5
