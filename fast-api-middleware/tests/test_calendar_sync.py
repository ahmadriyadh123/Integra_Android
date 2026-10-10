from datetime import datetime, timezone
from unittest.mock import Mock

from app.features.calendar.repository import CalendarRepository


def test_calendar_repository_filters_by_class_and_write_date():
    odoo = Mock()
    odoo.execute_kw.return_value = {
        "id": {"type": "integer"},
        "course_id": {"type": "many2one"},
        "semester_id": {"type": "many2one"},
        "tahun_id": {"type": "many2one"},
        "link_dokumen": {"type": "char"},
        "status": {"type": "char"},
        "write_date": {"type": "datetime"},
    }
    odoo.search_read.return_value = [{"id": 9, "write_date": "2026-10-08 09:04:00"}]

    records = CalendarRepository(odoo).get_academic_calendars(
        uid=7,
        password="secret",
        course_id=32,
        cursor=datetime(2026, 10, 8, 9, 5, tzinfo=timezone.utc),
    )

    kwargs = odoo.search_read.call_args.kwargs
    assert ("course_id", "=", 32) in kwargs["domain"]
    assert ("write_date", ">=", "2026-10-08 09:03:00") in kwargs["domain"]
    assert "write_date" in kwargs["fields"]
    assert records == [{"id": 9, "write_date": "2026-10-08 09:04:00"}]
