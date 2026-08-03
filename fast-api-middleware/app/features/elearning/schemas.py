from pydantic import BaseModel
from typing import List, Optional

class CourseItemResponse(BaseModel):
    id: int
    title: str
    teacher_name: str
    total_chapters: int
    progress_percentage: float

class APIResponseCourseList(BaseModel):
    success: bool
    message: str
    data: List[CourseItemResponse]

class MaterialItemResponse(BaseModel):
    id: int
    title: str
    material_type: str      # 'video', 'document', 'quiz', 'infographic'
    file_url: Optional[str] = None
    is_completed: bool = False

class ChapterResponse(BaseModel):
    id: int
    chapter_name: str
    description: str
    materials: List[MaterialItemResponse]

class CourseDetailResponse(BaseModel):
    id: int
    title: str
    teacher_name: str
    description: str
    chapters: List[ChapterResponse]

class APIResponseCourseDetail(BaseModel):
    success: bool
    message: str
    data: Optional[CourseDetailResponse] = None