from app.features.calendar.repository import CalendarRepository
from app.features.calendar.service import CalendarService


class _TenantOdooClient:
    def __init__(self):
        self.requested_fields = None
        self.requested_order = None
        self.requested_domain = None

    def execute_kw(self, **kwargs):
        assert kwargs["model"] == "kaldik.sd"
        assert kwargs["method"] == "fields_get"
        return {
            "id": {"type": "integer"},
            "course_id": {"type": "many2one"},
            "semester_id": {"type": "many2one"},
            "link_dokumen": {"type": "char"},
            "status": {"type": "char"},
        }

    def search_read(self, **kwargs):
        self.requested_fields = kwargs["fields"]
        self.requested_order = kwargs["order"]
        self.requested_domain = kwargs["domain"]
        return [
            {
                "id": 8,
                "course_id": [3, "Kelas 3"],
                "semester_id": [1, "Semester 1"],
                "link_dokumen": "https://example.test/calendar",
                "status": "published",
            }
        ]


def test_calendar_query_uses_only_tenant_fields_and_supported_order():
    odoo = _TenantOdooClient()
    service = CalendarService(CalendarRepository(odoo))

    result = service.get_calendars_list(
        uid=17,
        password="secret",
        course_id=3,
        jenjang="sd",
    )

    assert odoo.requested_fields == [
        "id",
        "course_id",
        "semester_id",
        "link_dokumen",
        "status",
    ]
    assert odoo.requested_order == "semester_id asc"
    assert odoo.requested_domain == [("course_id", "=", 3)]
    assert result["calendars"][0]["kelas"] == "Kelas 3"
    assert result["calendars"][0]["tahun_ajaran"] == "-"


def test_calendar_repository_rejects_missing_student_class():
    odoo = _TenantOdooClient()
    repository = CalendarRepository(odoo)

    try:
        repository.get_academic_calendars(
            uid=17,
            password="secret",
            course_id=0,
            jenjang="sd",
        )
    except ValueError as exc:
        assert str(exc) == "Akun Odoo belum terhubung ke kelas siswa."
    else:
        raise AssertionError("Calendar lookup must require a student class.")
