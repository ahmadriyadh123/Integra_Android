from app.features.e_rapor.repository import ERaporRepository
from app.features.e_rapor.service import ERaporService


class _OdooClient:
    def execute_kw(self, uid, password, model, method, args, kwargs):
        assert method == "fields_get"
        if model == "op.student":
            return {
                "id": {},
                "gr_no": {},
                "nisn_no": {},
                "course_id": {},
            }
        if model == "op.course":
            return {"fase_id": {}}
        raise AssertionError(f"Unexpected metadata model: {model}")

    def search_read(self, **kwargs):
        if kwargs["model"] == "op.student":
            return [
                {
                    "gr_no": "NIS-001",
                    "nisn_no": "0098765432",
                    "course_id": [5, "Kelas 4"],
                }
            ]
        if kwargs["model"] == "op.course":
            return [{"fase_id": [2, "Fase B"]}]
        raise AssertionError(f"Unexpected search model: {kwargs['model']}")


class _ReportRepository(ERaporRepository):
    def get_report_card_details(
        self, uid, password, rapor_id, student_id, jenjang=None
    ):
        return {
            "id": rapor_id,
            "student_id": [student_id, "Nama Siswa"],
            "semester": "1",
            "header_data": {
                "course_id": [5, "Kelas 4"],
                "academic_year_id": [11, "2025/2026"],
            },
            "subjects": [],
        }


def test_report_detail_fills_student_class_year_and_phase_fields():
    service = ERaporService(_ReportRepository(_OdooClient()))

    detail = service.get_report_detail(
        uid=17,
        password="secret",
        rapor_id=23,
        student_id=41,
        jenjang="sd",
    )

    assert detail["nis_nisn"] == "NIS-001 / 0098765432"
    assert detail["tahun_ajaran"] == "2025/2026"
    assert detail["kelas"] == "Kelas 4"
    assert detail["fase"] == "Fase B"
