import sys
import os
import io
import subprocess
import tempfile
import logging
from typing import Dict, Any
from docxtpl import DocxTemplate

logger = logging.getLogger(__name__)

TEMPLATE_DOCX_PATH = os.path.join(
    os.path.dirname(__file__), "templates", "weekly_plan_template.docx"
)

def _get_libreoffice_cmd() -> str:
    """Mencari path eksekusi LibreOffice secara presisi di Windows / Linux."""
    if sys.platform.startswith("win"):
        # Jalur umum tempat LibreOffice terinstall di Windows
        possible_paths = [
            r"C:\Program Files\LibreOffice\program\soffice.exe",
            r"C:\Program Files (x86)\LibreOffice\program\soffice.exe",
            "soffice",
        ]
        for path in possible_paths:
            if os.path.exists(path):
                return path
        return "soffice"  # Gunakan perintah alias alias PATH Windows
    return "libreoffice"  # Untuk Linux / Ubuntu


def generate_weekly_plan_pdf(data: Dict[str, Any], jenjang: str = "SD") -> bytes:
    if not os.path.exists(TEMPLATE_DOCX_PATH):
        logger.error(f"[pdf_generator] File template tidak ditemukan di: {TEMPLATE_DOCX_PATH}")
        raise FileNotFoundError(f"Template Word tidak ditemukan di: {TEMPLATE_DOCX_PATH}")

    # 1. Siapkan data context
    context = dict(data)
    context['jenjang'] = jenjang.upper()

    # 2. Render data ke file Word
    doc = DocxTemplate(TEMPLATE_DOCX_PATH)
    doc.render(context)

    # 3. Simpan sementara dan konversi ke PDF via LibreOffice
    with tempfile.TemporaryDirectory() as temp_dir:
        docx_path = os.path.join(temp_dir, "weekly_plan_temp.docx")
        doc.save(docx_path)

        libreoffice_bin = _get_libreoffice_cmd()

        cmd = [
            libreoffice_bin, "--headless", "--convert-to", "pdf",
            docx_path, "--outdir", temp_dir
        ]

        # Di Windows, gunakan shell=True agar subprocess dapat menemukan variabel PATH 'soffice'
        use_shell = sys.platform.startswith("win")

        try:
            subprocess.run(
                cmd, 
                check=True, 
                stdout=subprocess.PIPE, 
                stderr=subprocess.PIPE,
                shell=use_shell
            )
        except Exception as e:
            logger.error(f"[pdf_generator] Gagal konversi Word ke PDF via LibreOffice ({libreoffice_bin}): {e}")
            raise RuntimeError("Gagal mengonversi dokumen Word ke PDF via LibreOffice.") from e

        pdf_path = os.path.join(temp_dir, "weekly_plan_temp.pdf")
        
        if not os.path.exists(pdf_path):
            raise FileNotFoundError(f"File PDF tidak berhasil dibuat di: {pdf_path}")

        with open(pdf_path, "rb") as f:
            pdf_bytes = f.read()

    return pdf_bytes