import base64
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional
from app.core.odoo_client import OdooRPCClient


class AssignmentNotSubmittableError(Exception):
    pass


class AssignmentDeadlinePassedError(Exception):
    pass


class AssignmentAlreadySubmittedError(Exception):
    pass


class AssignmentRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo_client = odoo_client

    def _submitted_state_value(self, uid: int, password: str) -> str:
        model_fields = self.odoo_client.execute_kw(
            uid=uid,
            password=password,
            model='op.assignment.sub.line',
            method='fields_get',
            args=[],
            kwargs={'attributes': ['selection']},
        )
        choices = (model_fields.get('state') or {}).get('selection') or []
        for value, label in choices:
            normalized_value = str(value).strip().lower()
            normalized_label = str(label).strip().lower()
            if normalized_value in {'submit', 'submitted'} or normalized_label in {
                'submit',
                'submitted',
            }:
                return str(value)

        raise RuntimeError(
            'Odoo tidak menyediakan pilihan state Submit/Submitted untuk '
            f'op.assignment.sub.line; pilihan tersedia: {choices}'
        )

    def _student_relation_field(self, uid: int, password: str) -> str:
        fields = self.odoo_client.execute_kw(
            uid=uid,
            password=password,
            model='op.assignment',
            method='fields_get',
            args=[],
            kwargs={'attributes': ['type', 'relation']},
        )
        candidates = [
            name
            for name, metadata in fields.items()
            if metadata.get('type') == 'many2many'
            and metadata.get('relation') == 'op.student'
        ]
        if len(candidates) != 1:
            raise RuntimeError(
                'Relasi op.assignment ke op.student tidak dapat diidentifikasi '
                f'dengan aman (kandidat: {candidates}).'
            )
        return candidates[0]

    def get_assignments_by_student(self, uid: int, password: str, student_id: int) -> List[Dict[str, Any]]:
        """
        Mengambil penugasan yang secara eksplisit terhubung ke record op.student.
        """
        student_field = self._student_relation_field(uid, password)
        domain = [
            ('active', '=', True),
            ('state', '!=', 'cancel'),
            (student_field, 'in', [student_id]),
        ]

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
                limit=1,
                use_sudo=True,
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

    def get_attachments_by_model(
        self,
        uid: int,
        password: str,
        res_model: str,
        res_id: int,
        use_sudo: bool = False,
    ) -> List[Dict[str, Any]]:
        """
        Mengambil lampiran file dari ir.attachment via Odoo RPC.
        """
        records = self.odoo_client.search_read(
            uid=uid,
            password=password,
            model='ir.attachment',
            domain=[('res_model', '=', res_model), ('res_id', '=', res_id)],
            fields=['id', 'name', 'store_fname', 'create_uid'],
            use_sudo=use_sudo,
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

    def get_assignment_attachment(
        self,
        uid: int,
        password: str,
        student_id: int,
        assignment_id: int,
        attachment_id: int,
    ) -> Optional[Dict[str, Any]]:
        student_field = self._student_relation_field(uid, password)
        assignment = self.odoo_client.search_read(
            uid=uid,
            password=password,
            model='op.assignment',
            domain=[
                ('id', '=', assignment_id),
                (student_field, 'in', [student_id]),
                ('active', '=', True),
                ('state', '!=', 'cancel'),
            ],
            fields=['id'],
            limit=1,
        )
        if not assignment:
            return None

        attachments = self.odoo_client.search_read(
            uid=uid,
            password=password,
            model='ir.attachment',
            domain=[
                ('id', '=', attachment_id),
                ('res_model', 'in', ['op.assignment', 'op.assignment.sub.line']),
            ],
            fields=['id', 'name', 'datas', 'mimetype', 'res_model', 'res_id'],
            limit=1,
            use_sudo=True,
        )
        if not attachments:
            return None

        attachment = attachments[0]
        res_model = attachment.get('res_model')
        res_id = attachment.get('res_id')
        if res_model == 'op.assignment' and res_id == assignment_id:
            return attachment

        if res_model == 'op.assignment.sub.line':
            submission = self.odoo_client.search_read(
                uid=uid,
                password=password,
                model='op.assignment.sub.line',
                domain=[
                    ('id', '=', res_id),
                    ('assignment_id', '=', assignment_id),
                    ('student_id', '=', student_id),
                ],
                fields=['id'],
                limit=1,
                use_sudo=True,
            )
            if submission:
                return attachment

        return None

    def submit_assignment(
        self, uid: int, password: str, student_id: int, assignment_id: int, file_bytes: bytes, filename: str
    ) -> Dict[str, Any]:
        """
        Mengunggah berkas pengumpulan tugas ke Odoo op.assignment.sub.line dan ir.attachment via RPC.
        """
        now_str = datetime.now(timezone.utc).replace(tzinfo=None).strftime('%Y-%m-%d %H:%M:%S')
        submitted_state = self._submitted_state_value(uid, password)

        # 1. Cari apakah baris submission (op.assignment.sub.line) sudah ada untuk siswa dan assignment ini
        existing_sub = self.odoo_client.search_read(
            uid=uid,
            password=password,
            model='op.assignment.sub.line',
            domain=[('assignment_id', '=', assignment_id), ('student_id', '=', student_id)],
            fields=['id', 'state'],
            limit=1,
            use_sudo=True,
        )

        if existing_sub:
            sub_id = existing_sub[0]['id']
            self.odoo_client.write(
                uid=uid,
                password=password,
                model='op.assignment.sub.line',
                ids=[sub_id],
                values={
                    'state': submitted_state,
                    'submission_date': now_str
                },
                use_sudo=True,
            )
        else:
            sub_id = self.odoo_client.create(
                uid=uid,
                password=password,
                model='op.assignment.sub.line',
                values={
                    'assignment_id': assignment_id,
                    'student_id': student_id,
                    'state': submitted_state,
                    'submission_date': now_str
                },
                use_sudo=True,
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
            },
            use_sudo=True,
        )

        return {
            'submission_id': sub_id,
            'attachment_id': att_id,
            'file_name': filename,
            'state': 'submitted',
            'submitted_at': now_str
        }

    def ensure_submission_allowed(
        self,
        uid: int,
        password: str,
        student_id: int,
        assignment_id: int,
    ) -> None:
        student_field = self._student_relation_field(uid, password)

        assignments = self.odoo_client.search_read(
            uid=uid,
            password=password,
            model='op.assignment',
            domain=[
                ('id', '=', assignment_id),
                (student_field, 'in', [student_id]),
                ('active', '=', True),
                ('state', 'in', ['publish', 'published']),
            ],
            fields=['id', 'submission_date'],
            limit=1,
        )
        if not assignments:
            raise AssignmentNotSubmittableError(
                'Penugasan tidak aktif, tidak ditugaskan kepada siswa ini, atau belum dipublikasikan.'
            )

        deadline_value = assignments[0].get('submission_date')
        if deadline_value:
            deadline = datetime.fromisoformat(str(deadline_value).replace('Z', '+00:00'))
            if deadline.tzinfo is None:
                deadline = deadline.replace(tzinfo=timezone.utc)
            if datetime.now(timezone.utc) > deadline:
                raise AssignmentDeadlinePassedError('Batas waktu pengumpulan tugas telah lewat.')

        existing_submissions = self.odoo_client.search_read(
            uid=uid,
            password=password,
            model='op.assignment.sub.line',
            domain=[
                ('assignment_id', '=', assignment_id),
                ('student_id', '=', student_id),
            ],
            fields=['id', 'state'],
            limit=1,
            use_sudo=True,
        )
        submitted_state = self._submitted_state_value(uid, password)
        if existing_submissions:
            existing_submission = existing_submissions[0]
            existing_state = existing_submission.get('state')
            if existing_state == 'graded':
                raise AssignmentAlreadySubmittedError('Tugas ini sudah dikumpulkan.')

            if existing_state in {submitted_state, 'submit', 'submitted'}:
                attachments = self.odoo_client.search_read(
                    uid=uid,
                    password=password,
                    model='ir.attachment',
                    domain=[
                        ('res_model', '=', 'op.assignment.sub.line'),
                        ('res_id', '=', existing_submission['id']),
                    ],
                    fields=['id'],
                    limit=1,
                    use_sudo=True,
                )
                if attachments:
                    raise AssignmentAlreadySubmittedError(
                        'Tugas ini sudah dikumpulkan.'
                    )