from datetime import datetime
from pathlib import Path
from unittest.mock import AsyncMock

import pytest

from app.features.e_rapor.repository import ERaporRepository
from app.features.e_rapor.service import ERaporService


class _Result:
    def __init__(self, rows=None, row=None):
        self.rows = rows or []
        self.row = row

    def mappings(self):
        return self

    def all(self):
        return self.rows

    def first(self):
        return self.row


class _ReportRepository:
    async def get_student_reports(self, student_id, jenjang=None):
        assert student_id == 41
        assert jenjang == "sd"
        return [
            {
                "id": 73,
                "student_id": 41,
                "student_name": "Nama Siswa",
                "jenis_rapor": "sts",
                "kelas": "Kelas 1 SD",
                "semester": "1",
                "tahun_ajaran": "2025/2026",
                "rata_rata_nilai": 88,
                "catatan_wali_kelas": None,
                "status_keputusan": "naik",
                "file_name": None,
            }
        ]

    async def get_student_reports_sync(self, student_id, jenjang, cursor):
        assert jenjang == "sd"
        assert cursor == "2026-10-11T09:00:00Z"
        return {
            "items": [
                {
                    "id": 73,
                    "student_id": student_id,
                    "student_name": "Nama Siswa",
                    "jenis_rapor": "sts",
                    "kelas": "Kelas 1 SD",
                    "semester": "1",
                    "tahun_ajaran": "2025/2026",
                    "rata_rata_nilai": 88,
                }
            ],
            "removed_ids": [81],
            "next_cursor": "2026-10-11T10:00:00+00:00",
            "full_sync": False,
        }


@pytest.mark.asyncio
async def test_erapor_list_maps_legacy_selection_values_to_display_labels():
    reports = await ERaporService(_ReportRepository()).get_student_reports(
        student_id=41,
        jenjang="sd",
    )

    assert reports == [
        {
            "id": 73,
            "student_id": 41,
            "student_name": "Nama Siswa",
            "jenis_rapor": "Sumatif Tengah Semester",
            "kelas": "Kelas 1 SD",
            "semester": "Gasal",
            "tahun_ajaran": "2025/2026",
            "rata_rata_nilai": 88.0,
            "catatan_wali_kelas": "",
            "status_keputusan": "naik",
            "file_rapor_pdf": "/e-rapor/pdf/73",
            "file_name": "Rapor_73.pdf",
        }
    ]


@pytest.mark.asyncio
async def test_erapor_sync_preserves_delta_metadata_and_item_format():
    result = await ERaporService(_ReportRepository()).sync_student_reports(
        student_id=41,
        jenjang="sd",
        cursor="2026-10-11T09:00:00Z",
    )

    assert result["full_sync"] is False
    assert result["removed_ids"] == [81]
    assert result["items"][0]["semester"] == "Gasal"
    assert result["next_cursor"] == "2026-10-11T10:00:00+00:00"


@pytest.mark.asyncio
async def test_erapor_pdf_fallback_renders_word_template_with_report_context(monkeypatch):
    class _DetailRepository(_ReportRepository):
        async def get_report_card_details(self, rapor_id, student_id, jenjang=None):
            assert (rapor_id, student_id, jenjang) == (73, 41, "sd")
            return {
                "id": 73,
                "student_id": 41,
                "student_name": "Nama Siswa",
                "jenis_rapor": "sts",
                "kelas": "Kelas 1 SD",
                "semester": "1",
                "tahun_ajaran": "2025/2026",
                "subjects": [
                    {
                        "id": 100,
                        "subject_id": 3,
                        "subject_name": "Matematika",
                        "nilai_pengetahuan": 88,
                        "nilai_keterampilan": 90,
                        "predikat": "B",
                    }
                ],
                "muatan_lokal": [],
                "attachment_id": None,
            }

        async def get_student_identity(self, student_id):
            assert student_id == 41
            return {"nis": "NIS-1", "nisn": "NISN-1"}

    class _NoAttachmentRepository(_DetailRepository):
        async def attachment_bytes(self, rapor_id, student_id, jenjang=None):
            assert (rapor_id, student_id, jenjang) == (73, 41, "sd")
            return None

    service = ERaporService(_NoAttachmentRepository())
    generated_context = {}

    class _WordTemplate:
        def __init__(self, template_path):
            assert template_path.endswith("rapor_template.docx")

        def render(self, context):
            generated_context.update(context)

        def save(self, output_path):
            Path(output_path).write_bytes(b"docx")

    def convert_to_pdf(command, **kwargs):
        assert "--headless" in command
        assert command[command.index("--convert-to") + 1] == "pdf"
        output_dir = Path(command[command.index("--outdir") + 1])
        (output_dir / "rapor_output.pdf").write_bytes(b"%PDF-test")

    monkeypatch.setattr("app.features.e_rapor.service.DocxTemplate", _WordTemplate)
    monkeypatch.setattr(
        "app.features.e_rapor.service.subprocess.run", convert_to_pdf
    )
    monkeypatch.setattr(service, "_get_libreoffice_cmd", lambda: "soffice")
    content, filename = await service.get_rapor_pdf_bytes(73, 41, "sd")

    assert filename == "E-Rapor_Nama_Siswa_ID73.pdf"
    assert content == b"%PDF-test"
    assert generated_context["nis_nisn"] == "NIS-1 / NISN-1"
    assert generated_context["subjects"][0]["no"] == 1
    assert generated_context["subjects"][0]["subject_name"] == "Matematika"


@pytest.mark.asyncio
async def test_erapor_delta_uses_student_scope_and_includes_child_changes():
    db = AsyncMock()
    db.execute.side_effect = [
        _Result(row={"table_name": "raport_siswa_sts"}),
        _Result(row={"has_reports": True}),
        _Result(rows=[{"column_name": "id"}, {"column_name": "student_id"}, {"column_name": "write_date"}]),
        _Result(rows=[{"id": 73}]),
        _Result(row={"table_name": "raport_siswa_line"}),
        _Result(rows=[
            {"column_name": "id"},
            {"column_name": "raport_id"},
            {"column_name": "write_date"},
        ]),
        _Result(rows=[{"report_id": 73}]),
        _Result(row=None),
        _Result(row={"table_name": "raport_siswa_sts"}),
        _Result(row={"has_reports": True}),
        _Result(rows=[
            {"column_name": column}
            for column in (
                "id",
                "student_id",
                "write_date",
                "semester_id",
                "jenis_raport",
                "kelas_id",
                "tahun_pelajaran",
                "active",
            )
        ]),
        _Result(rows=[
            {
                "id": 73,
                "student_id": 41,
                "student_name": "Nama Siswa",
                "kelas": "Kelas 1 SD",
                "tahun_ajaran": "2025/2026",
                "semester": "1",
                "jenis_rapor": "sts",
                "rata_rata_nilai": 88,
                "catatan_wali_kelas": None,
                "status_keputusan": None,
                "attachment_id": None,
                "file_name": None,
                "file_url": None,
            }
        ]),
    ]
    repository = ERaporRepository(db)

    sync = await repository.get_student_reports_sync(
        student_id=41,
        jenjang="sd",
        cursor="2026-10-09T11:00:00Z",
    )

    assert sync["full_sync"] is False
    assert sync["items"][0]["id"] == 73
    assert sync["removed_ids"] == []
    assert db.execute.await_args_list[6].args[1]["since"] == datetime(
        2026, 10, 9, 10, 58
    )
    assert "report.student_id = :student_id" in str(
        db.execute.await_args_list[6].args[0]
    )


@pytest.mark.asyncio
async def test_erapor_uses_ledger_when_legacy_has_no_student_reports():
    db = AsyncMock()
    db.execute.side_effect = [
        _Result(row={"table_name": "raport_siswa_sts"}),
        _Result(row={"has_reports": False}),
        _Result(row={"table_name": "ledger_rapor_sd"}),
        _Result(row={"table_name": "ledger_rapor_sd_lm1"}),
        _Result(row={"has_reports": True}),
    ]

    source, config = await ERaporRepository(db)._report_source("sd", 41)

    assert source == "ledger"
    assert config["report"] == "ledger_rapor_sd"


@pytest.mark.asyncio
async def test_erapor_prefers_legacy_when_student_has_legacy_reports():
    db = AsyncMock()
    db.execute.side_effect = [
        _Result(row={"table_name": "raport_siswa_sts"}),
        _Result(row={"has_reports": True}),
    ]

    source, config = await ERaporRepository(db)._report_source("sd", 41)

    assert source == "legacy"
    assert config["report"] == "raport_siswa_sts"


@pytest.mark.asyncio
async def test_legacy_report_detail_supports_text_teacher_reference():
    db = AsyncMock()
    db.execute.return_value = _Result(
        row={
            "tanggal_pengesahan": None,
            "nama_sekolah": None,
            "alamat_sekolah": None,
            "wali_kelas": "Wali Kelas",
        }
    )
    repository = ERaporRepository(db)
    repository._get_legacy_reports = AsyncMock(
        return_value=[{"id": 8, "student_id": 121}]
    )
    repository._columns = AsyncMock(
        return_value={"id", "student_id", "walas"}
    )
    repository._get_legacy_grade_lines = AsyncMock(return_value=[])

    detail = await repository._legacy_report_detail(8, 121, "sd")

    query = str(db.execute.await_args.args[0])
    assert "teacher.id::text = r.walas::text" in query
    assert "NULLIF(r.walas::text, '')" in query
    assert detail["wali_kelas"] == "Wali Kelas"


def test_erapor_rejects_unsupported_school_level():
    with pytest.raises(ValueError, match="sd, smp, atau tk"):
        ERaporRepository.normalize_level("sma")
