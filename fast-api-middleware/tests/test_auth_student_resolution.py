from app.features.auth.repository import AuthRepository


def test_login_reuses_student_relation_from_user_lookup():
    class OdooClient:
        db = "school_db"

        class Common:
            @staticmethod
            def authenticate(db, username, password, context):
                return 17

        common = Common()

        def __init__(self):
            self.search_calls = []

        def search_read(self, *, uid, password, model, domain, fields, limit, **kwargs):
            self.search_calls.append((model, fields))
            if model == "res.users":
                return [
                    {
                        "id": 17,
                        "name": "Siswa",
                        "login": "siswa",
                        "email": "siswa@example.com",
                        "partner_id": [27, "Siswa"],
                        "student_line": [41, "Siswa"],
                    }
                ]
            if model == "op.student":
                return [{"grade": [4, "Kelas 4"]}]
            raise AssertionError(f"Unexpected Odoo model: {model}")

    odoo = OdooClient()
    result = AuthRepository(odoo).authenticate_odoo_user("siswa", "password")

    assert result["student_id"] == 41
    assert result["course_id"] == 4
    assert [model for model, _ in odoo.search_calls] == [
        "res.users",
        "op.student",
    ]


class _OdooClient:
    def __init__(self):
        self.student_domains = []

    def search_read(self, *, uid, password, model, domain, fields, limit, **kwargs):
        if model == "res.users":
            raise ValueError("student relation fields are not installed")

        self.student_domains.append(domain)
        if domain == [("partner_id", "=", 27)]:
            return []
        if domain == [("user_id", "=", 17)]:
            return [{"id": 41}]
        if domain == [("id", "=", 41)]:
            return [{"grade": [4, "Kelas 4"]}]
        raise AssertionError(f"Unexpected Odoo domain: {domain}")


def test_student_resolution_falls_back_to_op_student_user_relation():
    odoo = _OdooClient()
    repository = AuthRepository(odoo)

    student_id, jenjang, course_id, course_name = (
        repository._resolve_student_and_jenjang(
            uid=17,
            password="password",
            partner_id=27,
        )
    )

    assert student_id == 41
    assert jenjang == "sd"
    assert course_id == 4
    assert course_name == "Kelas 4"
    assert [("user_id", "=", 17)] in odoo.student_domains
