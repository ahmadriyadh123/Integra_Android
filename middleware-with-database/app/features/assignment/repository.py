import ast
import base64
import hashlib
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class AssignmentNotSubmittableError(Exception):
    pass


class AssignmentDeadlinePassedError(Exception):
    pass


class AssignmentAlreadySubmittedError(Exception):
    pass


class AssignmentRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def _columns(self, table_name: str) -> set[str]:
        result = await self.db.execute(
            text("""
                SELECT column_name
                FROM information_schema.columns
                WHERE table_schema = current_schema()
                  AND table_name = :table_name;
            """),
            {"table_name": table_name},
        )
        return {
            str(row["column_name"])
            for row in result.mappings().all()
        }

    async def get_assignments_by_student(
        self, student_id: int, assignment_ids: Optional[List[int]] = None
    ) -> List[Dict[str, Any]]:
        if assignment_ids is not None and not assignment_ids:
            return []

        id_filter = ""
        params: Dict[str, Any] = {"student_id": student_id}
        if assignment_ids is not None:
            id_filter = "AND oa.id = ANY(:assignment_ids)"
            params["assignment_ids"] = assignment_ids

        assignment_columns = await self._columns("op_assignment")
        master_columns = await self._columns("grading_assignment")

        def select_column(name: str, *, fallback: str = "NULL") -> str:
            if name in assignment_columns:
                return f"oa.{name}"
            if name in master_columns:
                return f"ga.{name}"
            return fallback

        subject_id = (
            "oa.subject_id"
            if "subject_id" in assignment_columns
            else "ga.subject_id"
            if "subject_id" in master_columns
            else "NULL"
        )
        subject_join = (
            f"LEFT JOIN op_subject subject ON subject.id = {subject_id}"
            if subject_id != "NULL"
            else ""
        )
        subject_name = "subject.name" if subject_join else "NULL"
        faculty_id = select_column("faculty_id")
        batch_id = select_column("batch_id")
        description = select_column("description", fallback="''")
        max_marks = select_column("marks", fallback="100")
        query = text(f"""
            SELECT
                oa.id AS assignment_id,
                ga.id AS master_assignment_id,
                ga.name AS title,
                {subject_id} AS subject_id,
                {subject_name} AS subject_name,
                {faculty_id} AS faculty_id,
                {batch_id} AS batch_id,
                {description} AS description,
                oa.state AS assignment_state,
                {max_marks} AS max_marks,
                ga.issued_date AS issued_date,
                oa.submission_date AS deadline,
                sub.id AS submission_id,
                sub.state AS submission_state,
                sub.marks AS score_obtained,
                COALESCE(sub.write_date, sub.submission_date) AS submitted_at
            FROM op_assignment oa
            JOIN grading_assignment ga ON ga.id = oa.grading_assignment_id
            JOIN op_assignment_op_student_rel rel
              ON rel.op_assignment_id = oa.id
            {subject_join}
            LEFT JOIN LATERAL (
                SELECT s.id, s.state, s.marks, s.write_date, s.submission_date
                FROM op_assignment_sub_line s
                WHERE s.assignment_id = oa.id
                  AND s.student_id = :student_id
                ORDER BY s.id DESC
                LIMIT 1
            ) sub ON TRUE
            WHERE rel.op_student_id = :student_id
              AND oa.active IS TRUE
              AND oa.state != 'cancel'
              {id_filter}
            ORDER BY oa.submission_date ASC NULLS LAST, oa.id ASC;
        """)
        result = await self.db.execute(query, params)
        return [dict(row) for row in result.mappings().all()]

    async def get_attachments_by_model(
        self, res_model: str, res_id: int
    ) -> List[Dict[str, Any]]:
        if res_model not in {"op.assignment", "op.assignment.sub.line"}:
            raise ValueError("Model lampiran assignment tidak valid.")
        query = text("""
            SELECT id, name AS file_name, store_fname, create_uid
            FROM ir_attachment
            WHERE res_model = :res_model
              AND res_id = :res_id
              AND type = 'binary'
              AND COALESCE(active, TRUE) IS TRUE
              AND COALESCE(for_delete, FALSE) IS FALSE
            ORDER BY id;
        """)
        result = await self.db.execute(
            query,
            {"res_model": res_model, "res_id": res_id},
        )
        return [dict(row) for row in result.mappings().all()]

    @staticmethod
    def _overlap_cursor(cursor: str) -> datetime:
        try:
            value = datetime.fromisoformat(cursor.replace("Z", "+00:00"))
        except ValueError as exc:
            raise ValueError("Cursor assignment tidak valid.") from exc
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc).replace(tzinfo=None) - timedelta(
            minutes=2
        )

    async def get_assignment_sync_delta(
        self, student_id: int, cursor: Optional[str]
    ) -> Dict[str, Any]:
        watermark = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
        if cursor is None:
            return {
                "full_sync": True,
                "assignment_ids": None,
                "removed_ids": [],
                "next_cursor": watermark,
            }

        since = self._overlap_cursor(cursor)
        query = text("""
            SELECT DISTINCT changed.assignment_id
            FROM (
                SELECT oa.id AS assignment_id
                FROM op_assignment oa
                JOIN op_assignment_op_student_rel rel
                  ON rel.op_assignment_id = oa.id
                WHERE rel.op_student_id = :student_id
                  AND oa.write_date >= :since

                UNION

                SELECT s.assignment_id
                FROM op_assignment_sub_line s
                WHERE s.student_id = :student_id
                  AND s.write_date >= :since

                UNION

                SELECT oa.id
                FROM op_assignment oa
                JOIN op_assignment_op_student_rel rel
                  ON rel.op_assignment_id = oa.id
                JOIN grading_assignment ga
                  ON ga.id = oa.grading_assignment_id
                WHERE rel.op_student_id = :student_id
                  AND ga.write_date >= :since

                UNION

                SELECT oa.id
                FROM ir_attachment att
                JOIN op_assignment oa ON oa.id = att.res_id
                JOIN op_assignment_op_student_rel rel
                  ON rel.op_assignment_id = oa.id
                WHERE rel.op_student_id = :student_id
                  AND att.res_model = 'op.assignment'
                  AND att.write_date >= :since

                UNION

                SELECT s.assignment_id
                FROM ir_attachment att
                JOIN op_assignment_sub_line s ON s.id = att.res_id
                WHERE s.student_id = :student_id
                  AND att.res_model = 'op.assignment.sub.line'
                  AND att.write_date >= :since
            ) changed
            WHERE changed.assignment_id IS NOT NULL;
        """)
        result = await self.db.execute(
            query,
            {"student_id": student_id, "since": since},
        )
        assignment_ids = sorted(
            {int(row["assignment_id"]) for row in result.mappings().all()}
        )
        return {
            "full_sync": False,
            "assignment_ids": assignment_ids,
            "removed_ids": [],
            "next_cursor": watermark,
        }

    async def _submitted_state_value(self) -> str:
        columns = await self._columns("ir_model_fields")
        if "selection" not in columns:
            return "submit"

        result = await self.db.execute(
            text("""
                SELECT selection
                FROM ir_model_fields
                WHERE model = 'op.assignment.sub.line'
                  AND name = 'state'
                LIMIT 1;
            """)
        )
        row = result.mappings().first()
        selection = row.get("selection") if row else None
        if isinstance(selection, str):
            try:
                choices = ast.literal_eval(selection)
            except (ValueError, SyntaxError):
                choices = []
            for value, label in choices if isinstance(choices, (list, tuple)) else []:
                if str(value).strip().lower() in {"submit", "submitted"} or str(
                    label
                ).strip().lower() in {"submit", "submitted"}:
                    return str(value)
        raise RuntimeError(
            "Odoo tidak menyediakan pilihan state Submit/Submitted untuk "
            "op.assignment.sub.line."
        )

    async def ensure_submission_allowed(
        self,
        student_id: int,
        assignment_id: int,
        *,
        allow_existing_files: bool = False,
    ) -> Dict[str, Any]:
        result = await self.db.execute(
            text("""
                SELECT oa.id, oa.submission_date
                FROM op_assignment oa
                JOIN op_assignment_op_student_rel rel
                  ON rel.op_assignment_id = oa.id
                WHERE oa.id = :assignment_id
                  AND rel.op_student_id = :student_id
                  AND oa.active IS TRUE
                  AND oa.state IN ('publish', 'published')
                FOR UPDATE OF oa;
            """),
            {"assignment_id": assignment_id, "student_id": student_id},
        )
        assignment = result.mappings().first()
        if not assignment:
            raise AssignmentNotSubmittableError(
                "Penugasan tidak aktif, tidak ditugaskan kepada siswa ini, "
                "atau belum dipublikasikan."
            )

        deadline_value = assignment.get("submission_date")
        if deadline_value:
            deadline = deadline_value
            if isinstance(deadline, str):
                deadline = datetime.fromisoformat(deadline.replace("Z", "+00:00"))
            if deadline.tzinfo is None:
                deadline = deadline.replace(tzinfo=timezone.utc)
            if datetime.now(timezone.utc) > deadline:
                raise AssignmentDeadlinePassedError(
                    "Batas waktu pengumpulan tugas telah lewat."
                )

        submission_result = await self.db.execute(
            text("""
                SELECT id, state, submission_date
                FROM op_assignment_sub_line
                WHERE assignment_id = :assignment_id
                  AND student_id = :student_id
                ORDER BY id DESC
                LIMIT 1;
            """),
            {"assignment_id": assignment_id, "student_id": student_id},
        )
        submission = submission_result.mappings().first()
        submitted_state = await self._submitted_state_value()
        if submission:
            state = str(submission.get("state") or "").lower()
            if state == "graded":
                raise AssignmentAlreadySubmittedError("Tugas ini sudah dikumpulkan.")
            if (
                not allow_existing_files
                and state in {submitted_state.lower(), "submit", "submitted"}
            ):
                attachment_result = await self.db.execute(
                    text("""
                        SELECT id
                        FROM ir_attachment
                        WHERE res_model = 'op.assignment.sub.line'
                          AND res_id = :submission_id
                          AND COALESCE(active, TRUE) IS TRUE
                          AND COALESCE(for_delete, FALSE) IS FALSE
                        LIMIT 1;
                    """),
                    {"submission_id": submission["id"]},
                )
                if attachment_result.mappings().first():
                    raise AssignmentAlreadySubmittedError(
                        "Tugas ini sudah dikumpulkan."
                    )
        return {
            "submission": submission,
            "submitted_state": submitted_state,
        }

    async def update_submission_attachments(
        self,
        *,
        uid: int,
        student_id: int,
        assignment_id: int,
        files: List[Dict[str, Any]],
        remove_attachment_ids: List[int],
    ) -> Dict[str, Any]:
        if not files and not remove_attachment_ids:
            raise ValueError("Tambahkan atau pilih berkas yang akan dihapus.")
        if any(attachment_id <= 0 for attachment_id in remove_attachment_ids):
            raise ValueError("ID lampiran yang akan dihapus tidak valid.")

        allowed = await self.ensure_submission_allowed(
            student_id,
            assignment_id,
            allow_existing_files=True,
        )
        submission = allowed["submission"]
        if not submission:
            raise AssignmentAlreadySubmittedError(
                "Belum ada pengumpulan yang dapat diedit."
            )
        submission_id = int(submission["id"])
        now = datetime.now(timezone.utc).replace(tzinfo=None)

        current_result = await self.db.execute(
            text("""
                SELECT id
                FROM ir_attachment
                WHERE res_model = 'op.assignment.sub.line'
                  AND res_id = :submission_id
                FOR UPDATE;
            """),
            {"submission_id": submission_id},
        )
        current_ids = {
            int(row["id"]) for row in current_result.mappings().all()
        }
        remove_ids = set(remove_attachment_ids)
        if len(remove_ids) != len(remove_attachment_ids):
            raise ValueError("ID lampiran yang akan dihapus tidak boleh duplikat.")
        if not remove_ids.issubset(current_ids):
            raise AssignmentNotSubmittableError(
                "Satu atau beberapa lampiran bukan milik pengumpulan tugas ini."
            )
        if len(current_ids - remove_ids) + len(files) < 1:
            raise ValueError("Pengumpulan tugas harus memiliki minimal satu berkas.")

        if remove_ids:
            await self.db.execute(
                text("""
                    DELETE FROM ir_attachment
                    WHERE res_model = 'op.assignment.sub.line'
                      AND res_id = :submission_id
                      AND id = ANY(:attachment_ids);
                """),
                {
                    "submission_id": submission_id,
                    "attachment_ids": sorted(remove_ids),
                },
            )

        added_attachments = []
        for uploaded_file in files:
            file_bytes = uploaded_file["file_bytes"]
            filename = uploaded_file["filename"]
            result = await self.db.execute(
                text("""
                    INSERT INTO ir_attachment (
                        name, res_model, res_id, type, mimetype, db_datas,
                        store_fname, file_size, checksum, public,
                        create_uid, create_date, write_uid, write_date
                    )
                    VALUES (
                        :name, 'op.assignment.sub.line', :submission_id, 'binary',
                        :mimetype, :db_datas, NULL, :file_size, :checksum, FALSE,
                        :uid, :timestamp, :uid, :timestamp
                    )
                    RETURNING id;
                """),
                {
                    "name": filename,
                    "submission_id": submission_id,
                    "mimetype": uploaded_file["mimetype"],
                    "db_datas": base64.b64encode(file_bytes),
                    "file_size": len(file_bytes),
                    "checksum": hashlib.sha1(file_bytes).hexdigest(),
                    "uid": uid,
                    "timestamp": now,
                },
            )
            added_attachments.append(
                {
                    "attachment_id": int(result.scalar_one()),
                    "file_name": filename,
                }
            )

        await self.db.execute(
            text("""
                UPDATE op_assignment_sub_line
                SET write_uid = :uid, write_date = :timestamp
                WHERE id = :submission_id;
            """),
            {"uid": uid, "timestamp": now, "submission_id": submission_id},
        )
        remaining_result = await self.db.execute(
            text("""
                SELECT id AS attachment_id, name AS file_name
                FROM ir_attachment
                WHERE res_model = 'op.assignment.sub.line'
                  AND res_id = :submission_id
                ORDER BY id;
            """),
            {"submission_id": submission_id},
        )
        attachments = [
            dict(row) for row in remaining_result.mappings().all()
        ]
        await self.db.commit()
        return {
            "submission_id": submission_id,
            "attachment_id": attachments[0]["attachment_id"],
            "file_name": attachments[0]["file_name"],
            "attachments": attachments,
            "state": submission["state"],
            "submitted_at": submission.get("submission_date").isoformat()
            if submission.get("submission_date")
            else None,
            "added_attachments": added_attachments,
            "removed_attachment_ids": sorted(remove_ids),
        }

    async def submit_assignment(
        self,
        *,
        uid: int,
        student_id: int,
        assignment_id: int,
        files: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        if not files:
            raise ValueError("Pilih minimal satu berkas untuk dikumpulkan.")

        allowed = await self.ensure_submission_allowed(student_id, assignment_id)
        now = datetime.now(timezone.utc).replace(tzinfo=None)
        submission = allowed["submission"]
        if submission:
            submission_id = int(submission["id"])
            await self.db.execute(
                text("""
                    UPDATE op_assignment_sub_line
                    SET state = :state,
                        submission_date = :submitted_at,
                        write_uid = :uid,
                        write_date = :submitted_at
                    WHERE id = :submission_id;
                """),
                {
                    "state": allowed["submitted_state"],
                    "submitted_at": now,
                    "uid": uid,
                    "submission_id": submission_id,
                },
            )
        else:
            result = await self.db.execute(
                text("""
                    INSERT INTO op_assignment_sub_line (
                        assignment_id, student_id, state, submission_date,
                        create_uid, create_date, write_uid, write_date
                    )
                    VALUES (
                        :assignment_id, :student_id, :state, :submitted_at,
                        :uid, :submitted_at, :uid, :submitted_at
                    )
                    RETURNING id;
                """),
                {
                    "assignment_id": assignment_id,
                    "student_id": student_id,
                    "state": allowed["submitted_state"],
                    "submitted_at": now,
                    "uid": uid,
                },
            )
            submission_id = int(result.scalar_one())

        attachments = []
        for uploaded_file in files:
            file_bytes = uploaded_file["file_bytes"]
            filename = uploaded_file["filename"]
            attachment_result = await self.db.execute(
                text("""
                    INSERT INTO ir_attachment (
                        name, res_model, res_id, type, mimetype, db_datas,
                        store_fname, file_size, checksum, public,
                        create_uid, create_date, write_uid, write_date
                    )
                    VALUES (
                        :name, 'op.assignment.sub.line', :submission_id, 'binary',
                        :mimetype, :db_datas, NULL, :file_size, :checksum, FALSE,
                        :uid, :submitted_at, :uid, :submitted_at
                    )
                    RETURNING id;
                """),
                {
                    "name": filename,
                    "submission_id": submission_id,
                    "mimetype": uploaded_file["mimetype"],
                    "db_datas": base64.b64encode(file_bytes),
                    "file_size": len(file_bytes),
                    "checksum": hashlib.sha1(file_bytes).hexdigest(),
                    "uid": uid,
                    "submitted_at": now,
                },
            )
            attachments.append(
                {
                    "attachment_id": int(attachment_result.scalar_one()),
                    "file_name": filename,
                }
            )
        await self.db.commit()
        return {
            "submission_id": submission_id,
            "attachment_id": attachments[0]["attachment_id"],
            "file_name": attachments[0]["file_name"],
            "attachments": attachments,
            "state": allowed["submitted_state"],
            "submitted_at": now.isoformat(),
        }

    async def get_assignment_attachment(
        self, student_id: int, assignment_id: int, attachment_id: int
    ) -> Optional[Dict[str, Any]]:
        query = text("""
            SELECT
                att.id,
                att.name,
                att.mimetype,
                att.db_datas,
                att.store_fname,
                att.res_model,
                att.res_id
            FROM ir_attachment att
            WHERE att.id = :attachment_id
              AND att.type = 'binary'
              AND COALESCE(att.active, TRUE) IS TRUE
              AND COALESCE(att.for_delete, FALSE) IS FALSE
              AND (
                (
                    att.res_model = 'op.assignment'
                    AND att.res_id = :assignment_id
                    AND EXISTS (
                        SELECT 1
                        FROM op_assignment oa
                        JOIN op_assignment_op_student_rel rel
                          ON rel.op_assignment_id = oa.id
                        WHERE oa.id = :assignment_id
                          AND rel.op_student_id = :student_id
                          AND oa.active IS TRUE
                          AND oa.state != 'cancel'
                    )
                )
                OR
                (
                    att.res_model = 'op.assignment.sub.line'
                    AND EXISTS (
                        SELECT 1
                        FROM op_assignment_sub_line s
                        WHERE s.id = att.res_id
                          AND s.assignment_id = :assignment_id
                          AND s.student_id = :student_id
                    )
                )
              )
            LIMIT 1;
        """)
        result = await self.db.execute(
            query,
            {
                "attachment_id": attachment_id,
                "assignment_id": assignment_id,
                "student_id": student_id,
            },
        )
        row = result.mappings().first()
        return dict(row) if row else None
