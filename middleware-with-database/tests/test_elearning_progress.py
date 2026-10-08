import pytest
from unittest.mock import AsyncMock

from app.features.elearning.repository import ElearningRepository


class Result:
    def __init__(self, row=None):
        self.row = row

    def mappings(self):
        return self

    def first(self):
        return self.row


@pytest.mark.asyncio
async def test_progress_write_upserts_only_valid_opened_non_scorm_slide():
    db = AsyncMock()
    db.execute.side_effect = [
        Result({"slide_type": "document", "slide_category": "document"}),
        Result(),
    ]
    repository = ElearningRepository(db)

    assert await repository.mark_slide_completed(
        course_id=5,
        slide_id=10,
        partner_id=7,
        source="opened",
    )
    assert db.execute.await_count == 2
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_scorm_requires_player_completion_status():
    db = AsyncMock()
    db.execute.return_value = Result(
        {"slide_type": "scorm", "slide_category": "scorm"}
    )
    repository = ElearningRepository(db)

    assert not await repository.mark_slide_completed(
        course_id=5,
        slide_id=10,
        partner_id=7,
        source="scorm",
        completion_status="incomplete",
    )
    assert db.execute.await_count == 1
    db.commit.assert_not_awaited()
