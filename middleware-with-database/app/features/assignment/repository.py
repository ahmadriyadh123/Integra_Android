from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from typing import List, Dict, Any

class AssignmentRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_assignments_by_student(self, student_id: int) -> List[Dict[str, Any]]:
        query = text("""
            SELECT 
                oa.id AS assignment_id,
                ga.id AS master_assignment_id,
                ga.name AS title,
                COALESCE(gat.name, 'Tugas') AS assignment_type_name,
                ga.subject_id,
                ga.faculty_id,
                oa.batch_id,
                oa.description,
                oa.state AS assignment_state,
                oa.marks AS max_marks,
                ga.issued_date,
                oa.submission_date AS deadline,
                sub.id AS submission_id,
                sub.state AS submission_state,
                sub.marks AS score_obtained,
                sub.write_date AS submitted_at
            FROM op_assignment oa
            JOIN grading_assignment ga ON oa.grading_assignment_id = ga.id
            LEFT JOIN grading_assignment_type gat ON ga.assignment_type = gat.id
            JOIN op_assignment_op_student_rel rel ON oa.id = rel.op_assignment_id
            LEFT JOIN op_assignment_sub_line sub 
                ON oa.id = sub.assignment_id AND sub.create_uid = rel.op_student_id
            WHERE rel.op_student_id = :student_id
              AND oa.active = true
              AND oa.state != 'cancel'
            ORDER BY oa.submission_date ASC;
        """)
        
        result = await self.db.execute(query, {"student_id": student_id})
        return [dict(row) for row in result.mappings()]

    async def get_attachments_by_model(self, res_model: str, res_id: int) -> List[Dict[str, Any]]:
        query = text("""
            SELECT id, name AS file_name, store_fname, create_uid
            FROM ir_attachment
            WHERE res_model = :res_model AND res_id = :res_id
        """)
        result = await self.db.execute(query, {"res_model": res_model, "res_id": res_id})
        return [dict(row) for row in result.mappings()]