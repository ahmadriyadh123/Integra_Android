import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.models import RefreshToken


class RefreshTokenRepository:
    @staticmethod
    def _hash(token: str) -> str:
        return hashlib.sha256(token.encode("utf-8")).hexdigest()

    @staticmethod
    def _new_token() -> str:
        return secrets.token_urlsafe(48)

    @staticmethod
    def _expires_at() -> datetime:
        return datetime.now(timezone.utc) + timedelta(
            days=settings.REFRESH_TOKEN_EXPIRE_DAYS
        )

    async def issue(
        self,
        db: AsyncSession,
        *,
        tenant_id: int,
        user_id: int,
        claims: dict[str, Any],
    ) -> str:
        token = self._new_token()
        db.add(
            RefreshToken(
                token_hash=self._hash(token),
                tenant_id=tenant_id,
                user_id=user_id,
                claims=claims,
                expires_at=self._expires_at(),
            )
        )
        await db.commit()
        return token

    async def rotate(
        self,
        db: AsyncSession,
        *,
        token: str,
        tenant_id: int,
    ) -> tuple[str, dict[str, Any]] | None:
        result = await db.execute(
            select(RefreshToken)
            .where(
                RefreshToken.token_hash == self._hash(token),
                RefreshToken.tenant_id == tenant_id,
            )
            .with_for_update()
        )
        record = result.scalar_one_or_none()
        now = datetime.now(timezone.utc)
        if record is None or record.revoked_at is not None:
            await db.rollback()
            return None

        expires_at = record.expires_at
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)
        if expires_at <= now:
            record.revoked_at = now
            await db.commit()
            return None

        claims = dict(record.claims)
        new_token = self._new_token()
        record.revoked_at = now
        db.add(
            RefreshToken(
                token_hash=self._hash(new_token),
                tenant_id=tenant_id,
                user_id=record.user_id,
                claims=claims,
                expires_at=self._expires_at(),
            )
        )
        await db.commit()
        return new_token, claims

    async def revoke(
        self, db: AsyncSession, *, token: str, tenant_id: int
    ) -> None:
        await db.execute(
            update(RefreshToken)
            .where(
                RefreshToken.token_hash == self._hash(token),
                RefreshToken.tenant_id == tenant_id,
                RefreshToken.revoked_at.is_(None),
            )
            .values(revoked_at=datetime.now(timezone.utc))
        )
        await db.commit()
