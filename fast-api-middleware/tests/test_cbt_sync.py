from app.features.cbt.service import CbtService
from app.features.cbt.repository import CbtRepository
import pytest


class SyncRepository:
    def __init__(self):
        self.hasil_calls = []

    def get_schedules_sync_delta(
        self, uid, password, course_id, student_id, cursor
    ):
        assert (uid, course_id, student_id, cursor) == (8, 12, 21, "old-cursor")
        return {
            "schedules": [
                {
                    "id": 31,
                    "name": "Math",
                    "status": "active",
                    "tanggal_mulai": "",
                    "tanggal_selesai": "",
                    "durasi_menit": 45,
                    "jumlah_soal_ditampilkan": 10,
                },
            ],
            "removed_ids": [30],
            "cursor": "new-cursor",
        }

    def get_hasil_ujian(self, uid, password, student_id, jadwal_id=None):
        self.hasil_calls.append(jadwal_id)
        return [{"id": 50}] if jadwal_id == 31 else []


def test_delta_formats_changed_schedules_with_student_completion_and_removals():
    repo = SyncRepository()
    response = CbtService(repo).get_exam_list_sync(
        uid=8,
        password="pw",
        course_id=12,
        student_id=21,
        cursor="old-cursor",
    )

    assert response["is_full_sync"] is False
    assert response["cursor"] == "new-cursor"
    assert response["removed_ids"] == [30]
    assert response["exams"][0]["id"] == 31
    assert response["exams"][0]["status"] == "Selesai"
    assert repo.hasil_calls == [31]


def test_cursor_sync_fails_if_schedule_model_has_no_write_date():
    class OdooWithoutWriteDate:
        def execute_kw(self, **kwargs):
            assert kwargs["method"] == "fields_get"
            return {"id": {"type": "integer"}}

    repo = CbtRepository(OdooWithoutWriteDate())
    with pytest.raises(RuntimeError, match=r"cbt\.jadwal\.ujian\.write_date"):
        repo.get_schedules_sync_delta(
            uid=8,
            password="pw",
            course_id=12,
            student_id=21,
            cursor="old-cursor",
        )
