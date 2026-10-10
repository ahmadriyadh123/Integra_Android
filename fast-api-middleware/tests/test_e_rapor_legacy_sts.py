from app.features.e_rapor.repository import ERaporRepository
from app.features.e_rapor.service import ERaporService


class _OdooClient:
    def __init__(self):
        self.calls = []

    def execute_kw(self, uid, password, model, method, args, kwargs):
        assert method == "fields_get"
        if model == "raport.siswa.sts":
            return {
                "id": {"type": "integer"},
                "student_id": {"type": "many2one"},
                "kelas_id": {"type": "many2one"},
                "tahun_pelajaran": {"type": "many2one"},
                "semester_id": {
                    "type": "selection",
                    "selection": [("1", "Gasal"), ("2", "Genap")],
                },
                "jenis_raport": {
                    "type": "selection",
                    "selection": [("sts", "Sumatif Tengah Semester")],
                },
                "fase": {"type": "selection", "selection": [("B", "Fase B")]},
                "active": {"type": "boolean"},
                "raport_siswa_ids": {"type": "one2many"},
                "mulok_siswa_ids": {"type": "one2many"},
            }
        if model in {"raport.siswa.line", "raport.siswa.mulok"}:
            return {
                "id": {"type": "integer"},
                "raport_id": {"type": "many2one"},
                "subject_id": {"type": "many2one"},
                "nilai_akhir": {"type": "float"},
                "note": {"type": "char"},
                "note2": {"type": "text"},
            }
        raise AssertionError(f"Unexpected metadata model: {model}")

    def search_read(self, **kwargs):
        self.calls.append(kwargs)
        model = kwargs["model"]
        if model == "raport.siswa.sts":
            report_id = next(
                (value for field, operator, value in kwargs["domain"] if field == "id"),
                91,
            )
            if kwargs["domain"][-1] == ("student_id", "=", 41) or (
                ("student_id", "=", 41) in kwargs["domain"]
            ):
                return [{
                    "id": report_id,
                    "student_id": [41, "Siswa SD"],
                    "kelas_id": [8, "Kelas 1 SD"],
                    "tahun_pelajaran": [12, "2025/2026"],
                    "semester_id": "1",
                    "jenis_raport": "sts",
                    "fase": "B",
                }]
            return []
        if model == "raport.siswa.line":
            return [{
                "id": 101,
                "subject_id": [7, "Bahasa Indonesia"],
                "nilai_akhir": 88.0,
                "note": "B",
                "note2": "Baik",
            }]
        if model == "raport.siswa.mulok":
            return [{
                "id": 102,
                "subject_id": [9, "Bahasa Sunda"],
                "nilai_akhir": 90.0,
                "note": "A",
                "note2": "Sangat baik",
            }]
        raise AssertionError(f"Unexpected search model: {model}")


def test_report_list_reads_sts_records_scoped_to_authenticated_student():
    odoo = _OdooClient()
    reports = ERaporRepository(odoo).get_student_reports(
        uid=17,
        password="password",
        student_id=41,
        jenjang="sd",
    )

    assert reports[0]["id"] == 91
    assert reports[0]["jenis_rapor_label"] == "Sumatif Tengah Semester"
    assert reports[0]["semester_label"] == "Gasal"
    report_query = next(call for call in odoo.calls if call["model"] == "raport.siswa.sts")
    assert ("student_id", "=", 41) in report_query["domain"]
    assert report_query["domain"][-1] == ("active", "=", True)


def test_report_details_read_sts_and_related_grade_lines():
    odoo = _OdooClient()
    report = ERaporRepository(odoo).get_report_card_details(
        uid=17,
        password="password",
        rapor_id=91,
        student_id=41,
        jenjang="sd",
    )

    assert report["student_id"] == [41, "Siswa SD"]
    assert report["semester"] == "Gasal"
    assert report["fase"] == "Fase B"
    assert report["subjects"][0]["nilai_akhir"] == 88.0
    assert report["muatan_lokal"][0]["subject_id"] == [9, "Bahasa Sunda"]
    report_query = next(call for call in odoo.calls if call["model"] == "raport.siswa.sts")
    assert ("id", "=", 91) in report_query["domain"]
    assert ("student_id", "=", 41) in report_query["domain"]
    assert any(
        call["model"] == "raport.siswa.line"
        and call["domain"] == [("raport_id", "=", 91)]
        for call in odoo.calls
    )


def test_report_detail_maps_sts_grade_and_mulok_lines(monkeypatch):
    monkeypatch.setattr(
        "app.features.e_rapor.service.ProfileRepository.get_student_profile_record",
        lambda *args, **kwargs: {},
    )
    service = ERaporService(ERaporRepository(_OdooClient()))

    detail = service.get_report_detail(
        uid=17,
        password="password",
        rapor_id=91,
        student_id=41,
        jenjang="sd",
    )

    assert detail["kelas"] == "Kelas 1 SD"
    assert detail["tahun_ajaran"] == "2025/2026"
    assert detail["semester"] == "Gasal"
    assert detail["fase"] == "Fase B"
    assert detail["subjects"][0]["subject_name"] == "Bahasa Indonesia"
    assert detail["subjects"][0]["nilai_akhir"] == "88"
    assert detail["muatan_lokal"][0]["subject_name"] == "Bahasa Sunda"
    assert detail["muatan_lokal"][0]["nilai_akhir"] == "90"
