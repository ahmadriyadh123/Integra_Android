import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict

from docxtpl import DocxTemplate


class ERaporPdfGenerator:
    """Render e-rapor data into PDF without mixing document concerns into the service."""

    def __init__(self, template_path: str | Path | None = None):
        self.template_path = Path(
            template_path
            or Path(__file__).parent / "templates" / "rapor_template.docx"
        )

    @staticmethod
    def _get_libreoffice_cmd() -> str:
        if sys.platform.startswith("win"):
            possible_paths = [
                r"C:\Program Files\LibreOffice\program\soffice.exe",
                r"C:\Program Files (x86)\LibreOffice\program\soffice.exe",
                "soffice",
            ]
            for path in possible_paths:
                if os.path.exists(path):
                    return path
            return "soffice"
        return "libreoffice"

    def generate(self, context_data: Dict[str, Any]) -> bytes:
        if not self.template_path.is_file():
            raise FileNotFoundError(
                f"Template Word tidak ditemukan di: {self.template_path}"
            )

        document = DocxTemplate(str(self.template_path))
        document.render(context_data)

        with tempfile.TemporaryDirectory() as temp_dir:
            docx_path = Path(temp_dir) / "rapor_output.docx"
            pdf_path = Path(temp_dir) / "rapor_output.pdf"
            document.save(str(docx_path))

            subprocess.run(
                [
                    self._get_libreoffice_cmd(),
                    "--headless",
                    "--convert-to",
                    "pdf",
                    "--outdir",
                    temp_dir,
                    str(docx_path),
                ],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                shell=False,
            )
            return pdf_path.read_bytes()
