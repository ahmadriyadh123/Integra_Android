import io
import base64
from typing import Dict, Any, List, Optional

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable, Image
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT


COLOR_GREEN       = colors.HexColor('#059669')
COLOR_GREEN_LIGHT = colors.HexColor('#D1FAE5')
COLOR_GREEN_DARK  = colors.HexColor('#065F46')
COLOR_SLATE       = colors.HexColor('#334155')
COLOR_MUTED       = colors.HexColor('#94A3B8')
COLOR_BORDER      = colors.HexColor('#CBD5E1')
COLOR_WHITE       = colors.white
COLOR_HEADER_BG   = colors.HexColor('#ECFDF5')

PAGE_W, PAGE_H = A4
MARGIN = 15 * mm


def _styles() -> dict:
    # Semua elemen PDF memakai style terpusat agar formatnya konsisten.
    base = getSampleStyleSheet()
    return {
        'school': ParagraphStyle('school',
            fontSize=9, textColor=COLOR_SLATE, alignment=TA_CENTER,
            fontName='Helvetica'),
        'title': ParagraphStyle('title',
            fontSize=14, textColor=COLOR_GREEN_DARK, alignment=TA_CENTER,
            fontName='Helvetica-Bold', spaceAfter=2),
        'subtitle': ParagraphStyle('subtitle',
            fontSize=8, textColor=COLOR_MUTED, alignment=TA_CENTER,
            fontName='Helvetica'),
        'section': ParagraphStyle('section',
            fontSize=9, textColor=COLOR_GREEN_DARK, alignment=TA_CENTER,
            fontName='Helvetica-Bold'),
        'day_header': ParagraphStyle('day_header',
            fontSize=9, textColor=COLOR_WHITE, alignment=TA_LEFT,
            fontName='Helvetica-Bold'),
        'cell': ParagraphStyle('cell',
            fontSize=8, textColor=COLOR_SLATE, alignment=TA_LEFT,
            fontName='Helvetica', leading=11),
        'cell_center': ParagraphStyle('cell_center',
            fontSize=8, textColor=COLOR_SLATE, alignment=TA_CENTER,
            fontName='Helvetica', leading=11),
    }

def _base64_to_reportlab_image(base64_str: Optional[str], width: float, height: float) -> Optional[Image]:
    """Helper untuk mengonversi String Base64 menjadi objek Image ReportLab."""
    if not base64_str or base64_str == '-':
        return None
    try:
        clean_b64 = base64_str.split(',')[-1] if ',' in base64_str else base64_str
        image_bytes = base64.b64decode(clean_b64)
        img_buffer = io.BytesIO(image_bytes)
        img = Image(img_buffer, width=width, height=height)
        return img
    except Exception:
        return None

def _info_table(data: Dict[str, Any], styles: dict) -> Table:
    """Tabel 2 kolom: Pekan | Kelas dan Tahun Ajaran | Semester."""
    s = styles['cell']
    rows = [
        [
            Paragraph(f"<b>Pekan</b> : {data.get('pekan', '-')}", s),
            Paragraph(f"<b>Kelas</b> : {data.get('kelas', '-')}", s),
        ],
        [
            Paragraph(f"<b>Tahun Ajaran</b> : {data.get('tahun_ajaran', '-')}", s),
            Paragraph(f"<b>Semester</b> : {data.get('semester', '-')}", s),
        ],
    ]
    usable = PAGE_W - 2 * MARGIN
    t = Table(rows, colWidths=[usable / 2, usable / 2])
    t.setStyle(TableStyle([
        ('BOX',        (0, 0), (-1, -1), 0.5, COLOR_BORDER),
        ('INNERGRID',  (0, 0), (-1, -1), 0.5, COLOR_BORDER),
        ('BACKGROUND', (0, 0), (-1, -1), COLOR_HEADER_BG),
        ('TOPPADDING',    (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING',   (0, 0), (-1, -1), 6),
    ]))
    return t


def _section_header(text: str, styles: dict) -> Table:
    """Bar hijau sebagai judul seksi."""
    t = Table(
        [[Paragraph(text, styles['section'])]],
        colWidths=[PAGE_W - 2 * MARGIN]
    )
    t.setStyle(TableStyle([
        ('BACKGROUND',    (0, 0), (-1, -1), COLOR_GREEN),
        ('TOPPADDING',    (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('TEXTCOLOR',     (0, 0), (-1, -1), COLOR_WHITE),
    ]))
    return t


def _tema_table(tema: str, styles: dict) -> Table:
    usable = PAGE_W - 2 * MARGIN
    t = Table(
        [[Paragraph(tema or '-', styles['cell'])]],
        colWidths=[usable]
    )
    t.setStyle(TableStyle([
        ('BOX',           (0, 0), (-1, -1), 0.5, COLOR_BORDER),
        ('TOPPADDING',    (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING',   (0, 0), (-1, -1), 6),
    ]))
    return t


def _tp_table(tp_lines: List[Dict[str, Any]], styles: dict) -> Table:
    """Tabel Tujuan Pembelajaran: Mata Pelajaran | Tujuan Pembelajaran."""
    usable = PAGE_W - 2 * MARGIN
    col_w = [usable * 0.28, usable * 0.72]

    header = [
        Paragraph('<b>Mata Pelajaran</b>', styles['cell_center']),
        Paragraph('<b>Tujuan Pembelajaran</b>', styles['cell_center']),
    ]
    rows = [header]

    if tp_lines:
        for tp in tp_lines:
            rows.append([
                Paragraph(tp.get('subject_name', '-'), styles['cell']),
                Paragraph(tp.get('tp', '-'), styles['cell']),
            ])
    else:
        rows.append([Paragraph('-', styles['cell']), Paragraph('-', styles['cell'])])

    t = Table(rows, colWidths=col_w, repeatRows=1)
    t.setStyle(TableStyle([
        ('BOX',           (0, 0), (-1, -1), 0.5, COLOR_BORDER),
        ('INNERGRID',     (0, 0), (-1, -1), 0.5, COLOR_BORDER),
        ('BACKGROUND',    (0, 0), (1, 0),   COLOR_GREEN_LIGHT),
        ('TOPPADDING',    (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING',   (0, 0), (-1, -1), 5),
        ('VALIGN',        (0, 0), (-1, -1), 'TOP'),
    ]))
    return t


def _day_table(
    day_label: str,
    lines: List[Dict[str, Any]],
    styles: dict
) -> List:
    """Header hari + tabel kegiatan (Waktu | Aktivitas | Media | Sumber | Penilaian)."""
    # Lebar kolom dijaga tetap agar tabel harian tidak berubah antar halaman.
    usable = PAGE_W - 2 * MARGIN
    col_w = [
        usable * 0.14,   # Waktu
        usable * 0.32,   # Aktivitas Pembelajaran
        usable * 0.18,   # Media
        usable * 0.18,   # Sumber Belajar
        usable * 0.18,   # Penilaian
    ]

    day_bar = Table(
        [[Paragraph(day_label, styles['day_header'])]],
        colWidths=[usable]
    )
    day_bar.setStyle(TableStyle([
        ('BACKGROUND',    (0, 0), (-1, -1), COLOR_GREEN),
        ('TOPPADDING',    (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING',   (0, 0), (-1, -1), 6),
    ]))

    col_headers = [
        Paragraph('<b>Waktu</b>',                 styles['cell_center']),
        Paragraph('<b>Aktivitas Pembelajaran</b>', styles['cell_center']),
        Paragraph('<b>Media</b>',                  styles['cell_center']),
        Paragraph('<b>Sumber Belajar</b>',         styles['cell_center']),
        Paragraph('<b>Penilaian</b>',              styles['cell_center']),
    ]
    rows = [col_headers]

    if lines:
        for line in lines:
            rows.append([
                Paragraph(line.get('waktu', '-'),      styles['cell_center']),
                Paragraph(line.get('aktivitas', '-'),  styles['cell']),
                Paragraph(line.get('media', '-'),      styles['cell']),
                Paragraph(line.get('sumber', '-'),     styles['cell']),
                Paragraph(line.get('penilaian', '-'),  styles['cell']),
            ])
    else:
        rows.append([
            Paragraph('-', styles['cell_center']),
            Paragraph('-', styles['cell']),
            Paragraph('-', styles['cell']),
            Paragraph('-', styles['cell']),
            Paragraph('-', styles['cell']),
        ])

    activity_table = Table(rows, colWidths=col_w, repeatRows=1)
    activity_table.setStyle(TableStyle([
        ('BOX',           (0, 0), (-1, -1), 0.5, COLOR_BORDER),
        ('INNERGRID',     (0, 0), (-1, -1), 0.5, COLOR_BORDER),
        ('BACKGROUND',    (0, 0), (-1, 0),  COLOR_GREEN_LIGHT),
        ('TOPPADDING',    (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING',   (0, 0), (-1, -1), 5),
        ('VALIGN',        (0, 0), (-1, -1), 'TOP'),
    ]))

    return [day_bar, activity_table]


def generate_weekly_plan_pdf(data: Dict[str, Any]) -> bytes:
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=MARGIN,
        rightMargin=MARGIN,
        topMargin=MARGIN,
        bottomMargin=MARGIN,
        title=f"Weekly Plan - {data.get('kelas', '')} - Pekan {data.get('pekan', '')}",
    )
    s = _styles()
    story = []

    usable = PAGE_W - 2 * MARGIN

    # ==================== 1. KOP HEADER (DENGAN LOGO) ====================
    logo_img = _base64_to_reportlab_image(data.get('logo_base64'), width=14*mm, height=14*mm)
    
    header_left = [
        Paragraph(data.get('nama_sekolah', 'ERP Integra Edusolusi'), s['school']),
        Paragraph(data.get('alamat_sekolah', 'Jl. Pena Kencana BSD'), s['subtitle']),
    ]
    
    if logo_img:
        header_table = Table(
            [[logo_img, header_left, Paragraph('WEEKLY PLAN SD', s['title'])]],
            colWidths=[16*mm, usable * 0.5, usable * 0.5 - 16*mm]
        )
    else:
        header_table = Table(
            [[header_left, Paragraph('WEEKLY PLAN SD', s['title'])]],
            colWidths=[usable * 0.55, usable * 0.45]
        )
        
    header_table.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('LEFTPADDING', (0, 0), (-1, -1), 0),
        ('RIGHTPADDING', (0, 0), (-1, -1), 0),
    ]))
    story.append(header_table)

    story.append(HRFlowable(
        width='100%', thickness=1.5,
        color=COLOR_GREEN, spaceAfter=4, spaceBefore=4
    ))

    # ==================== 2. INFO METADATA ====================
    story.append(_info_table(data, s))
    story.append(Spacer(1, 4 * mm))

    # ==================== 3. TEMA PEMBELAJARAN ====================
    story.append(_section_header('TEMA PEMBELAJARAN', s))
    story.append(_tema_table(data.get('tema', '-'), s))
    story.append(Spacer(1, 4 * mm))

    # ==================== 4. TUJUAN PEMBELAJARAN ====================
    story.append(_section_header('TUJUAN PEMBELAJARAN', s))
    story.append(_tp_table(data.get('tujuan_pembelajaran', []), s))
    story.append(Spacer(1, 4 * mm))

    # ==================== 5. RINCIAN HARIAN ====================
    days = [
        ('Senin',  'senin'),
        ('Selasa', 'selasa'),
        ('Rabu',   'rabu'),
        ('Kamis',  'kamis'),
        ('Jumat',  'jumat'),
    ]
    for label, key in days:
        for elem in _day_table(label, data.get(key, []), s):
            story.append(elem)
        story.append(Spacer(1, 3 * mm))

    story.append(Spacer(1, 4 * mm))

    # ==================== 6. TANDA TANGAN KEPSEK & GURU ====================
    ttd_kepsek_img = _base64_to_reportlab_image(data.get('ttd_kepsek_base64'), width=30*mm, height=15*mm)
    ttd_guru_img = _base64_to_reportlab_image(data.get('ttd_guru_base64'), width=30*mm, height=15*mm)

    sign_rows = [
        [
            Paragraph('Mengetahui,<br/>Kepala Sekolah', s['cell_center']),
            Paragraph('', s['cell']),
            Paragraph('Guru Kelas', s['cell_center']),
        ],
        [
            ttd_kepsek_img if ttd_kepsek_img else Paragraph('<br/><br/>', s['cell']),
            Paragraph('', s['cell']),
            ttd_guru_img if ttd_guru_img else Paragraph('<br/><br/>', s['cell']),
        ],
        [
            Paragraph(f"<b>{data.get('nama_kepsek', 'Kepala Sekolah')}</b>", s['cell_center']),
            Paragraph('', s['cell']),
            Paragraph(f"<b>{data.get('nama_guru', 'Guru Kelas')}</b>", s['cell_center']),
        ]
    ]

    sign_table = Table(
        sign_rows,
        colWidths=[usable * 0.35, usable * 0.30, usable * 0.35]
    )
    sign_table.setStyle(TableStyle([
        ('ALIGN',         (0, 0), (-1, -1), 'CENTER'),
        ('VALIGN',        (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING',    (0, 0), (-1, -1), 2),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
        ('LINEBELOW',     (0, 2), (0, 2), 0.5, COLOR_SLATE),
        ('LINEBELOW',     (2, 2), (2, 2), 0.5, COLOR_SLATE),
    ]))
    story.append(sign_table)

    doc.build(story)
    return buffer.getvalue()