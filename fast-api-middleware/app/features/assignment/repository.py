import base64
from datetime import datetime
from typing import List, Dict, Any
from app.core.odoo_client import OdooRPCClient

class AssignmentRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo_client = odoo_client

    def get_assignments_by_student(self, uid: int, password: str, student_id: int) -> List[Dict[str, Any]]:
        """
        Mengambil daftar penugasan siswa dari Odoo via RPC (op.assignment) berdasarkan batch_id.
        """
        # 1. Cari batch_id siswa dari model op.student
        batch_id = None
        if student_id:
            try:
                student_records = self.odoo_client.search_read(
                    uid=uid,
                    password=password,
                    model='op.student',
                    domain=[('id', '=', student_id)],
                    fields=['batch_id'],
                    limit=1,
                    use_sudo=True
                )
                if student_records:
                    val = student_records[0].get('batch_id')
                    if isinstance(val, (list, tuple)) and val:
                        batch_id = val[0]
                    elif isinstance(val, int):
                        batch_id = val
            except Exception:
                pass

        # 2. Susun domain untuk op.assignment menggunakan batch_id
        domain = [
            ('active', '=', True),
            ('state', '!=', 'cancel')
        ]
        if batch_id:
            domain.append(('batch_id', '=', batch_id))

        fields = [
            'id',
            'name',
            'grading_assignment_id',
            'subject_id',
            'faculty_id',
            'batch_id',
            'description',
            'state',
            'marks',
            'issued_date',
            'submission_date'
        ]

        assignments = self.odoo_client.search_read(
            uid=uid,
            password=password,
            model='op.assignment',
            domain=domain,
            fields=fields,
            order='submission_date asc'
        )

        grading_ids = [
            grading_raw[0]
            for assignment in assignments
            if isinstance(grading_raw := assignment.get('grading_assignment_id'), (list, tuple))
            and grading_raw
        ]
        grading_issued_dates = {}
        if grading_ids:
            grading_records = self.odoo_client.search_read(
                uid=uid,
                password=password,
                model='grading.assignment',
                domain=[('id', 'in', grading_ids)],
                fields=['id', 'issued_date'],
                limit=len(grading_ids),
            )
            grading_issued_dates = {
                record.get('id'): record.get('issued_date')
                for record in grading_records
            }

        res = []
        for oa in assignments:
            assignment_id = oa.get('id')
            
            # Fetch submission info for this student
            sub_domain = [('assignment_id', '=', assignment_id)]
            if student_id:
                sub_domain.append(('student_id', '=', student_id))
            
            sub_records = self.odoo_client.search_read(
                uid=uid,
                password=password,
                model='op.assignment.sub.line',
                domain=sub_domain,
                fields=['id', 'state', 'marks', 'write_date', 'submission_date'],
                limit=1
            )

            submission_id = None
            submission_state = None
            score_obtained = 0.0
            submitted_at = None

            if sub_records:
                sub = sub_records[0]
                submission_id = sub.get('id')
                submission_state = sub.get('state', 'draft')
                score_obtained = sub.get('marks') or 0.0
                submitted_at = sub.get('write_date') or sub.get('submission_date')

            grading_raw = oa.get('grading_assignment_id')
            master_id = grading_raw[0] if isinstance(grading_raw, (list, tuple)) else (oa.get('id') or 0)
            issued_date = grading_issued_dates.get(master_id) or oa.get('issued_date')

            subj_raw = oa.get('subject_id')
            subj_id = subj_raw[0] if isinstance(subj_raw, (list, tuple)) else None

            fac_raw = oa.get('faculty_id')
            fac_id = fac_raw[0] if isinstance(fac_raw, (list, tuple)) else 0

            batch_raw = oa.get('batch_id')
            batch_id_val = batch_raw[0] if isinstance(batch_raw, (list, tuple)) else 0

            res.append({
                'assignment_id': oa.get('id'),
                'master_assignment_id': master_id,
                'title': oa.get('name') or 'Tugas',
                'subject_id': subj_id,
                'faculty_id': fac_id,
                'batch_id': batch_id_val,
                'description': oa.get('description') or '',
                'assignment_state': oa.get('state') or 'draft',
                'max_marks': oa.get('marks') or 100.0,
                'issued_date': issued_date,
                'deadline': oa.get('submission_date'),
                'submission_id': submission_id,
                'submission_state': submission_state,
                'score_obtained': score_obtained,
                'submitted_at': submitted_at
            })

        return res

    def get_attachments_by_model(self, uid: int, password: str, res_model: str, res_id: int) -> List[Dict[str, Any]]:
        """
        Mengambil lampiran file dari ir.attachment via Odoo RPC.
        """
        records = self.odoo_client.search_read(
            uid=uid,
            password=password,
            model='ir.attachment',
            domain=[('res_model', '=', res_model), ('res_id', '=', res_id)],
            fields=['id', 'name', 'store_fname', 'create_uid']
        )
        res = []
        for r in records:
            res.append({
                'id': r.get('id'),
                'file_name': r.get('name') or 'file',
                'store_fname': r.get('store_fname'),
                'create_uid': r.get('create_uid')
            })
        return res

    def submit_assignment(
        self, uid: int, password: str, student_id: int, assignment_id: int, file_bytes: bytes, filename: str
    ) -> Dict[str, Any]:
        """
        Mengunggah berkas pengumpulan tugas ke Odoo op.assignment.sub.line dan ir.attachment via RPC.
        """
        now_str = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        # 1. Cari apakah baris submission (op.assignment.sub.line) sudah ada untuk siswa dan assignment ini
        existing_sub = self.odoo_client.search_read(
            uid=uid,
            password=password,
            model='op.assignment.sub.line',
            domain=[('assignment_id', '=', assignment_id), ('student_id', '=', student_id)],
            fields=['id', 'state'],
            limit=1
        )

        if existing_sub:
            sub_id = existing_sub[0]['id']
            self.odoo_client.write(
                uid=uid,
                password=password,
                model='op.assignment.sub.line',
                ids=[sub_id],
                values={
                    'state': 'submitted',
                    'submission_date': now_str
                }
            )
        else:
            sub_id = self.odoo_client.create(
                uid=uid,
                password=password,
                model='op.assignment.sub.line',
                values={
                    'assignment_id': assignment_id,
                    'student_id': student_id,
                    'state': 'submitted',
                    'submission_date': now_str
                }
            )

        # 2. Simpan file attachment ke ir.attachment
        b64_content = base64.b64encode(file_bytes).decode('utf-8')
        att_id = self.odoo_client.create(
            uid=uid,
            password=password,
            model='ir.attachment',
            values={
                'name': filename,
                'res_model': 'op.assignment.sub.line',
                'res_id': sub_id,
                'datas': b64_content,
                'type': 'binary'
            }
        )

        return {
            'submission_id': sub_id,
            'attachment_id': att_id,
            'file_name': filename,
            'state': 'submitted',
            'submitted_at': now_str
        }