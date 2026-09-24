from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Dict, Any

from app.core.dependencies import get_current_user_credentials, get_odoo_client
from app.core.odoo_client import OdooRPCClient
from app.features.assignment.schemas import AssignmentResponse
from app.features.assignment.repository import AssignmentRepository
from app.features.assignment.service import AssignmentService

router = APIRouter(
    prefix="/assignments",
    tags=["Assignments"]
)

@router.get("", response_model=List[AssignmentResponse])
def get_my_assignments(
    credentials: Dict[str, Any] = Depends(get_current_user_credentials),
    odoo_client: OdooRPCClient = Depends(get_odoo_client)
):
    """
    Endpoint untuk mengambil seluruh daftar penugasan milik siswa berdasarkan JWT Token.
    """
    student_id = credentials.get("student_id")
    uid = credentials.get("uid")
    password = credentials.get("password")

    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kredensial student_id tidak ditemukan pada Token JWT Anda."
        )

    try:
        repo = AssignmentRepository(odoo_client)
        service = AssignmentService(repo)
        return service.get_student_assignments(uid=uid, password=password, student_id=student_id)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengambil data penugasan: {str(e)}"
        )

