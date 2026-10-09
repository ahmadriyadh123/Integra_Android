import xmlrpc.client
import logging
from typing import Dict, Any, Optional
from app.core.odoo_client import OdooRPCClient

logger = logging.getLogger(__name__)


class OdooUnavailableError(RuntimeError):
    """Raised when Odoo cannot be reached during authentication."""


class AuthRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def _resolve_student_and_jenjang(
        self,
        uid: int,
        password: str,
        partner_id: Optional[int],
        user_data: Optional[Dict[str, Any]] = None,
    ) -> tuple[Optional[int], str, Optional[int], str]:
        """
        Cari student_id, jenjang, dan course_id siswa.
        Return: (student_id, jenjang, course_id)
        """
        student_id_from_user = None
        jenjang = "sd"
        course_id = None
        course_name = ''

        if user_data is not None:
            for field in ("student_line", "student_id"):
                value = user_data.get(field)
                if isinstance(value, list) and value:
                    student_id_from_user = int(value[0])
                    break
                if isinstance(value, int) and value:
                    student_id_from_user = value
                    break

        # Reuse user fields when the login query already loaded them.
        if not student_id_from_user and user_data is None:
            try:
                records = self.odoo.search_read(
                    uid=uid,
                    password=password,
                    model="res.users",
                    domain=[("id", "=", uid)],
                    fields=["student_line", "student_id"],
                    limit=1,
                )
                if records:
                    for field in ("student_line", "student_id"):
                        value = records[0].get(field)
                        if isinstance(value, list) and value:
                            student_id_from_user = int(value[0])
                            break
                        if isinstance(value, int) and value:
                            student_id_from_user = value
                            break
            except Exception as error:
                logger.debug("[auth] user/student relation fields unavailable: %s", error)

        # Cari melalui op.student jika dua relasi user sebelumnya tidak tersedia.
        if not student_id_from_user and partner_id:
            try:
                records = self.odoo.search_read(
                    uid=uid, password=password,
                    model='op.student',
                    domain=[('partner_id', '=', partner_id)],
                    fields=['id'],
                    limit=1
                )
                if records:
                    student_id_from_user = int(records[0]['id'])
            except Exception as e:
                logger.debug(f"[auth] op.student tidak bisa diakses: {e}")

        # Beberapa tenant menghubungkan siswa langsung ke res.users, bukan partner.
        if not student_id_from_user:
            try:
                records = self.odoo.search_read(
                    uid=uid,
                    password=password,
                    model='op.student',
                    domain=[('user_id', '=', uid)],
                    fields=['id'],
                    limit=1
                )
                if records:
                    student_id_from_user = int(records[0]['id'])
            except Exception as e:
                logger.debug(f"[auth] op.student.user_id tidak tersedia: {e}")

        # Ambil kelas dan jenjang untuk disimpan pada session pengguna.
        if student_id_from_user:
            try:
                student_records = self.odoo.search_read(
                    uid=uid, password=password,
                    model='op.student',
                    domain=[('id', '=', student_id_from_user)],
                    fields=['grade'],
                    limit=1
                )
                if student_records:
                    cid = student_records[0].get('grade')
                    if isinstance(cid, list) and cid:
                        course_id = int(cid[0])
                        # Simpan nama kelas asli (contoh: "Kelas 1 SD")
                        course_name = str(cid[1]) if len(cid) > 1 else ''
                        # Deteksi jenjang dari nama kelas
                        course_name_upper = course_name.upper()
                        if ' SMP' in course_name_upper or course_name_upper.startswith('SMP'):
                            jenjang = 'smp'
                        elif any(k in course_name_upper for k in ['TK', 'PAUD', 'KB']):
                            jenjang = 'tk'
                        else:
                            jenjang = 'sd'  # Default: SD
                    elif isinstance(cid, int) and cid:
                        course_id = cid
                        course_name = ''
            except Exception as e:
                logger.debug(f"[auth] Gagal ambil course_id dari op.student: {e}")

        logger.info(
            f"[auth] uid={uid} student_id={student_id_from_user} "
            f"course_id={course_id} course_name='{course_name}' jenjang={jenjang}"
        )
        return student_id_from_user, jenjang, course_id, course_name

    def resolve_student_context(
        self,
        uid: int,
        password: str,
        partner_id: Optional[int] = None,
    ) -> tuple[Optional[int], str, Optional[int], str]:
        """Resolve student and class context for authenticated-user features."""
        return self._resolve_student_and_jenjang(uid, password, partner_id)

    def authenticate_odoo_user(self, username: str, password: str) -> Optional[Dict[str, Any]]:
        """
        Verifikasi kredensial ke Odoo, lalu kumpulkan uid, partner_id,
        student_id, dan jenjang untuk disimpan ke JWT.
        """
        try:
            uid = self.odoo.common.authenticate(self.odoo.db, username, password, {})
            if not uid:
                return None

            core_user_fields = ["id", "name", "login", "email", "partner_id"]
            try:
                user_records = self.odoo.search_read(
                    uid=uid,
                    password=password,
                    model="res.users",
                    domain=[("id", "=", uid)],
                    fields=core_user_fields + ["student_line", "student_id"],
                    limit=1,
                )
            except xmlrpc.client.Fault as exc:
                logger.debug(
                    "[auth] Optional student fields unavailable for uid=%s: %s",
                    uid,
                    exc,
                )
                user_records = self.odoo.search_read(
                    uid=uid,
                    password=password,
                    model="res.users",
                    domain=[("id", "=", uid)],
                    fields=core_user_fields,
                    limit=1,
                )

            if not user_records:
                return None

            user_data = user_records[0]
            partner_val = user_data.get('partner_id')
            partner_id = partner_val[0] if isinstance(partner_val, list) and partner_val else None

            has_student_relation = any(
                user_data.get(field) for field in ("student_line", "student_id")
            )
            if partner_id or has_student_relation:
                student_id, jenjang, course_id, course_name = (
                    self._resolve_student_and_jenjang(
                        uid, password, partner_id, user_data=user_data
                    )
                )
            else:
                student_id, jenjang, course_id, course_name = None, "sd", None, ""

            return {
                "uid": uid,
                "name": str(user_data.get('name') or ''),
                "username": str(user_data.get('login') or username),
                "email": str(user_data.get('email') or ''),
                "partner_id": partner_id,
                "student_id": student_id,
                "jenjang": jenjang,
                "course_id": course_id,
                "course_name": course_name,
            }
        except (OSError, xmlrpc.client.ProtocolError) as e:
            logger.warning("[auth] Odoo unavailable during login: %s", e)
            raise OdooUnavailableError("Odoo authentication service unavailable") from e
        except Exception as e:
            logger.error(f"[auth] authenticate_odoo_user error: {e}")
            return None
