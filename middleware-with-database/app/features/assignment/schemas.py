from pydantic import BaseModel, ConfigDict, field_validator
from typing import Optional, List
from datetime import datetime

class AttachmentResponse(BaseModel):
    id: int
    file_name: str
    file_url: str
    uploaded_by_role: str

    model_config = ConfigDict(from_attributes=True)

class StudentSubmissionResponse(BaseModel):
    id: int
    state: str
    marks: float
    submitted_at: Optional[datetime] = None
    attachments: List[AttachmentResponse] = []

    model_config = ConfigDict(from_attributes=True)

class SubjectInfo(BaseModel):
    id: Optional[int] = None
    name: str = "Umum"

class AssignmentResponse(BaseModel):
    id: int
    master_assignment_id: int
    title: str
    assignment_type: str
    subject: SubjectInfo
    faculty_id: int
    batch_id: int
    description: str
    state: str
    max_marks: float
    issued_date: Optional[datetime] = None
    submission_deadline: Optional[datetime] = None
    teacher_attachments: List[AttachmentResponse] = []
    student_submission: Optional[StudentSubmissionResponse] = None

    @field_validator('description', mode='before')
    @classmethod
    def sanitize_description(cls, v):
        if not v or str(v).strip() == '-':
            return ""
        return str(v).strip()

    model_config = ConfigDict(from_attributes=True)