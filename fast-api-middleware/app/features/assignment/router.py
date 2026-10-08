import logging
import base64
from io import BytesIO
from urllib.parse import quote
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import StreamingResponse
from typing import List, Dict, Any

from app.core.dependencies import get_current_user_credentials, get_odoo_client
from app.core.odoo_client import OdooAccessError, OdooRPCClient
from app.features.assignment.schemas import AssignmentResponse
from app.features.assignment.repository import (
    AssignmentAlreadySubmittedError,
    AssignmentDeadlinePassedError,
    AssignmentNotSubmittableError,
    AssignmentRepository,
)
from app.features.assignment.service import AssignmentService

router = APIRouter(
    prefix="/assignments",
    tags=["Assignments"]
)
logger = logging.getLogger(__name__)
_MAX_SUBMISSION_SIZE = 20 * 1024 * 1024

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


@router.post("/{assignment_id}/submit")
async def submit_assignment(
    assignment_id: int,
    file: UploadFile = File(...),
    credentials: Dict[str, Any] = Depends(get_current_user_credentials),
    odoo_client: OdooRPCClient = Depends(get_odoo_client),
):
    student_id = credentials.get("student_id")
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kredensial student_id tidak ditemukan pada Token JWT Anda.",
        )

    try:
        file_bytes = await file.read(_MAX_SUBMISSION_SIZE + 1)
        if len(file_bytes) > _MAX_SUBMISSION_SIZE:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="Ukuran file maksimal 20 MiB.",
            )
        if not file_bytes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File yang diunggah kosong.",
            )

        repository = AssignmentRepository(odoo_client)
        service = AssignmentService(repository)
        result = service.submit_assignment(
            uid=credentials["uid"],
            password=credentials["password"],
            student_id=student_id,
            assignment_id=assignment_id,
            file_bytes=file_bytes,
            filename=file.filename or "submission",
        )
        return {"success": True, "data": result}
    except AssignmentAlreadySubmittedError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
    except AssignmentDeadlinePassedError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
    except AssignmentNotSubmittableError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc
    except OdooAccessError as exc:
        logger.exception(
            "[assignments/%s/submit] Odoo menolak pembuatan lampiran uid=%s",
            assignment_id,
            credentials.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=(
                "Odoo menolak akses untuk menyimpan lampiran. Pastikan pengguna "
                "yang login memiliki hak akses yang diperlukan."
            ),
        ) from exc
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception(
            "[assignments/%s/submit] Upload gagal uid=%s",
            assignment_id,
            credentials.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal mengunggah jawaban tugas.",
        ) from exc
    finally:
        await file.close()


@router.get("/{assignment_id}/attachments/{attachment_id}")
def download_assignment_attachment(
    assignment_id: int,
    attachment_id: int,
    credentials: Dict[str, Any] = Depends(get_current_user_credentials),
    odoo_client: OdooRPCClient = Depends(get_odoo_client),
):
    student_id = credentials.get("student_id")
    if not student_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kredensial student_id tidak ditemukan pada Token JWT Anda.",
        )

    repository = AssignmentRepository(odoo_client)
    try:
        attachment = repository.get_assignment_attachment(
            uid=credentials["uid"],
            password=credentials["password"],
            student_id=student_id,
            assignment_id=assignment_id,
            attachment_id=attachment_id,
        )
        if not attachment or not attachment.get("datas"):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Lampiran tidak ditemukan atau tidak dapat diakses.",
            )

        content = base64.b64decode(attachment["datas"])
        filename = attachment.get("name") or f"assignment-{assignment_id}-file"
        safe_filename = quote(filename, safe="")
        return StreamingResponse(
            BytesIO(content),
            media_type=attachment.get("mimetype") or "application/octet-stream",
            headers={
                "Content-Disposition": f"attachment; filename*=UTF-8''{safe_filename}",
                "Content-Length": str(len(content)),
            },
        )
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception(
            "[assignments/%s/attachments/%s] Download gagal uid=%s",
            assignment_id,
            attachment_id,
            credentials.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal mengunduh lampiran tugas.",
        ) from exc
