from app.features.auth.repository import AuthRepository


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
