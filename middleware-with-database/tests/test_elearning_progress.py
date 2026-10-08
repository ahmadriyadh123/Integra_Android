import pytest
from unittest.mock import AsyncMock, Mock

from app.features.elearning.repository import ElearningRepository
from app.features.elearning.service import ElearningService


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


@pytest.mark.asyncio
async def test_quiz_is_not_completed_by_opening_it():
    db = AsyncMock()
    db.execute.return_value = Result(
        {"slide_type": "quiz", "slide_category": "quiz"}
    )
    repository = ElearningRepository(db)

    assert not await repository.mark_slide_completed(
        course_id=5,
        slide_id=10,
        partner_id=7,
        source="opened",
    )
    assert db.execute.await_count == 1
    db.commit.assert_not_awaited()


@pytest.mark.asyncio
async def test_course_progress_uses_only_completed_slides_in_returned_course():
    repository = Mock()
    repository.get_published_courses = AsyncMock(
        return_value=[
            {
                "id": 5,
                "name": "Matematika",
                "teacher_name": "Guru",
                "total_slides": 4,
                "completed_slides": 2,
                "description": "",
            }
        ]
    )
    courses = await ElearningService(repository).get_courses_list(partner_id=7)

    assert courses[0]["completed_slides"] == 2
    assert courses[0]["progress_percent"] == 50
    repository.get_published_courses.assert_awaited_once_with(partner_id=7)
