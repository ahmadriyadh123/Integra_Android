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
            "kelas_id": {"type": "many2one"},
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
                "kelas_id": [3, "Kelas 3"],
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
        "kelas_id",
        "semester_id",
        "link_dokumen",
        "status",
    ]
    assert odoo.requested_order == "semester_id asc"
    assert odoo.requested_domain == [("kelas_id", "=", 3)]
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


def test_calendar_repository_rejects_unsupported_level_before_odoo_request():
    odoo = _TenantOdooClient()

    try:
        CalendarRepository(odoo).get_academic_calendars(
            uid=17,
            password="secret",
            course_id=3,
            jenjang="invalid",
        )
    except ValueError as exc:
        assert "Jenjang kalender tidak didukung" in str(exc)
    else:
        raise AssertionError("Calendar lookup must reject unsupported levels.")

    assert odoo.requested_fields is None


def test_calendar_repository_supports_legacy_kelas_id_field():
    class LegacyCalendarOdooClient(_TenantOdooClient):
        def execute_kw(self, **kwargs):
            assert kwargs["model"] == "kaldik.sd"
            assert kwargs["method"] == "fields_get"
            return {
                "id": {"type": "integer"},
                "kelas_id": {"type": "many2one"},
                "semester_id": {"type": "many2one"},
                "tahun_id": {"type": "many2one"},
                "link_dokumen": {"type": "char"},
                "status": {"type": "char"},
            }

        def search_read(self, **kwargs):
            self.requested_fields = kwargs["fields"]
            self.requested_domain = kwargs["domain"]
            return [
                {
                    "id": 9,
                    "kelas_id": [3, "Kelas 3"],
                    "semester_id": [1, "Semester 1"],
                    "tahun_id": [2, "2025/2026"],
                    "link_dokumen": "https://example.test/calendar",
                    "status": "published",
                }
            ]

    odoo = LegacyCalendarOdooClient()
    result = CalendarService(CalendarRepository(odoo)).get_calendars_list(
        uid=17,
        password="password",
        course_id=3,
        jenjang="sd",
    )

    assert odoo.requested_fields == [
        "id",
        "kelas_id",
        "semester_id",
        "tahun_id",
        "link_dokumen",
        "status",
    ]
    assert odoo.requested_domain == [("kelas_id", "=", 3)]
    assert result["calendars"][0]["kelas"] == "Kelas 3"
    assert result["calendars"][0]["tahun_ajaran"] == "2025/2026"


def test_calendar_repository_does_not_fallback_to_course_id():
    class CalendarWithoutKelasIdClient(_TenantOdooClient):
        def execute_kw(self, **kwargs):
            return {
                "id": {"type": "integer"},
                "course_id": {"type": "many2one"},
                "semester_id": {"type": "many2one"},
            }

    try:
        CalendarRepository(CalendarWithoutKelasIdClient()).get_academic_calendars(
            uid=17,
            password="secret",
            course_id=3,
            jenjang="sd",
        )
    except RuntimeError as exc:
        assert "tidak memiliki field kelas_id" in str(exc)
    else:
        raise AssertionError("Calendar lookup must require kaldik.kelas_id.")
