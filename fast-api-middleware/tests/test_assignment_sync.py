from app.features.assignment.repository import AssignmentRepository


class _AssignmentOdoo:
    def __init__(self):
        self.calls = []

    def execute_kw(self, uid, password, model, method, args, kwargs):
        assert method == "fields_get"
        if model == "op.assignment":
            return {
                "student_ids": {"type": "many2many", "relation": "op.student"},
                "grading_assignment_id": {
                    "type": "many2one",
                    "relation": "grading.assignment",
                },
                "write_date": {"type": "datetime"},
            }
        if model == "op.assignment.sub.line":
            return {
                "student_id": {"type": "many2one", "relation": "op.student"},
                "assignment_id": {
                    "type": "many2one",
                    "relation": "op.assignment",
                },
                "write_date": {"type": "datetime"},
            }
        if model == "grading.assignment":
            return {"write_date": {"type": "datetime"}}
        if model == "ir.attachment":
            return {
                "res_model": {"type": "char"},
                "res_id": {"type": "integer"},
                "write_date": {"type": "datetime"},
            }
        raise AssertionError(model)

    def search_read(self, **kwargs):
        self.calls.append(kwargs)
        model = kwargs["model"]
        domain = kwargs["domain"]
        if model == "op.assignment":
            if ("write_date", ">=", "2026-10-09 10:58:00") in domain:
                return [{"id": 1}]
            if ("grading_assignment_id", "in", [3]) in domain:
                return [{"id": 2}]
        if model == "op.assignment.sub.line":
            if ("write_date", ">=", "2026-10-09 10:58:00") in domain:
                return [{"id": 40, "assignment_id": [4, "Tugas"]}]
            if ("id", "in", [50]) in domain:
                return [{"id": 50, "assignment_id": [5, "Tugas"]}]
        if model == "grading.assignment":
            return [{"id": 3}]
        if model == "ir.attachment":
            return [
                {
                    "id": 60,
                    "res_model": "op.assignment",
                    "res_id": 6,
                },
                {
                    "id": 61,
                    "res_model": "op.assignment.sub.line",
                    "res_id": 50,
                },
            ]
        return []


def test_assignment_cursor_includes_base_and_related_record_changes():
    odoo = _AssignmentOdoo()
    sync = AssignmentRepository(odoo).get_assignment_sync_delta(
        uid=7,
        password="pw",
        student_id=22,
        cursor="2026-10-09T11:00:00Z",
    )

    assert sync["full_sync"] is False
    assert sync["assignment_ids"] == [1, 2, 4, 5, 6]
    assert sync["removed_ids"] == []
    assert sync["next_cursor"]
    assert any(
        call["model"] == "grading.assignment"
        and call["domain"] == [("write_date", ">=", "2026-10-09 10:58:00")]
        for call in odoo.calls
    )


def test_assignment_missing_write_date_is_not_silently_treated_as_delta():
    odoo = _AssignmentOdoo()
    original = odoo.execute_kw

    def metadata_without_write_date(uid, password, model, method, args, kwargs):
        result = original(uid, password, model, method, args, kwargs)
        if model == "grading.assignment":
            return {}
        return result

    odoo.execute_kw = metadata_without_write_date
    try:
        AssignmentRepository(odoo).get_assignment_sync_delta(
            uid=7,
            password="pw",
            student_id=22,
            cursor="2026-10-09T11:00:00Z",
        )
        assert False, "expected unsupported cursor source to fail"
    except RuntimeError as error:
        assert "write_date" in str(error)


def test_assignment_first_request_is_a_full_reconciliation():
    sync = AssignmentRepository(_AssignmentOdoo()).get_assignment_sync_delta(
        uid=7, password="pw", student_id=22, cursor=None
    )

    assert sync["full_sync"] is True
    assert sync["assignment_ids"] is None
    assert sync["next_cursor"]
