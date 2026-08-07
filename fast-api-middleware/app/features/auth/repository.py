import xmlrpc.client
import logging
from typing import Dict, Any, Optional
from app.core.odoo_client import OdooRPCClient

logger = logging.getLogger(__name__)


class AuthRepository:
    def __init__(self, odoo_client: OdooRPCClient):
        self.odoo = odoo_client

    def _resolve_student_id(self, uid: int, password: str, partner_id: int) -> Optional[int]:
        """
        Cari student_id (integer ID dari op.student) tanpa dot-notation.

        Urutan percobaan:
        1. Baca field 'student_id' langsung dari res.users (ada di beberapa
           konfigurasi OpenEduCat yang menambah field ke res.users).
        2. Query op.student dengan domain [('partner_id', '=', partner_id)]
           — berhasil jika user punya akses read ke op.student.
        3. Baca field 'student_ids' (Many2many) dari res.users.
        """

        # --- Cara 1: field student_id di res.users ---
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
                # Many2one dikembalikan sebagai [id, name] atau False
                if isinstance(val, list) and val:
                    logger.info(f"[auth] student_id dari res.users.student_id: {val[0]}")
                    return int(val[0])
                if isinstance(val, int) and val:
                    return val
        except Exception as e:
            logger.debug(f"[auth] res.users.student_id tidak tersedia: {e}")

        # --- Cara 2: query op.student langsung (butuh akses read) ---
        try:
            records = self.odoo.search_read(
                uid=uid, password=password,
                model='op.student',
                domain=[('partner_id', '=', partner_id)],
                fields=['id'],
                limit=1
            )
            if records:
                logger.info(f"[auth] student_id dari op.student: {records[0]['id']}")
                return int(records[0]['id'])
        except Exception as e:
            logger.debug(f"[auth] op.student tidak bisa diakses: {e}")

        # --- Cara 3: field student_ids (Many2many) di res.users ---
        try:
            records = self.odoo.search_read(
                uid=uid, password=password,
                model='res.users',
                domain=[('id', '=', uid)],
                fields=['student_ids'],
                limit=1
            )
            if records:
                val = records[0].get('student_ids')
                if isinstance(val, list) and val:
                    logger.info(f"[auth] student_id dari res.users.student_ids: {val[0]}")
                    return int(val[0])
        except Exception as e:
            logger.debug(f"[auth] res.users.student_ids tidak tersedia: {e}")

        logger.warning(
            f"[auth] Tidak bisa resolve student_id untuk uid={uid} partner_id={partner_id}. "
            "Pastikan user memiliki akses read ke op.student atau field student_id "
            "tersedia di res.users."
        )
        return None

    def authenticate_odoo_user(self, username: str, password: str) -> Optional[Dict[str, Any]]:
        """
        Verifikasi kredensial ke Odoo, lalu kumpulkan uid, partner_id,
        dan student_id untuk disimpan ke JWT.
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

            student_id = self._resolve_student_id(uid, password, partner_id) if partner_id else None

            return {
                "uid": uid,
                "name": str(user_data.get('name') or ''),
                "username": str(user_data.get('login') or username),
                "email": str(user_data.get('email') or ''),
                "partner_id": partner_id,
                "student_id": student_id,
            }
        except Exception as e:
            logger.error(f"[auth] authenticate_odoo_user error: {e}")
            return None
