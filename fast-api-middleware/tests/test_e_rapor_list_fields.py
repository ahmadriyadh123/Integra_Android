from app.features.e_rapor.service import ERaporService


class _ReportRepository:
    def get_student_reports(self, uid, password, student_id, jenjang=None):
        return [
            {
                "id": 73,
                "student_id": [41, "Nama Siswa"],
                "jenis_rapor": "sts",
                "semester": "1",
                "header_data": {
                    "academic_year_id": [12, "2025/2026"],
                    "course_id": [8, "Kelas 1 SD"],
                },
            }
        ]


def test_report_list_exposes_requested_labels_and_display_values():
    reports = ERaporService(_ReportRepository()).get_student_reports(
        uid=17,
        password="secret",
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
            "rata_rata_nilai": 0.0,
            "catatan_wali_kelas": "",
            "status_keputusan": "",
            "file_rapor_pdf": "/e-rapor/pdf/73",
            "file_name": "Rapor_Semester_1.pdf",
        }
    ]
