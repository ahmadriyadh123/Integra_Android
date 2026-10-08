import logging
from typing import Optional, Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from passlib.context import CryptContext

logger = logging.getLogger(__name__)

# Context untuk verifikasi hash password Odoo (PBKDF2 / Bcrypt / Plaintext)
pwd_context = CryptContext(
    schemes=["pbkdf2_sha512", "bcrypt", "plaintext"],
    deprecated="auto"
)

class AuthRepository:
    def __init__(self, db_session: AsyncSession):
        self.db = db_session

    async def get_user_by_login(self, login: str) -> Optional[Dict[str, Any]]:
        """
        Get user data by login/email tanpa verifikasi password.
        Digunakan untuk cek user existence.
        """
        query = text("""
            SELECT 
                u.id AS user_id,
                u.login,
                u.password AS password_hash,
                u.active,
                p.id AS partner_id,
                p.name AS full_name,
                p.email,
                s.id AS student_id,
                s.nis AS nis
            FROM res_users u
            JOIN res_partner p ON p.id = u.partner_id
            LEFT JOIN op_student s ON s.user_id = u.id
            WHERE u.login = :login AND u.active = TRUE
            LIMIT 1;
        """)
        
        result = await self.db.execute(query, {"login": login})
        user = result.mappings().first()
        return dict(user) if user else None

    async def authenticate_user(self, login: str, password_plain: str) -> Optional[Dict[str, Any]]:
        """
        Memverifikasi kredensial user langsung dari tabel res_users database.
        """
        # Cek user ada atau tidak
        user = await self.get_user_by_login(login)
        
        if not user:
            logger.error(f"[auth] User dengan login '{login}' tidak ditemukan di DB")
            return None

        # Verifikasi password
        if not user["password_hash"] or not pwd_context.verify(password_plain, user["password_hash"]):
            logger.error(f"[auth] Hash password tidak cocok untuk user '{login}'")
            return None

        # Ambil daftar Group ID
        groups = await self.get_user_groups(user["user_id"])

        return {
            "user_id": user["user_id"],
            "login": user["login"],
            "partner_id": user["partner_id"],
            "name": user["full_name"],
            "email": user["email"],
            "student_id": user["student_id"],
            "nis": user["nis"],
            "groups": groups,
            "is_portal": 10 in groups  # Contoh: ID 10 adalah grup portal
        }

    async def get_user_groups(self, user_id: int) -> List[int]:
        query = text("""
            SELECT gid 
            FROM res_groups_users_rel 
            WHERE uid = :user_id;
        """)
        result = await self.db.execute(query, {"user_id": user_id})
        return [row[0] for row in result.fetchall()]

    async def change_password(self, user_id: int, current_password: str, new_password: str) -> bool:
        user_query = text("SELECT password FROM res_users WHERE id = :user_id AND active = TRUE LIMIT 1")
        result = await self.db.execute(user_query, {"user_id": user_id})
        user = result.mappings().first()
        if not user or not user["password"] or not pwd_context.verify(current_password, user["password"]):
            return False

        update_query = text("UPDATE res_users SET password = :password WHERE id = :user_id")
        await self.db.execute(
            update_query,
            {"password": pwd_context.hash(new_password), "user_id": user_id},
        )
        await self.db.commit()
        return True

    async def get_user_profile_by_id(self, user_id: int) -> Optional[Dict[str, Any]]:
        query = text("""
            SELECT 
                u.id AS user_id,
                u.login,
                u.password AS password_hash,
                u.active,
                p.id AS partner_id,
                p.name AS full_name,
                p.email,
                s.id AS student_id,
                s.nis AS nis  -- Menggunakan kolom s.nis menggantikan s.gr_no
            FROM res_users u
            JOIN res_partner p ON p.id = u.partner_id
            LEFT JOIN op_student s ON s.user_id = u.id
            WHERE u.login = :login AND u.active = TRUE
            LIMIT 1;
        """)
        result = await self.db.execute(query, {"user_id": user_id})
        row = result.mappings().first()
        return dict(row) if row else None