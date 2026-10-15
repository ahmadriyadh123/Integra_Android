import base64
import binascii
import json
import logging
from io import BytesIO
from urllib.parse import quote
from typing import Any, Dict

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    Query,
    UploadFile,
    status,
)
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_attachment_path
from app.core.dependencies import get_current_user_credentials, get_db
from app.features.assignment.repository import (
    AssignmentAlreadySubmittedError,
    AssignmentDeadlinePassedError,
    AssignmentNotSubmittableError,
    AssignmentRepository,
)
from app.features.assignment.schemas import AssignmentResponse
from app.features.assignment.service import AssignmentService

router = APIRouter(prefix="/assignments", tags=["Assignments"])
logger = logging.getLogger(__name__)
_MAX_SUBMISSION_SIZE = 20 * 1024 * 1024


def _student_id(credentials: Dict[str, Any]) -> int:
    student_id = credentials.get("student_id")
    if type(student_id) is not int or student_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Data siswa belum tersedia. Silakan login kembali atau hubungi pihak sekolah.",
        )
    return student_id


@router.get("", response_model=list[AssignmentResponse])
async def get_my_assignments(
    credentials: Dict[str, Any] = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = _student_id(credentials)
    try:
        service = AssignmentService(AssignmentRepository(db))
        return await service.get_student_assignments(student_id=student_id)
    except Exception as exc:
        logger.exception(
            "[assignments] Gagal mengambil data uid=%s",
            credentials.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal mengambil data penugasan.",
        ) from exc


@router.get("/sync")
async def sync_my_assignments(
    cursor: str | None = Query(None),
    credentials: Dict[str, Any] = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = _student_id(credentials)
    try:
        service = AssignmentService(AssignmentRepository(db))
        data = await service.sync_student_assignments(
            student_id=student_id,
            cursor=cursor,
        )
        return {"success": True, "data": data}
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Data tugas belum dapat disinkronkan. Muat ulang halaman.",
        ) from exc
    except Exception as exc:
        logger.exception(
            "[assignments/sync] Gagal sinkron uid=%s",
            credentials.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal sinkronisasi data penugasan.",
        ) from exc


@router.post("/{assignment_id}/submit")
async def submit_assignment(
    assignment_id: int,
    files: list[UploadFile] = File(default=[]),
    file: UploadFile | None = File(default=None),
    credentials: Dict[str, Any] = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = _student_id(credentials)
    uploaded_files = [*files, *([file] if file is not None else [])]
    try:
        if not uploaded_files:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Pilih minimal satu berkas untuk dikumpulkan.",
            )

        submission_files = []
        for upload in uploaded_files:
            file_bytes = await upload.read(_MAX_SUBMISSION_SIZE + 1)
            if len(file_bytes) > _MAX_SUBMISSION_SIZE:
                raise HTTPException(
                    status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                    detail=f"Ukuran file {upload.filename or 'unggahan'} maksimal 20 MiB.",
                )
            if not file_bytes:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"File {upload.filename or 'unggahan'} kosong.",
                )
            submission_files.append(
                {
                    "file_bytes": file_bytes,
                    "filename": upload.filename or "submission",
                    "mimetype": upload.content_type or "application/octet-stream",
                }
            )

        service = AssignmentService(AssignmentRepository(db))
        result = await service.submit_assignment(
            uid=credentials["uid"],
            student_id=student_id,
            assignment_id=assignment_id,
            files=submission_files,
        )
        return {"success": True, "data": result}
    except AssignmentAlreadySubmittedError as exc:
        await db.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
    except AssignmentDeadlinePassedError as exc:
        await db.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
    except AssignmentNotSubmittableError as exc:
        await db.rollback()
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc
    except HTTPException:
        await db.rollback()
        raise
    except Exception as exc:
        await db.rollback()
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
        for upload in uploaded_files:
            await upload.close()


@router.patch("/{assignment_id}/submission")
async def update_submission_attachments(
    assignment_id: int,
    files: list[UploadFile] = File(default=[]),
    remove_attachment_ids: str = Form(default="[]"),
    credentials: Dict[str, Any] = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = _student_id(credentials)
    try:
        try:
            parsed_remove_ids = json.loads(remove_attachment_ids)
        except json.JSONDecodeError as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Daftar lampiran yang akan dihapus tidak valid.",
            ) from exc
        if not isinstance(parsed_remove_ids, list) or any(
            type(attachment_id) is not int for attachment_id in parsed_remove_ids
        ):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Daftar lampiran yang akan dihapus tidak valid.",
            )

        if not files and not parsed_remove_ids:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Tambahkan berkas atau pilih lampiran yang akan dihapus.",
            )

        submission_files = []
        for upload in files:
            file_bytes = await upload.read(_MAX_SUBMISSION_SIZE + 1)
            if len(file_bytes) > _MAX_SUBMISSION_SIZE:
                raise HTTPException(
                    status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                    detail=f"Ukuran file {upload.filename or 'unggahan'} maksimal 20 MiB.",
                )
            if not file_bytes:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"File {upload.filename or 'unggahan'} kosong.",
                )
            submission_files.append(
                {
                    "file_bytes": file_bytes,
                    "filename": upload.filename or "submission",
                    "mimetype": upload.content_type or "application/octet-stream",
                }
            )

        service = AssignmentService(AssignmentRepository(db))
        result = await service.update_submission_attachments(
            uid=credentials["uid"],
            student_id=student_id,
            assignment_id=assignment_id,
            files=submission_files,
            remove_attachment_ids=parsed_remove_ids,
        )
        return {"success": True, "data": result}
    except AssignmentDeadlinePassedError as exc:
        await db.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
    except AssignmentAlreadySubmittedError as exc:
        await db.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
    except AssignmentNotSubmittableError as exc:
        await db.rollback()
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc
    except ValueError as exc:
        await db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    except HTTPException:
        await db.rollback()
        raise
    except Exception as exc:
        await db.rollback()
        logger.exception(
            "[assignments/%s/submission] Perubahan lampiran gagal uid=%s",
            assignment_id,
            credentials.get("uid"),
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gagal memperbarui lampiran pengumpulan tugas.",
        ) from exc
    finally:
        for upload in files:
            await upload.close()


@router.get("/{assignment_id}/attachments/{attachment_id}")
async def download_assignment_attachment(
    assignment_id: int,
    attachment_id: int,
    credentials: Dict[str, Any] = Depends(get_current_user_credentials),
    db: AsyncSession = Depends(get_db),
):
    student_id = _student_id(credentials)
    repository = AssignmentRepository(db)
    try:
        attachment = await repository.get_assignment_attachment(
            student_id=student_id,
            assignment_id=assignment_id,
            attachment_id=attachment_id,
        )
        if not attachment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Lampiran tidak ditemukan atau tidak dapat diakses.",
            )

        content = None
        db_datas = attachment.get("db_datas")
        if db_datas:
            encoded = bytes(db_datas) if isinstance(db_datas, memoryview) else db_datas
            try:
                content = base64.b64decode(encoded, validate=True)
            except (binascii.Error, TypeError, ValueError):
                logger.warning(
                    "[assignments/%s/attachments/%s] db_datas tidak valid",
                    assignment_id,
                    attachment_id,
                )

        if content is None and attachment.get("store_fname"):
            file_path = get_attachment_path(
                attachment["store_fname"],
                db.info.get("tenant_database"),
            )
            if file_path and file_path.is_file():
                content = file_path.read_bytes()

        if content is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Isi lampiran tidak ditemukan.",
            )

        filename = attachment.get("name") or f"assignment-{assignment_id}-file"
        return StreamingResponse(
            BytesIO(content),
            media_type=attachment.get("mimetype") or "application/octet-stream",
            headers={
                "Content-Disposition": (
                    f"attachment; filename*=UTF-8''{quote(filename, safe='')}"
                ),
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
