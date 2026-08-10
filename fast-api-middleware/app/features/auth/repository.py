import xmlrpc.client
import logging
from typing import Dict, Any, Optional
from app.core.odoo_client import OdooRPCClient

logger = logging.getLogger(__name__)


class AuthRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def _resolve_student_and_jenjang(self, uid: int, password: str, partner_id: int) -> tuple[Optional[int], str, Optional[int]]:
        """
        Cari student_id, jenjang, dan course_id siswa.
        Return: (student_id, jenjang, course_id)
        """
        student_id_from_user = None
        jenjang = "sd"
        course_id = None

        # --- Cara 1: field student_line di res.users ---
        try:
            records = self.odoo.search_read(
                uid=uid, password=password,
                model='res.users',
                domain=[('id', '=', uid)],
                fields=['student_line'],
                limit=1
            )
            if records:
                val = records[0].get('student_line')
                if isinstance(val, list) and val:
                    student_id_from_user = int(val[0])
                elif isinstance(val, int) and val:
                    student_id_from_user = val
        except Exception as e:
            logger.debug(f"[auth] res.users.student_line tidak tersedia: {e}")

        # --- Cara 2: field student_id di res.users ---
        if not student_id_from_user:
            try:
                records = self.odoo.search_read(
                    uid=uid, password=password,
                    model='res.users',
                    domain=[('id', '=', uid)],
                    fields=['student_id'],
                    limit=1
                )
                if records:
                    val = records[0].get('student_id')
                    if isinstance(val, list) and val:
                        student_id_from_user = int(val[0])
                    elif isinstance(val, int) and val:
                        student_id_from_user = val
            except Exception as e:
                logger.debug(f"[auth] res.users.student_id tidak tersedia: {e}")

        # --- Cara 3: query op.student via sudo ---
        if not student_id_from_user:
            try:
                records = self.odoo.search_read(
                    uid=uid, password=password,
                    model='op.student',
                    domain=[('partner_id', '=', partner_id)],
                    fields=['id'],
                    limit=1,
                    use_sudo=True
                )
                if records:
                    student_id_from_user = int(records[0]['id'])
            except Exception as e:
                logger.debug(f"[auth] op.student tidak bisa diakses: {e}")

        # --- Ambil course_id dan jenjang dari op.student via sudo ---
        if student_id_from_user:
            try:
                student_records = self.odoo.search_read(
                    uid=uid, password=password,
                    model='op.student',
                    domain=[('id', '=', student_id_from_user)],
                    fields=['course_id'],
                    limit=1,
                    use_sudo=True
                )
                if student_records:
                    cid = student_records[0].get('course_id')
                    if isinstance(cid, list) and cid:
                        course_id = int(cid[0])
                        # Deteksi jenjang dari nama kelas
                        # Contoh: "Kelas 1 SD", "Kelas 7 SMP", "TK A"
                        course_name = str(cid[1]).upper() if len(cid) > 1 else ''
                        if ' SMP' in course_name or course_name.startswith('SMP'):
                            jenjang = 'smp'
                        elif any(k in course_name for k in ['TK', 'PAUD', 'KB']):
                            jenjang = 'tk'
                        else:
                            jenjang = 'sd'  # Default: SD
                    elif isinstance(cid, int) and cid:
                        course_id = cid
            except Exception as e:
                logger.debug(f"[auth] Gagal ambil course_id dari op.student: {e}")

        logger.info(
            f"[auth] uid={uid} student_id={student_id_from_user} "
            f"course_id={course_id} jenjang={jenjang}"
        )
        return student_id_from_user, jenjang, course_id

    def authenticate_odoo_user(self, username: str, password: str) -> Optional[Dict[str, Any]]:
        """
        Verifikasi kredensial ke Odoo, lalu kumpulkan uid, partner_id,
        student_id, dan jenjang untuk disimpan ke JWT.
        """
        try:
            common = xmlrpc.client.ServerProxy(f"{self.odoo.url}/xmlrpc/2/common")

            uid = common.authenticate(self.odoo.db, username, password, {})
            if not uid:
                return None

            user_records = self.odoo.search_read(
                uid=uid, password=password,
                model='res.users',
                domain=[('id', '=', uid)],
                fields=['id', 'name', 'login', 'email', 'partner_id'],
                limit=1
            )

            if not user_records:
                return None

            user_data = user_records[0]
            partner_val = user_data.get('partner_id')
            partner_id = partner_val[0] if isinstance(partner_val, list) and partner_val else None

            student_id, jenjang, course_id = self._resolve_student_and_jenjang(uid, password, partner_id) if partner_id else (None, "sd", None)

            return {
                "uid": uid,
                "name": str(user_data.get('name') or ''),
                "username": str(user_data.get('login') or username),
                "email": str(user_data.get('email') or ''),
                "partner_id": partner_id,
                "student_id": student_id,
                "jenjang": jenjang,
                "course_id": course_id,
            }
        except Exception as e:
            logger.error(f"[auth] authenticate_odoo_user error: {e}")
            return None
