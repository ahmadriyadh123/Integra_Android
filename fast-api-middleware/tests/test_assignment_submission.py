from datetime import datetime, timedelta, timezone

import pytest

from app.features.assignment.repository import (
    AssignmentAlreadySubmittedError,
    AssignmentDeadlinePassedError,
    AssignmentNotSubmittableError,
    AssignmentRepository,
)
from app.features.assignment.service import AssignmentService


class FakeOdooClient:
    db = "school_db"

    def __init__(
        self,
        *,
        deadline=None,
        assignment_exists=True,
        submission_state=None,
        submission_has_attachment=False,
    ):
        self.deadline = deadline or (datetime.now(timezone.utc) + timedelta(days=1))
        self.assignment_exists = assignment_exists
        self.submission_state = submission_state
        self.submission_has_attachment = submission_has_attachment
        self.assignment_domain = None

    def execute_kw(self, *, model, method, **kwargs):
        assert method == "fields_get"
        if model == "op.assignment.sub.line":
            return {
                "state": {
                    "selection": [
                        ("draft", "Draft"),
                        ("submit", "Submitted"),
                        ("accept", "Accepted"),
                    ]
                }
            }
        assert model == "op.assignment"
        return {
            "student_ids": {"type": "many2many", "relation": "op.student"},
        }

    def search_read(self, *, model, **kwargs):
        if model == "op.assignment":
            self.assignment_domain = kwargs.get("domain")
            if not self.assignment_exists:
                return []
            return [{"id": 3, "state": "publish", "submission_date": self.deadline.isoformat()}]
        if model == "op.assignment.sub.line" and self.submission_state:
            return [{"id": 9, "state": self.submission_state}]
        if model == "ir.attachment" and self.submission_has_attachment:
            return [{"id": 42}]
        return []


def test_allows_published_assignment_assigned_to_student_before_deadline():
    odoo = FakeOdooClient()
    repository = AssignmentRepository(odoo)

    repository.ensure_submission_allowed(
        uid=17,
        password="secret",
        student_id=121,
        assignment_id=3,
    )
    assert ("student_ids", "in", [121]) in odoo.assignment_domain


def test_rejects_assignment_after_deadline():
    repository = AssignmentRepository(
        FakeOdooClient(deadline=datetime.now(timezone.utc) - timedelta(seconds=1))
    )

    with pytest.raises(AssignmentDeadlinePassedError):
        repository.ensure_submission_allowed(
            uid=17,
            password="secret",
            student_id=121,
            assignment_id=3,
        )


def test_rejects_assignment_not_available_to_student_batch():
    repository = AssignmentRepository(FakeOdooClient(assignment_exists=False))

    with pytest.raises(AssignmentNotSubmittableError):
        repository.ensure_submission_allowed(
            uid=17,
            password="secret",
            student_id=121,
            assignment_id=3,
        )


@pytest.mark.parametrize("state", ["submit", "submitted"])
def test_allows_submitted_record_without_attachment_to_be_completed(state):
    repository = AssignmentRepository(FakeOdooClient(submission_state=state))

    repository.ensure_submission_allowed(
        uid=17,
        password="secret",
        student_id=121,
        assignment_id=3,
    )


@pytest.mark.parametrize("state", ["submit", "submitted"])
def test_rejects_submitted_record_that_already_has_attachment(state):
    repository = AssignmentRepository(
        FakeOdooClient(submission_state=state, submission_has_attachment=True)
    )

    with pytest.raises(AssignmentAlreadySubmittedError):
        repository.ensure_submission_allowed(
            uid=17,
            password="secret",
            student_id=121,
            assignment_id=3,
        )


def test_rejects_graded_submission():
    repository = AssignmentRepository(FakeOdooClient(submission_state="graded"))

    with pytest.raises(AssignmentAlreadySubmittedError):
        repository.ensure_submission_allowed(
            uid=17,
            password="secret",
            student_id=121,
            assignment_id=3,
        )


def test_reads_valid_submission_state_from_odoo_selection():
    repository = AssignmentRepository(FakeOdooClient())

    assert repository._submitted_state_value(uid=17, password="secret") == "submit"


def test_assignment_response_includes_uploaded_student_file():
    deadline = datetime(2026, 10, 6, 12, 30, tzinfo=timezone.utc)

    class AssignmentWithSubmissionOdoo(FakeOdooClient):
        def search_read(self, *, model, **kwargs):
            if model == "op.assignment":
                return [
                    {
                        "id": 5,
                        "name": "TUGAS PAI BAB 1",
                        "grading_assignment_id": [3, "TUGAS PAI BAB 1"],
                        "subject_id": [6, "PAI"],
                        "faculty_id": [1, "Guru"],
                        "batch_id": [3, "Kelas"],
                        "description": "Kerjakan latihan",
                        "state": "publish",
                        "marks": 100,
                        "issued_date": "2026-03-31 23:00:00",
                        "submission_date": deadline.isoformat(),
                    }
                ]
            if model == "grading.assignment":
                return []
            if model == "op.assignment.sub.line":
                return [
                    {
                        "id": 3,
                        "state": "submit",
                        "marks": 0,
                        "submission_date": "2026-10-02 05:51:13",
                    }
                ]
            if model == "ir.attachment":
                domain = kwargs.get("domain", [])
                if ("res_model", "=", "op.assignment.sub.line") in domain:
                    return [
                        {
                            "id": 88,
                            "name": "jawaban-pai.pdf",
                            "store_fname": "ab/cd/file",
                            "create_uid": [17, "Siswa"],
                        }
                    ]
                return []
            return super().search_read(model=model, **kwargs)

    service = AssignmentService(
        AssignmentRepository(AssignmentWithSubmissionOdoo(deadline=deadline))
    )
    result = service.get_student_assignments(uid=17, password="secret", student_id=121)

    assert result[0].student_submission is not None
    assert result[0].submission_deadline == deadline
    assert result[0].student_submission.state == "submit"
    assert result[0].student_submission.attachments[0].file_name == "jawaban-pai.pdf"


class FakeAttachmentOdoo(FakeOdooClient):
    def __init__(self, attachment, *, submission_student_id=None):
        super().__init__()
        self.attachment = attachment
        self.submission_student_id = submission_student_id

    def search_read(self, *, model, **kwargs):
        if model == "op.assignment":
            return [{"id": 5}]
        if model == "ir.attachment":
            return [self.attachment]
        if model == "op.assignment.sub.line":
            requested_domain = kwargs.get("domain", [])
            requested_student = next(
                value
                for field, operator, value in requested_domain
                if field == "student_id"
            )
            if requested_student == self.submission_student_id:
                return [{"id": self.attachment["res_id"]}]
        return []


def test_assignment_attachment_allows_teacher_file_for_assigned_assignment():
    repository = AssignmentRepository(
        FakeAttachmentOdoo({
            "id": 41,
            "name": "petunjuk.pdf",
            "datas": "cGRm",
            "mimetype": "application/pdf",
            "res_model": "op.assignment",
            "res_id": 5,
        })
    )

    attachment = repository.get_assignment_attachment(
        uid=17,
        password="secret",
        student_id=121,
        assignment_id=5,
        attachment_id=41,
    )

    assert attachment["name"] == "petunjuk.pdf"


def test_assignment_attachment_rejects_another_students_submission():
    repository = AssignmentRepository(
        FakeAttachmentOdoo(
            {
                "id": 42,
                "name": "jawaban.pdf",
                "datas": "cGRm",
                "mimetype": "application/pdf",
                "res_model": "op.assignment.sub.line",
                "res_id": 30,
            },
            submission_student_id=122,
        )
    )

    attachment = repository.get_assignment_attachment(
        uid=17,
        password="secret",
        student_id=121,
        assignment_id=5,
        attachment_id=42,
    )

    assert attachment is None