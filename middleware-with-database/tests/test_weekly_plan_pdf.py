from pathlib import Path

from app.features.weekly_plan import pdf_generator


def test_weekly_plan_pdf_renders_word_template_and_converts_to_pdf(monkeypatch):
    rendered_context = {}
    saved_docx = {}

    class _WordTemplate:
        def __init__(self, template_path):
            assert Path(template_path).name == "weekly_plan_template.docx"
            assert Path(template_path).is_file()

        def render(self, context):
            rendered_context.update(context)

        def save(self, output_path):
            saved_docx["path"] = output_path
            Path(output_path).write_bytes(b"docx")

    def _convert_to_pdf(command, **kwargs):
        assert "--headless" in command
        assert command[command.index("--convert-to") + 1] == "pdf"
        assert Path(saved_docx["path"]).name == "weekly_plan_output.docx"
        output_dir = Path(command[command.index("--outdir") + 1])
        (output_dir / "weekly_plan_output.pdf").write_bytes(b"%PDF-test")

    monkeypatch.setattr(pdf_generator, "DocxTemplate", _WordTemplate)
    monkeypatch.setattr(pdf_generator, "_get_libreoffice_cmd", lambda: "soffice")
    monkeypatch.setattr(pdf_generator.subprocess, "run", _convert_to_pdf)

    pdf_bytes = pdf_generator.generate_weekly_plan_pdf(
        {
            "jenjang": "smp",
            "kelas": "Kelas 7",
            "pekan": "Pekan 1",
            "tujuan_pembelajaran": [{"subject_name": "IPA", "tp": "Mengamati"}],
            "senin": [{"waktu": "08.00", "aktivitas": "Diskusi"}],
        }
    )

    assert pdf_bytes == b"%PDF-test"
    assert rendered_context["jenjang"] == "SMP"
    assert rendered_context["senin"] == "Senin"
    assert rendered_context["senin_lines"] == [
        {"waktu": "08.00", "aktivitas": "Diskusi"}
    ]
    assert rendered_context["selasa_lines"] == []
    assert rendered_context["tujuan_pembelajaran"][0]["subject_name"] == "IPA"
    assert rendered_context["write_date"]
