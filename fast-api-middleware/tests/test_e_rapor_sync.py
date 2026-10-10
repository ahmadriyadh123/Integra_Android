import pytest

from app.features.e_rapor.repository import ERaporRepository
from app.features.e_rapor.service import ERaporService


class _RaporOdoo:
    def __init__(self, missing_write_date=False):
        self.calls = []
        self.missing_write_date = missing_write_date

    def execute_kw(self, uid, password, model, method, args, kwargs):
        assert method == "fields_get"
        if model == "raport.siswa.sts":
            fields = {
                "id": {"type": "integer"},
                "student_id": {"type": "many2one", "relation": "op.student"},
                "active": {"type": "boolean"},
                "semester_id": {"type": "selection", "selection": [("1", "Gasal")]},
                "jenis_raport": {"type": "selection", "selection": [("sts", "STS")]},
                "kelas_id": {"type": "many2one", "relation": "op.course"},
                "tahun_pelajaran": {"type": "many2one"},
                "raport_siswa_ids": {
                    "type": "one2many",
                    "relation": "raport.siswa.line",
                    "relation_field": "raport_id",
                },
                "mulok_siswa_ids": {
                    "type": "one2many",
                    "relation": "raport.siswa.mulok",
                    "relation_field": "raport_id",
                },
            }
            if not self.missing_write_date:
                fields["write_date"] = {"type": "datetime"}
            return fields
        if model in {"raport.siswa.line", "raport.siswa.mulok"}:
            return {
                "id": {"type": "integer"},
                "raport_id": {
                    "type": "many2one",
                    "relation": "raport.siswa.sts",
                },
                "write_date": {"type": "datetime"},
            }
        raise AssertionError(model)

    def search_read(self, **kwargs):
        self.calls.append(kwargs)
        model = kwargs["model"]
        domain = kwargs["domain"]
        if model == "raport.siswa.sts":
            if ("write_date", ">=", "2026-10-09 10:58:00") in domain:
                return [{"id": 91}]
            if (
                ("id", "in", [91]) in domain
                or ("student_id", "=", 41) in domain
            ):
                return [{
                    "id": 91,
                    "student_id": [41, "Siswa"],
                    "kelas_id": [8, "Kelas 1"],
                    "tahun_pelajaran": [12, "2025/2026"],
                    "semester_id": "1",
                    "jenis_raport": "sts",
                    "nilai_rata_rata": 88,
                }]
            return []
        if model == "raport.siswa.line":
            return [{"id": 100, "raport_id": [91, "Rapor"]}]
        if model == "raport.siswa.mulok":
            return []
        raise AssertionError(model)


def test_erapor_cursor_includes_related_score_line_changes():
    odoo = _RaporOdoo()
    result = ERaporService(ERaporRepository(odoo)).sync_student_reports(
        uid=17,
        password="pw",
        student_id=41,
        jenjang="sd",
        cursor="2026-10-09T11:00:00Z",
    )

    assert result["full_sync"] is False
    assert result["items"][0]["id"] == 91
    assert result["items"][0]["rata_rata_nilai"] == 88
    assert result["removed_ids"] == []
    assert any(
        call["model"] == "raport.siswa.line"
        and call["domain"] == [("write_date", ">=", "2026-10-09 10:58:00")]
        for call in odoo.calls
    )


def test_erapor_initial_cursor_request_returns_full_reconciliation():
    result = ERaporRepository(_RaporOdoo()).get_student_reports_sync(
        uid=17,
        password="pw",
        student_id=41,
        jenjang="sd",
        cursor=None,
    )

    assert result["full_sync"] is True
    assert result["items"] == [
        {
            "id": 91,
            "student_id": [41, "Siswa"],
            "kelas_id": [8, "Kelas 1"],
            "tahun_pelajaran": [12, "2025/2026"],
            "semester_id": "1",
            "jenis_raport": "sts",
            "nilai_rata_rata": 88,
            "semester_label": "Gasal",
            "jenis_rapor_label": "STS",
            "fase_label": None,
            "header_data": {
                "course_id": [8, "Kelas 1"],
                "academic_year_id": [12, "2025/2026"],
                "write_date": None,
                "user_id": None,
            },
        }
    ]


def test_erapor_missing_header_write_date_fails_instead_of_claiming_delta():
    with pytest.raises(RuntimeError, match="write_date"):
        ERaporRepository(_RaporOdoo(missing_write_date=True)).get_student_reports_sync(
            uid=17,
            password="pw",
            student_id=41,
            jenjang="sd",
            cursor="2026-10-09T11:00:00Z",
        )
