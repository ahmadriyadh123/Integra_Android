import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Any, Dict

from docxtpl import DocxTemplate


TEMPLATE_PATH = (
    Path(__file__).resolve().parent / "templates" / "weekly_plan_template.docx"
)

_INDONESIAN_MONTHS = (
    "Januari",
    "Februari",
    "Maret",
    "April",
    "Mei",
    "Juni",
    "Juli",
    "Agustus",
    "September",
    "Oktober",
    "November",
    "Desember",
)
_WEEKDAYS = (
    ("senin", "Senin"),
    ("selasa", "Selasa"),
    ("rabu", "Rabu"),
    ("kamis", "Kamis"),
    ("jumat", "Jumat"),
)


def _get_libreoffice_cmd() -> str:
    if sys.platform.startswith("win"):
        for candidate in (
            r"C:\Program Files\LibreOffice\program\soffice.exe",
            r"C:\Program Files (x86)\LibreOffice\program\soffice.exe",
        ):
            if Path(candidate).is_file():
                return candidate
    command = shutil.which("soffice") or shutil.which("libreoffice")
    if command:
        return command
    raise FileNotFoundError(
        "LibreOffice tidak ditemukan. Pasang LibreOffice untuk membuat PDF Weekly Plan."
    )


def _format_indonesian_date(value: datetime) -> str:
    return f"{value.day} {_INDONESIAN_MONTHS[value.month - 1]} {value.year}"


def _template_context(data: Dict[str, Any]) -> Dict[str, Any]:
    context = dict(data)
    context["jenjang"] = str(data.get("jenjang") or "SD").upper()
    context["write_date"] = data.get("write_date") or _format_indonesian_date(
        datetime.now()
    )
    context["tujuan_pembelajaran"] = data.get("tujuan_pembelajaran") or []
    for key, label in _WEEKDAYS:
        context[key] = label
        context[f"{key}_lines"] = data.get(key) or []
    return context


def generate_weekly_plan_pdf(data: Dict[str, Any]) -> bytes:
    if not TEMPLATE_PATH.is_file():
        raise FileNotFoundError(f"Template Word tidak ditemukan di: {TEMPLATE_PATH}")

    document = DocxTemplate(str(TEMPLATE_PATH))
    document.render(_template_context(data))

    with tempfile.TemporaryDirectory() as temp_dir:
        output_dir = Path(temp_dir)
        docx_path = output_dir / "weekly_plan_output.docx"
        document.save(str(docx_path))

        command = [
            _get_libreoffice_cmd(),
            "--headless",
            f"-env:UserInstallation={(output_dir / 'libreoffice-profile').as_uri()}",
            "--convert-to",
            "pdf",
            "--outdir",
            str(output_dir),
            str(docx_path),
        ]
        subprocess.run(
            command,
            check=True,
            capture_output=True,
            timeout=60,
        )

        pdf_path = output_dir / "weekly_plan_output.pdf"
        if not pdf_path.is_file():
            raise RuntimeError("LibreOffice tidak menghasilkan PDF Weekly Plan.")
        pdf_bytes = pdf_path.read_bytes()
        if not pdf_bytes.startswith(b"%PDF"):
            raise RuntimeError("Hasil konversi Weekly Plan bukan dokumen PDF yang valid.")
        return pdf_bytes
