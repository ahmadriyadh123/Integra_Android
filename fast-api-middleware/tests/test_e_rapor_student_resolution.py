from app.features.e_rapor.repository import ERaporRepository


class _OdooClient:
    def __init__(
        self,
        student_fields,
        student_records=None,
        user_fields=None,
        user_record=None,
    ):
        self.student_fields = student_fields
        self.student_records = student_records or {}
        self.user_fields = user_fields or {}
        self.user_record = user_record
        self.domains = []

    def execute_kw(self, *args):
        model = args[2]
        method = args[3]
        assert method == "fields_get"
        if model == "op.student":
            return self.student_fields
        if model == "res.users":
            return self.user_fields
        raise AssertionError(f"Unexpected metadata model: {model}")

    def search_read(self, *args):
        model = args[2]
        domain = args[3]
        fields = args[4]
        self.domains.append((model, domain, fields))
        if model == "op.student":
            field, _, relation_id = domain[0]
            return self.student_records.get((field, relation_id), [])
        if model == "res.users":
            return [self.user_record] if self.user_record else []
        raise AssertionError(f"Unexpected search model: {model}")


def test_resolves_student_by_partner_when_user_id_relation_has_no_match():
    odoo = _OdooClient(
        student_fields={"id": {}, "user_id": {}, "partner_id": {}},
        student_records={("partner_id", 27): [{"id": 41}]},
    )

    student_id = ERaporRepository(odoo).resolve_student_id(
        uid=17,
        password="secret",
        partner_id=27,
    )

    assert student_id == 41
    assert ("op.student", [("partner_id", "=", 27)], ["id"]) in odoo.domains


def test_resolves_student_from_res_users_relation_fields():
    odoo = _OdooClient(
        student_fields={"id": {}},
        user_fields={"student_line": {"type": "many2one"}},
        user_record={"student_line": [41, "Siswa"]},
    )

    student_id = ERaporRepository(odoo).resolve_student_id(
        uid=17,
        password="secret",
    )

    assert student_id == 41


def test_does_not_choose_arbitrary_student_when_partner_has_multiple_matches():
    odoo = _OdooClient(
        student_fields={"id": {}, "user_id": {}, "partner_id": {}},
        student_records={
            ("partner_id", 27): [{"id": 41}, {"id": 42}],
        },
        user_fields={"student_id": {"type": "many2one"}},
        user_record={"student_id": [43, "Siswa yang tepat"]},
    )

    student_id = ERaporRepository(odoo).resolve_student_id(
        uid=17,
        password="secret",
        partner_id=27,
    )

    assert student_id == 43
