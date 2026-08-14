# app/features/elearning/schemas.py
from pydantic import BaseModel
from typing import List, Optional

class CourseItemResponse(BaseModel):
    id: int
    title: str
    teacher_name: str
    total_slides: int
    description: str

class APIResponseCourseList(BaseModel):
    success: bool
    message: str
    data: List[CourseItemResponse]

class SlideItemResponse(BaseModel):
    id: int
    title: str
    material_type: str  # 'document', 'video', 'scorm', 'quiz'
    download_url: Optional[str] = None
    sequence: int

class CourseDetailResponse(BaseModel):
    id: int
    title: str
    teacher_name: str
    description: str
    total_slides: int
    slides: List[SlideItemResponse]

class APIResponseCourseDetail(BaseModel):
    success: bool
    message: str
    data: Optional[CourseDetailResponse] = None