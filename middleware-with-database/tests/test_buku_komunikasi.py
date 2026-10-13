from unittest.mock import AsyncMock

import pytest

from app.features.buku_komunikasi.repository import BukuKomunikasiRepository
from app.features.buku_komunikasi.service import BukuKomunikasiService


class _Result:
    def __init__(self, rows=None, row=None, scalar=None, rowcount=1):
        self.rows = rows or []
        self.row = row
        self.scalar = scalar
        self.rowcount = rowcount

    def mappings(self):
        return self

    def all(self):
        return self.rows

    def first(self):
        return self.row

    def scalar_one_or_none(self):
        return self.scalar


@pytest.mark.asyncio
async def test_buku_komunikasi_returns_header_status_and_ordered_line_data():
    db = AsyncMock()
    db.execute.side_effect = [
        _Result(
            row={
                "id": 5,
                "student_id": 41,
                "student_name": "Nama Siswa",
                "kelas_id": 3,
                "kelas_name": "Kelas 1",
                "tahun_id": 2,
                "tahun_name": "2026/2027",
                "status": "open",
            }
        ),
        _Result(
            rows=[
                {
                    "id": 9,
                    "pekan_ke": 2,
                    "bulan": "Oktober",
                    "senin": "Membaca",
                    "feedback_senin": "Bagus",
                    "selasa": None,
                    "feedback_selasa": None,
                    "rabu": None,
                    "feedback_rabu": None,
                    "kamis": None,
                    "feedback_kamis": None,
                    "jumat": None,
                    "feedback_jumat": None,
                }
            ]
        ),
    ]

    data = await BukuKomunikasiService(
        BukuKomunikasiRepository(db)
    ).get_buku_komunikasi(student_id=41, jenjang="sd")

    assert data["status"] == "open"
    assert data["lines"][0]["senin"] == "Membaca"
    assert data["lines"][0]["feedback_senin"] == "Bagus"
    assert data["lines"][0]["selasa"] == "-"
    assert db.execute.await_args_list[0].args[1] == {"student_id": 41}
    assert db.execute.await_args_list[1].args[1] == {"bukpeng_id": 5}


@pytest.mark.asyncio
async def test_daily_note_update_is_scoped_to_the_authenticated_student():
    db = AsyncMock()
    db.execute.return_value = _Result(rowcount=1)

    saved = await BukuKomunikasiRepository(db).update_daily_note(
        student_id=41,
        line_id=9,
        day="Senin",
        note_text="Membaca",
        jenjang="sd",
    )

    query = str(db.execute.await_args.args[0])
    assert saved is True
    assert "header.student_id = :student_id" in query
    assert "SET senin = :note_text" in query
    assert db.execute.await_args.args[1] == {
        "note_text": "Membaca",
        "line_id": 9,
        "student_id": 41,
    }
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_parent_feedback_update_uses_feedback_field_and_student_scope():
    db = AsyncMock()
    db.execute.return_value = _Result(rowcount=1)

    saved = await BukuKomunikasiRepository(db).update_parent_feedback(
        student_id=41,
        line_id=9,
        day="selasa",
        feedback_text="Terima kasih",
        jenjang="smp",
    )

    query = str(db.execute.await_args.args[0])
    assert saved is True
    assert "SET feedback_selasa = :feedback_text" in query
    assert "header.student_id = :student_id" in query
    assert "bukpeng_smp_line" in query
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_new_daily_note_is_inserted_only_for_students_own_book():
    db = AsyncMock()
    db.execute.return_value = _Result(scalar=17)

    saved = await BukuKomunikasiRepository(db).create_daily_note_line(
        student_id=41,
        pekan_ke=3,
        bulan="Oktober",
        day="rabu",
        note_text="Menggambar",
        jenjang="tk",
    )

    query = str(db.execute.await_args.args[0])
    assert saved is True
    assert "INSERT INTO bukpeng_tk_line" in query
    assert "bukpeng_tk_id" in query
    assert "WHERE header.student_id = :student_id" in query
    assert db.execute.await_args.args[1] == {
        "student_id": 41,
        "pekan_ke": 3,
        "bulan": "Oktober",
        "note_text": "Menggambar",
    }
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_unowned_line_updates_are_rejected_without_commit():
    db = AsyncMock()
    db.execute.return_value = _Result(rowcount=0)

    saved = await BukuKomunikasiRepository(db).update_parent_feedback(
        student_id=41,
        line_id=99,
        day="jumat",
        feedback_text="Catatan",
    )

    assert saved is False
    db.commit.assert_not_awaited()
    db.rollback.assert_awaited_once()


@pytest.mark.asyncio
async def test_service_creates_note_for_new_week_and_validates_inputs():
    repo = AsyncMock()
    repo.create_daily_note_line.return_value = True
    service = BukuKomunikasiService(repo)

    result = await service.save_daily_note(
        student_id=41,
        line_id=0,
        day="RABU",
        note_text="Catatan",
        month="Oktober",
        week=3,
    )

    assert result is True
    repo.create_daily_note_line.assert_awaited_once_with(
        student_id=41,
        pekan_ke=3,
        bulan="Oktober",
        day="rabu",
        note_text="Catatan",
        jenjang="sd",
    )
    with pytest.raises(ValueError, match="Hari"):
        await service.save_parent_feedback(
            student_id=41,
            line_id=9,
            day="minggu",
            feedback_text="Invalid",
        )
    with pytest.raises(ValueError, match="Bulan"):
        await service.save_daily_note(
            student_id=41,
            line_id=0,
            day="rabu",
            note_text="Catatan",
        )


@pytest.mark.asyncio
async def test_repository_rejects_unsafe_level_and_day_values():
    repository = BukuKomunikasiRepository(AsyncMock())

    with pytest.raises(ValueError, match="sd, smp, atau tk"):
        await repository.get_buku_catatan_header(41, "sd; DROP TABLE")
    with pytest.raises(ValueError, match="Hari tidak valid"):
        await repository.update_daily_note(
            student_id=41,
            line_id=9,
            day="senin; DROP TABLE",
            note_text="",
        )
