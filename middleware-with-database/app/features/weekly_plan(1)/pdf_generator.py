"""
Generator PDF Weekly Plan SD menggunakan ReportLab.

Format output:
  - Header sekolah (nama, alamat)
  - Judul WEEKLY PLAN SD
  - Info: Pekan, Kelas, Tahun Ajaran, Semester
  - Tabel Tema Pembelajaran
  - Tabel Tujuan Pembelajaran (Mata Pelajaran | Tujuan)
  - Tabel kegiatan per hari: Senin–Jumat
    (Waktu | Aktivitas Pembelajaran | Media | Sumber Belajar | Penilaian)
"""

import io
from typing import Dict, Any, List

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
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
    """
    Terima dict hasil WeeklyPlanService.get_weekly_plan_detail()
    dan kembalikan bytes PDF.
    """
    # ReportLab menyusun seluruh elemen dokumen sebelum hasilnya dikembalikan.
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

    story.append(Paragraph(data.get('nama_sekolah', 'ERP Integra Edusolusi'), s['school']))
    story.append(Paragraph('WEEKLY PLAN SD', s['title']))
    story.append(Paragraph(data.get('alamat_sekolah', ''), s['subtitle']))
    story.append(HRFlowable(
        width='100%', thickness=1.5,
        color=COLOR_GREEN, spaceAfter=4
    ))

    story.append(_info_table(data, s))
    story.append(Spacer(1, 4 * mm))

    story.append(_section_header('TEMA PEMBELAJARAN', s))
    story.append(_tema_table(data.get('tema', '-'), s))
    story.append(Spacer(1, 4 * mm))

    story.append(_section_header('TUJUAN PEMBELAJARAN', s))
    story.append(_tp_table(data.get('tujuan_pembelajaran', []), s))
    story.append(Spacer(1, 4 * mm))

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

    story.append(Spacer(1, 6 * mm))
    usable = PAGE_W - 2 * MARGIN
    sign_rows = [[
        Paragraph('Mengetahui,<br/>Kepala Sekolah', s['cell_center']),
        Paragraph('', s['cell']),
        Paragraph('Guru Kelas', s['cell_center']),
    ]]
    sign_rows.append([Paragraph('<br/><br/><br/>', s['cell']), '', ''])
    sign_rows.append([
        Paragraph(f"<b>{data.get('nama_kepsek', '.....................')}</b>", s['cell_center']),
        Paragraph('', s['cell']),
        Paragraph(f"<b>{data.get('nama_guru', '.....................')}</b>", s['cell_center']),
    ])
    sign_table = Table(
        sign_rows,
        colWidths=[usable * 0.35, usable * 0.30, usable * 0.35]
    )
    sign_table.setStyle(TableStyle([
        ('ALIGN',         (0, 0), (-1, -1), 'CENTER'),
        ('VALIGN',        (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING',    (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('LINEBELOW',     (0, 2), (0, 2), 0.5, COLOR_SLATE),
        ('LINEBELOW',     (2, 2), (2, 2), 0.5, COLOR_SLATE),
    ]))
    story.append(sign_table)

    doc.build(story)
    return buffer.getvalue()
