from pydantic import BaseModel, Field
from typing import List, Literal, Optional


class CourseItemResponse(BaseModel):
    id: int
    title: str
    teacher_name: str
    total_slides: int
    completed_slides: int = 0
    progress_percent: int = 0
    description: str


class APIResponseCourseList(BaseModel):
    success: bool
    message: str
    data: List[CourseItemResponse]


class SlideItemResponse(BaseModel):
    id: int
    title: str
    material_type: str       # 'document', 'video', 'scorm', 'quiz'
    download_url: Optional[str] = None
    sequence: int
    is_completed: bool = False


class CourseDetailResponse(BaseModel):
    id: int
    title: str
    teacher_name: str
    description: str
    total_slides: int
    completed_slides: int = 0
    progress_percent: int = 0
    slides: List[SlideItemResponse]


class APIResponseCourseDetail(BaseModel):
    success: bool
    message: str
    data: Optional[CourseDetailResponse] = None


class CourseMessageResponse(BaseModel):
    id: int
    author_name: str
    body: str
    created_at: str
    is_own: bool


class APIResponseCourseMessages(BaseModel):
    success: bool
    message: str
    data: List[CourseMessageResponse]


class CreateCourseMessageRequest(BaseModel):
    body: str = Field(min_length=1, max_length=2000)


class CompleteSlideRequest(BaseModel):
    source: Literal['opened', 'scorm']
    completion_status: Optional[str] = None
