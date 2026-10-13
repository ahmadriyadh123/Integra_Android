from unittest.mock import AsyncMock

import pytest

from app.features.auth.repository import AuthRepository, pwd_context


class _Result:
    def __init__(self, row):
        self.row = row

    def mappings(self):
        return self

    def first(self):
        return self.row


@pytest.mark.asyncio
async def test_authentication_returns_class_id_and_level_from_student_grade(monkeypatch):
    db = AsyncMock()
    db.execute.return_value = _Result(
        {
            "user_id": 4,
            "login": "student@example.test",
            "password_hash": "hashed",
            "partner_id": 8,
            "full_name": "Student",
            "email": "student@example.test",
            "student_id": 12,
            "nis": "NIS-12",
            "course_id": 32,
            "course_name": "Kelas 7 SMP",
        }
    )
    repository = AuthRepository(db)
    repository.get_user_groups = AsyncMock(return_value=[])
    monkeypatch.setattr(pwd_context, "verify", lambda plain, hashed: True)

    user = await repository.authenticate_user(
        "student@example.test",
        "password",
    )

    assert user["course_id"] == 32
    assert user["jenjang"] == "smp"
    query = str(db.execute.await_args_list[0].args[0])
    assert "s.grade AS course_id" in query
    assert "LEFT JOIN op_course c ON c.id = s.grade" in query
