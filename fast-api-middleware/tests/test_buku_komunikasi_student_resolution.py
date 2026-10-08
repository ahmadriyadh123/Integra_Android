import pytest
from fastapi import HTTPException

from app.features.buku_komunikasi.router import _resolve_student_id


class _OdooClient:
    def __init__(self, student_id):
        self.student_id = student_id
        self.domains = []

    def search_read(self, **kwargs):
        uid = kwargs["uid"]
        model = kwargs["model"]
        domain = kwargs["domain"]
        self.domains.append(domain)
        assert all(value is not None for condition in domain for value in condition)

        if model == "res.users":
            raise ValueError("student relation is not installed")
        if model == "op.student" and domain == [("user_id", "=", uid)]:
            return [{"id": self.student_id}] if self.student_id else []
        if model == "op.student" and domain == [("id", "=", self.student_id)]:
            return [{"grade": [4, "Kelas 4"]}]
        return []


def test_resolves_missing_student_id_without_sending_none_to_odoo():
    odoo = _OdooClient(student_id=41)

    student_id = _resolve_student_id(
        {"uid": 17, "password": "secret", "student_id": None},
        odoo,
    )

    assert student_id == 41
    assert all(
        value is not None
        for domain in odoo.domains
        for condition in domain
        for value in condition
    )


def test_missing_student_relation_returns_forbidden_instead_of_rpc_error():
    odoo = _OdooClient(student_id=None)

    with pytest.raises(HTTPException) as exc_info:
        _resolve_student_id(
            {"uid": 17, "password": "secret", "student_id": None},
            odoo,
        )

    assert exc_info.value.status_code == 403
