from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, Mock

import pytest

from app.core.models import RefreshToken
from app.features.auth.refresh_tokens import RefreshTokenRepository


@pytest.mark.asyncio
async def test_issue_persists_only_a_hash_of_the_refresh_token():
    db = Mock()
    db.add = Mock()
    db.commit = AsyncMock()
    repository = RefreshTokenRepository()

    token = await repository.issue(
        db,
        tenant_id=3,
        user_id=42,
        claims={"uid": 42, "school_id": 3},
    )

    record = db.add.call_args.args[0]
    assert isinstance(record, RefreshToken)
    assert record.token_hash != token
    assert len(record.token_hash) == 64
    assert record.tenant_id == 3
    assert record.user_id == 42
    assert record.claims == {"uid": 42, "school_id": 3}
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_rotate_revokes_previous_token_and_issues_a_new_one():
    old_token = "old-refresh-token"
    record = RefreshToken(
        token_hash=RefreshTokenRepository._hash(old_token),
        tenant_id=3,
        user_id=42,
        claims={"uid": 42, "school_id": 3},
        expires_at=datetime.now(timezone.utc) + timedelta(days=1),
    )
    db = Mock()
    db.add = Mock()
    db.commit = AsyncMock()
    db.rollback = AsyncMock()
    db.execute = AsyncMock(
        return_value=Mock(scalar_one_or_none=Mock(return_value=record))
    )

    rotated = await RefreshTokenRepository().rotate(
        db,
        token=old_token,
        tenant_id=3,
    )

    assert rotated is not None
    new_token, claims = rotated
    new_record = db.add.call_args.args[0]
    assert new_token != old_token
    assert new_record.token_hash != new_token
    assert new_record.token_hash != record.token_hash
    assert claims == record.claims
    assert record.revoked_at is not None
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_rotate_rejects_replayed_or_unknown_tokens():
    db = Mock()
    db.add = Mock()
    db.commit = AsyncMock()
    db.rollback = AsyncMock()
    db.execute = AsyncMock(
        return_value=Mock(scalar_one_or_none=Mock(return_value=None))
    )

    rotated = await RefreshTokenRepository().rotate(
        db,
        token="already-used-token",
        tenant_id=3,
    )

    assert rotated is None
    db.rollback.assert_awaited_once()
    db.add.assert_not_called()


@pytest.mark.asyncio
async def test_rotate_revokes_expired_token_without_issuing_another():
    record = RefreshToken(
        token_hash=RefreshTokenRepository._hash("expired-token"),
        tenant_id=3,
        user_id=42,
        claims={"uid": 42, "school_id": 3},
        expires_at=datetime.now(timezone.utc) - timedelta(seconds=1),
    )
    db = Mock()
    db.add = Mock()
    db.commit = AsyncMock()
    db.rollback = AsyncMock()
    db.execute = AsyncMock(
        return_value=Mock(scalar_one_or_none=Mock(return_value=record))
    )

    rotated = await RefreshTokenRepository().rotate(
        db,
        token="expired-token",
        tenant_id=3,
    )

    assert rotated is None
    assert record.revoked_at is not None
    db.add.assert_not_called()
    db.commit.assert_awaited_once()
