from typing import List
from app.features.assignment.repository import AssignmentRepository
from app.features.assignment.schemas import (
    AssignmentResponse, 
    SubjectInfo, 
    StudentSubmissionResponse, 
    AttachmentResponse
)

class AssignmentService:
    def __init__(self, repository: AssignmentRepository):
        self.repository = repository

    async def get_student_assignments(self, student_id: int) -> List[AssignmentResponse]:
        raw_assignments = await self.repository.get_assignments_by_student(student_id)
        formatted_list = []

        for row in raw_assignments:
            # 1. Fetch Lampiran Tugas dari Guru
            teacher_files_raw = await self.repository.get_attachments_by_model(
                res_model='op_assignment', 
                res_id=row['assignment_id']
            )
            teacher_attachments = [
                AttachmentResponse(
                    id=f['id'],
                    file_name=f['file_name'],
                    file_url=f"/files/{f['id']}",
                    uploaded_by_role='teacher'
                ) for f in teacher_files_raw
            ]

            # 2. Fetch Pengumpulan & Lampiran Tugas Siswa (jika ada)
            student_submission = None
            if row['submission_id']:
                student_files_raw = await self.repository.get_attachments_by_model(
                    res_model='op_assignment_sub_line', 
                    res_id=row['submission_id']
                )
                student_attachments = [
                    AttachmentResponse(
                        id=f['id'],
                        file_name=f['file_name'],
                        file_url=f"/files/{f['id']}",
                        uploaded_by_role='student'
                    ) for f in student_files_raw
                ]

                student_submission = StudentSubmissionResponse(
                    id=row['submission_id'],
                    state=row['submission_state'] or 'draft',
                    marks=row['score_obtained'] or 0.0,
                    submitted_at=row['submitted_at'],
                    attachments=student_attachments
                )

            # 3. Wrapping Object Response
            assignment_obj = AssignmentResponse(
                id=row['assignment_id'],
                master_assignment_id=row['master_assignment_id'],
                title=row['title'],
                assignment_type=row['assignment_type_name'],
                subject=SubjectInfo(id=row['subject_id'], name="Mata Pelajaran" if row['subject_id'] else "Umum"),
                faculty_id=row['faculty_id'],
                batch_id=row['batch_id'],
                description=row['description'],
                state=row['assignment_state'],
                max_marks=row['max_marks'],
                issued_date=row['issued_date'],
                submission_deadline=row['deadline'],
                teacher_attachments=teacher_attachments,
                student_submission=student_submission
            )
            formatted_list.append(assignment_obj)

        return formatted_list