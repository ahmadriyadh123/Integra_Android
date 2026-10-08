import pytest

from app.features.elearning.repository import ElearningRepository


class DummyResult:
    def __init__(self, row):
        self._row = row

    def mappings(self):
        return self

    def first(self):
        return self._row

    def all(self):
        return [self._row]


class DummyDB:
    def __init__(self, row=None):
        self.row = row

    async def execute(self, query, params=None):
        return DummyResult(self.row)


@pytest.mark.asyncio
async def test_get_course_by_id_accepts_course_id_keyword():
    dummy_row = {
        "id": 12,
        "name": "Matematika Wajib",
        "teacher_name": "Bpk. Hendra",
        "description": "Deskripsi",
        "total_slides": 8,
    }

    repo = ElearningRepository(DummyDB(dummy_row))

    result = await repo.get_course_by_id(course_id=12)

    assert result == dummy_row
