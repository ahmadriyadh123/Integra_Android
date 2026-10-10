from datetime import datetime, timezone
from unittest.mock import Mock

from app.features.weekly_plan.repository import WeeklyPlanRepository


def test_weekly_plan_delta_uses_write_date_and_class_scope():
    odoo = Mock()
    odoo.search_read.return_value = [
        {
            "id": 17,
            "course_id": [44, "Kelas 4"],
            "write_date": "2026-10-08 10:03:00",
        }
    ]
    cursor = datetime(2026, 10, 8, 10, 5, tzinfo=timezone.utc)

    records = WeeklyPlanRepository(odoo).get_weekly_plans(
        uid=3,
        password="secret",
        jenjang="sd",
        course_id=44,
        cursor=cursor,
    )

    kwargs = odoo.search_read.call_args.kwargs
    assert ("write_date", ">=", "2026-10-08 10:03:00") in kwargs["domain"]
    assert "write_date" in kwargs["fields"]
    assert records[0]["id"] == 17
