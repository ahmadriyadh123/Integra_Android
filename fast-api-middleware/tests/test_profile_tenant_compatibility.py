from app.features.profile.repository import ProfileRepository
from app.features.profile.service import ProfileService


class _TenantOdooClient:
    def __init__(self):
        self.requested_fields = None
        self.domain = None

    def execute_kw(self, **kwargs):
        assert kwargs["model"] == "op.student"
        assert kwargs["method"] == "fields_get"
        return {
            "id": {"type": "integer"},
            "partner_id": {"type": "many2one"},
            "gr_no": {"type": "char"},
            "date_of_birth": {"type": "date"},
            "course_id": {"type": "many2one"},
            "batch_id": {"type": "many2one"},
            "user_id": {"type": "many2one"},
        }

    def search_read(self, **kwargs):
        self.domain = kwargs["domain"]
        self.requested_fields = kwargs["fields"]
        return [
            {
                "id": 41,
                "partner_id": [27, "Siswa Sekolah B"],
                "gr_no": "NIS-B",
                "date_of_birth": "2015-04-10",
                "course_id": [4, "Kelas 4"],
                "batch_id": [8, "Reguler"],
            }
        ]


def test_profile_uses_fields_supported_by_tenant_odoo():
    odoo = _TenantOdooClient()
    service = ProfileService(ProfileRepository(odoo))

    result = service.get_student_profile(
        uid=17,
        password="password",
        user_id=17,
        partner_id=27,
        student_id=41,
    )

    profile = result["profile"]
    assert "active" not in odoo.requested_fields
    assert "nis" not in odoo.requested_fields
    assert "birth_date" not in odoo.requested_fields
    assert odoo.domain == [("id", "=", 41)]
    assert profile["nis"] == "NIS-B"
    assert profile["kelas"] == "Kelas 4"
    assert profile["rombel"] == "Reguler"
    assert profile["tanggal_lahir"] == "2015-04-10"
    assert profile["nama_lengkap"] == "Siswa Sekolah B"
