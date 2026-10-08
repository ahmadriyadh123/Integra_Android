from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession

# Import core dependencies sesuai kode yang Anda miliki
from app.core.dependencies import get_db, get_current_user_credentials
from app.features.assignment.schemas import AssignmentResponse
from app.features.assignment.repository import AssignmentRepository
from app.features.assignment.service import AssignmentService

router = APIRouter(
    prefix="/assignments",
    tags=["Assignments"]
)

@router.get("", response_model=List[AssignmentResponse])
async def get_my_assignments(
    credentials: Dict[str, Any] = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db)
):
    """
    Endpoint untuk mengambil seluruh daftar penugasan milik siswa berdasarkan JWT Token.
    """
    student_id = credentials.get("student_id")
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kredensial student_id tidak ditemukan pada Token JWT Anda."
        )

    try:
        repo = AssignmentRepository(db)
        service = AssignmentService(repo)
        return await service.get_student_assignments(student_id=student_id)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data penugasan: {str(e)}"
        )