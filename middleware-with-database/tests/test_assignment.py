import base64
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest
from fastapi import FastAPI

from app.features.assignment.router import (
    download_assignment_attachment,
    router,
)
from app.features.assignment.repository import (
    AssignmentAlreadySubmittedError,
    AssignmentDeadlinePassedError,
    AssignmentNotSubmittableError,
    AssignmentRepository,
)
from app.features.assignment.service import AssignmentService


class _Result:
    def __init__(self, rows=None, row=None, scalar=None):
        self.rows = rows or []
        self.row = row
        self.scalar = scalar

    def mappings(self):
        return self

    def all(self):
        return self.rows

    def first(self):
        return self.row

    def scalar_one(self):
        return self.scalar


def test_submission_attachment_edit_route_is_registered():
    app = FastAPI()
    app.include_router(router)

    operation = app.openapi()["paths"]["/assignments/{assignment_id}/submission"][
        "patch"
    ]
    assert operation["requestBody"]["content"]["multipart/form-data"]


@pytest.mark.asyncio
async def test_assignment_listing_returns_student_scoped_assignments_and_files():
    db = AsyncMock(    )
    db.execute.side_effect = [
        _Result(rows=[{"column_name": "subject_id"}]),
        _Result(rows=[]),
        _Result(
            rows=[
                {
                    "assignment_id": 14,
                    "master_assignment_id": 4,
                    "title": {"en_US": "Tugas Matematika", "id_ID": "Tugas Matematika"},
                    "subject_id": 3,
                    "subject_name": {"en_US": "Matematika"},
                    "faculty_id": 7,
                    "batch_id": 2,
                    "description": "Kerjakan latihan",
                    "assignment_state": "publish",
                    "max_marks": 100,
                    "issued_date": None,
                    "deadline": None,
                    "submission_id": 21,
                    "submission_state": "draft",
                    "score_obtained": 0,
                    "submitted_at": None,
                }
            ]
        ),
        _Result(
            rows=[
                {
                    "id": 51,
                    "file_name": "soal.pdf",
                    "store_fname": "ab/cd",
                    "create_uid": 8,
                }
            ]
        ),
        _Result(
            rows=[
                {
                    "id": 52,
                    "file_name": "jawaban.pdf",
                    "store_fname": "ef/gh",
                    "create_uid": 12,
                }
            ]
        ),
    ]

    assignments = await AssignmentService(
        AssignmentRepository(db)
    ).get_student_assignments(student_id=12)

    assert assignments[0].id == 14
    assert assignments[0].subject.name == "Matematika"
    assert assignments[0].student_submission.state == "submitted"
    assert assignments[0].teacher_attachments[0].file_url == (
        "/assignments/14/attachments/51"
    )
    assert assignments[0].student_submission.attachments[0].file_url == (
        "/assignments/14/attachments/52"
    )
    assignment_query = str(db.execute.await_args_list[2].args[0])
    assert "oa.subject_id AS subject_id" in assignment_query
    assert "rel.op_student_id = :student_id" in assignment_query
    assert "att.res_id = s.id" in assignment_query
    assert db.execute.await_args_list[2].args[1] == {"student_id": 12}


@pytest.mark.asyncio
async def test_assignment_listing_works_when_subject_column_is_absent():
    db = AsyncMock()
    db.execute.side_effect = [
        _Result(rows=[{"column_name": "id"}, {"column_name": "name"}]),
        _Result(rows=[{"column_name": "id"}, {"column_name": "name"}]),
        _Result(rows=[]),
    ]

    assignments = await AssignmentRepository(db).get_assignments_by_student(12)

    query = str(db.execute.await_args_list[2].args[0])
    assert assignments == []
    assert "NULL AS subject_id" in query
    assert "NULL AS subject_name" in query
    assert "LEFT JOIN op_subject" not in query


@pytest.mark.asyncio
async def test_assignment_listing_uses_master_subject_when_available():
    db = AsyncMock()
    db.execute.side_effect = [
        _Result(rows=[{"column_name": "id"}]),
        _Result(rows=[{"column_name": "id"}, {"column_name": "subject_id"}]),
        _Result(rows=[]),
    ]

    await AssignmentRepository(db).get_assignments_by_student(12)

    query = str(db.execute.await_args_list[2].args[0])
    assert "ga.subject_id AS subject_id" in query
    assert "LEFT JOIN op_subject subject ON subject.id = ga.subject_id" in query


@pytest.mark.asyncio
async def test_assignment_listing_uses_master_fields_when_missing_from_assignment():
    db = AsyncMock()
    db.execute.side_effect = [
        _Result(rows=[{"column_name": "id"}, {"column_name": "subject_id"}]),
        _Result(
            rows=[
                {"column_name": "id"},
                {"column_name": "name"},
                {"column_name": "faculty_id"},
                {"column_name": "batch_id"},
                {"column_name": "description"},
                {"column_name": "marks"},
                {"column_name": "subject_id"},
            ]
        ),
        _Result(rows=[]),
    ]

    await AssignmentRepository(db).get_assignments_by_student(12)

    query = str(db.execute.await_args_list[2].args[0])
    assert "ga.faculty_id AS faculty_id" in query
    assert "ga.batch_id AS batch_id" in query
    assert "ga.description AS description" in query
    assert "ga.marks AS max_marks" in query
    assert "oa.faculty_id" not in query
    assert "oa.batch_id" not in query


@pytest.mark.asyncio
async def test_assignment_delta_uses_changed_related_rows_and_cursor_overlap():
    db = AsyncMock()
    db.execute.return_value = _Result(rows=[{"assignment_id": 5}, {"assignment_id": 8}])
    repository = AssignmentRepository(db)

    sync = await repository.get_assignment_sync_delta(
        student_id=12,
        cursor="2026-10-09T11:00:00Z",
    )

    assert sync["full_sync"] is False
    assert sync["assignment_ids"] == [5, 8]
    assert sync["removed_ids"] == []
    assert db.execute.await_args.args[1]["since"] == datetime(
        2026, 10, 9, 10, 58
    )


@pytest.mark.asyncio
async def test_assignment_first_sync_requests_full_snapshot():
    db = AsyncMock()

    sync = await AssignmentRepository(db).get_assignment_sync_delta(
        student_id=12,
        cursor=None,
    )

    assert sync["full_sync"] is True
    assert sync["assignment_ids"] is None
    db.execute.assert_not_awaited()


@pytest.mark.asyncio
async def test_invalid_assignment_cursor_is_reported():
    with pytest.raises(ValueError, match="Cursor assignment tidak valid"):
        await AssignmentRepository(AsyncMock()).get_assignment_sync_delta(
            student_id=12,
            cursor="not-a-timestamp",
        )


@pytest.mark.asyncio
async def test_submission_state_uses_standard_submit_value_without_selection_metadata():
    db = AsyncMock()
    db.execute.return_value = _Result(
        rows=[{"column_name": "model"}, {"column_name": "name"}]
    )

    state = await AssignmentRepository(db)._submitted_state_value()

    assert state == "submit"
    db.execute.assert_awaited_once()


@pytest.mark.asyncio
async def test_submission_checks_assignment_deadline_and_duplicate_state():
    db = AsyncMock()
    db.execute.side_effect = [
        _Result(
            row={
                "id": 14,
                "submission_date": datetime.now(timezone.utc) + timedelta(days=1),
            }
        ),
        _Result(row={"id": 21, "state": "graded"}),
    ]
    repository = AssignmentRepository(db)
    repository._submitted_state_value = AsyncMock(return_value="submit")

    with pytest.raises(AssignmentAlreadySubmittedError):
        await repository.ensure_submission_allowed(student_id=12, assignment_id=14)

    assert db.execute.await_count == 2


@pytest.mark.asyncio
async def test_submission_rejects_expired_deadline():
    db = AsyncMock()
    db.execute.return_value = _Result(
        row={
            "id": 14,
            "submission_date": datetime.now(timezone.utc) - timedelta(seconds=1),
        }
    )
    repository = AssignmentRepository(db)

    with pytest.raises(AssignmentDeadlinePassedError):
        await repository.ensure_submission_allowed(student_id=12, assignment_id=14)

    assert db.execute.await_count == 1


@pytest.mark.asyncio
async def test_submission_rejects_unpublished_or_unassigned_assignment():
    db = AsyncMock()
    db.execute.return_value = _Result()

    with pytest.raises(AssignmentNotSubmittableError):
        await AssignmentRepository(db).ensure_submission_allowed(
            student_id=12,
            assignment_id=14,
        )


@pytest.mark.asyncio
async def test_submission_creates_database_submission_and_attachment():
    db = AsyncMock()
    db.execute.side_effect = [
        _Result(
            row={
                "id": 14,
                "submission_date": datetime.now(timezone.utc) + timedelta(days=1),
            }
        ),
        _Result(),
        _Result(scalar=21),
        _Result(scalar=51),
    ]
    repository = AssignmentRepository(db)
    repository._submitted_state_value = AsyncMock(return_value="submit")

    result = await repository.submit_assignment(
        uid=7,
        student_id=12,
        assignment_id=14,
        files=[
            {
                "file_bytes": b"answer contents",
                "filename": "answer.pdf",
                "mimetype": "application/pdf",
            }
        ],
    )

    assert result["submission_id"] == 21
    assert result["attachment_id"] == 51
    assert result["attachments"] == [
        {"attachment_id": 51, "file_name": "answer.pdf"}
    ]
    assert result["state"] == "submit"
    attachment_query = str(db.execute.await_args_list[-1].args[0])
    assert "INSERT INTO ir_attachment" in attachment_query
    assert db.execute.await_args_list[-1].args[1]["db_datas"] == (
        b"YW5zd2VyIGNvbnRlbnRz"
    )
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_submission_stores_all_selected_attachments_on_one_submission():
    db = AsyncMock()
    db.execute.side_effect = [
        _Result(
            row={
                "id": 14,
                "submission_date": datetime.now(timezone.utc) + timedelta(days=1),
            }
        ),
        _Result(),
        _Result(scalar=21),
        _Result(scalar=51),
        _Result(scalar=52),
    ]
    repository = AssignmentRepository(db)
    repository._submitted_state_value = AsyncMock(return_value="submit")

    result = await repository.submit_assignment(
        uid=7,
        student_id=12,
        assignment_id=14,
        files=[
            {
                "file_bytes": b"first file",
                "filename": "first.pdf",
                "mimetype": "application/pdf",
            },
            {
                "file_bytes": b"second file",
                "filename": "second.docx",
                "mimetype": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            },
        ],
    )

    assert result["submission_id"] == 21
    assert result["attachments"] == [
        {"attachment_id": 51, "file_name": "first.pdf"},
        {"attachment_id": 52, "file_name": "second.docx"},
    ]
    attachment_insert_ids = [
        call.args[1]["submission_id"]
        for call in db.execute.await_args_list[3:]
    ]
    assert attachment_insert_ids == [21, 21]
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_update_submission_attachments_can_replace_existing_file_atomically():
    db = AsyncMock()
    db.execute.side_effect = [
        _Result(rows=[{"id": 51}]),
        _Result(),
        _Result(scalar=52),
        _Result(),
        _Result(rows=[{"attachment_id": 52, "file_name": "updated.pdf"}]),
    ]
    repository = AssignmentRepository(db)
    repository.ensure_submission_allowed = AsyncMock(
        return_value={
            "submission": {
                "id": 21,
                "state": "submit",
                "submission_date": datetime(2026, 10, 12, 1, 0),
            },
            "submitted_state": "submit",
        }
    )

    result = await repository.update_submission_attachments(
        uid=7,
        student_id=12,
        assignment_id=14,
        files=[
            {
                "file_bytes": b"replacement contents",
                "filename": "updated.pdf",
                "mimetype": "application/pdf",
            }
        ],
        remove_attachment_ids=[51],
    )

    assert result["submission_id"] == 21
    assert result["attachments"] == [
        {"attachment_id": 52, "file_name": "updated.pdf"}
    ]
    assert result["removed_attachment_ids"] == [51]
    assert result["added_attachments"] == [
        {"attachment_id": 52, "file_name": "updated.pdf"}
    ]
    repository.ensure_submission_allowed.assert_awaited_once_with(
        12,
        14,
        allow_existing_files=True,
    )
    assert "SELECT id" in str(db.execute.await_args_list[0].args[0])
    assert "DELETE FROM ir_attachment" in str(db.execute.await_args_list[1].args[0])
    assert "INSERT INTO ir_attachment" in str(db.execute.await_args_list[2].args[0])
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_update_submission_attachments_cannot_remove_all_files():
    db = AsyncMock()
    db.execute.return_value = _Result(rows=[{"id": 51}])
    repository = AssignmentRepository(db)
    repository.ensure_submission_allowed = AsyncMock(
        return_value={
            "submission": {"id": 21, "state": "submit"},
            "submitted_state": "submit",
        }
    )

    with pytest.raises(ValueError, match="minimal satu berkas"):
        await repository.update_submission_attachments(
            uid=7,
            student_id=12,
            assignment_id=14,
            files=[],
            remove_attachment_ids=[51],
        )

    db.commit.assert_not_awaited()
    assert db.execute.await_count == 1


@pytest.mark.asyncio
async def test_update_submission_attachments_rejects_foreign_file_ids():
    db = AsyncMock()
    db.execute.return_value = _Result(rows=[{"id": 51}])
    repository = AssignmentRepository(db)
    repository.ensure_submission_allowed = AsyncMock(
        return_value={
            "submission": {"id": 21, "state": "submit"},
            "submitted_state": "submit",
        }
    )

    with pytest.raises(AssignmentNotSubmittableError, match="bukan milik"):
        await repository.update_submission_attachments(
            uid=7,
            student_id=12,
            assignment_id=14,
            files=[],
            remove_attachment_ids=[99],
        )

    db.commit.assert_not_awaited()


@pytest.mark.asyncio
async def test_attachment_lookup_scopes_teacher_and_student_files_to_assignment():
    db = AsyncMock()
    db.execute.return_value = _Result(
        row={
            "id": 51,
            "name": "soal.pdf",
            "mimetype": "application/pdf",
            "db_datas": b"cGRm",
            "store_fname": None,
            "res_model": "op.assignment",
            "res_id": 14,
        }
    )

    attachment = await AssignmentRepository(db).get_assignment_attachment(
        student_id=12,
        assignment_id=14,
        attachment_id=51,
    )

    assert attachment["id"] == 51
    query = str(db.execute.await_args.args[0])
    assert "rel.op_student_id = :student_id" in query
    assert "s.student_id = :student_id" in query
    assert "att.type = 'binary'" in query
    assert db.execute.await_args.args[1] == {
        "student_id": 12,
        "assignment_id": 14,
        "attachment_id": 51,
    }


@pytest.mark.asyncio
async def test_assignment_download_reads_database_stored_binary_attachment():
    content = b"\x89PNG\r\n\x1a\nassignment-image"
    db = SimpleNamespace(
        info={"tenant_database": "school_db"},
        execute=AsyncMock(
            return_value=_Result(
                row={
                    "id": 2158,
                    "name": "Screenshot_20261008-135006.png",
                    "mimetype": "application/octet-stream",
                    "type": "binary",
                    "db_datas": base64.b64encode(content),
                    "store_fname": None,
                    "res_model": "op.assignment.sub.line",
                    "res_id": 3,
                }
            )
        ),
    )

    response = await download_assignment_attachment(
        assignment_id=14,
        attachment_id=2158,
        credentials={"student_id": 12, "uid": 17},
        db=db,
    )
    downloaded = b"".join(
        [chunk async for chunk in response.body_iterator]
    )

    assert downloaded == content
    assert response.media_type == "application/octet-stream"
    assert "Screenshot_20261008-135006.png" in response.headers[
        "content-disposition"
    ]
    assert "att.type = 'binary'" in str(db.execute.await_args.args[0])
