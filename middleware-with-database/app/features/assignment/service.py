from typing import Any, Dict, List, Optional

from app.features.assignment.repository import AssignmentRepository
from app.features.assignment.schemas import (
    AssignmentResponse,
    AttachmentResponse,
    StudentSubmissionResponse,
    SubjectInfo,
)


class AssignmentService:
    def __init__(self, repository: AssignmentRepository):
        self.repository = repository

    @staticmethod
    def _localized_text(value: Any, fallback: str) -> str:
        if isinstance(value, dict):
            value = value.get("en_US") or next(iter(value.values()), None)
        return str(value).strip() if value else fallback

    async def get_student_assignments(
        self,
        student_id: int,
        assignment_ids: Optional[List[int]] = None,
    ) -> List[AssignmentResponse]:
        raw_assignments = await self.repository.get_assignments_by_student(
            student_id=student_id,
            assignment_ids=assignment_ids,
        )
        formatted_list = []

        for row in raw_assignments:
            assignment_id = row["assignment_id"]
            teacher_files = await self.repository.get_attachments_by_model(
                res_model="op.assignment",
                res_id=assignment_id,
            )
            teacher_attachments = [
                AttachmentResponse(
                    id=file["id"],
                    file_name=file["file_name"],
                    file_url=(
                        f"/assignments/{assignment_id}/attachments/{file['id']}"
                    ),
                    uploaded_by_role="teacher",
                )
                for file in teacher_files
            ]

            student_submission = None
            if row["submission_id"]:
                student_files = await self.repository.get_attachments_by_model(
                    res_model="op.assignment.sub.line",
                    res_id=row["submission_id"],
                )
                student_attachments = [
                    AttachmentResponse(
                        id=file["id"],
                        file_name=file["file_name"],
                        file_url=(
                            f"/assignments/{assignment_id}/attachments/{file['id']}"
                        ),
                        uploaded_by_role="student",
                    )
                    for file in student_files
                ]
                student_submission = StudentSubmissionResponse(
                    id=row["submission_id"],
                    state=row["submission_state"] or "draft",
                    marks=row["score_obtained"] or 0.0,
                    submitted_at=row["submitted_at"],
                    attachments=student_attachments,
                )

            formatted_list.append(
                AssignmentResponse(
                    id=assignment_id,
                    master_assignment_id=row["master_assignment_id"],
                    title=self._localized_text(row["title"], "Tugas"),
                    subject=SubjectInfo(
                        id=row["subject_id"],
                            name=self._localized_text(row.get("subject_name"), "Umum"),
                    ),
                    faculty_id=row["faculty_id"] or 0,
                    batch_id=row["batch_id"] or 0,
                    description=row["description"] or "",
                    state=row["assignment_state"] or "draft",
                    max_marks=row["max_marks"] or 100.0,
                    issued_date=row["issued_date"],
                    submission_deadline=row["deadline"],
                    teacher_attachments=teacher_attachments,
                    student_submission=student_submission,
                )
            )
        return formatted_list

    async def sync_student_assignments(
        self, student_id: int, cursor: Optional[str]
    ) -> Dict[str, Any]:
        sync = await self.repository.get_assignment_sync_delta(
            student_id=student_id,
            cursor=cursor,
        )
        assignment_ids = sync["assignment_ids"]
        items = await self.get_student_assignments(
            student_id=student_id,
            assignment_ids=assignment_ids,
        )
        present_ids = {item.id for item in items}
        removed_ids = (
            []
            if assignment_ids is None
            else [
                assignment_id
                for assignment_id in assignment_ids
                if assignment_id not in present_ids
            ]
        )
        return {
            "items": items,
            "removed_ids": removed_ids,
            "next_cursor": sync["next_cursor"],
            "full_sync": sync["full_sync"],
        }

    async def submit_assignment(
        self,
        *,
        uid: int,
        student_id: int,
        assignment_id: int,
        files: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        return await self.repository.submit_assignment(
            uid=uid,
            student_id=student_id,
            assignment_id=assignment_id,
            files=files,
        )

    async def update_submission_attachments(
        self,
        *,
        uid: int,
        student_id: int,
        assignment_id: int,
        files: List[Dict[str, Any]],
        remove_attachment_ids: List[int],
    ) -> Dict[str, Any]:
        return await self.repository.update_submission_attachments(
            uid=uid,
            student_id=student_id,
            assignment_id=assignment_id,
            files=files,
            remove_attachment_ids=remove_attachment_ids,
        )
