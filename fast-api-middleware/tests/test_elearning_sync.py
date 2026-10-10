from datetime import datetime, timezone
from unittest.mock import Mock

from app.features.elearning.repository import ElearningRepository
from app.features.elearning.service import ElearningService


def test_course_sync_without_cursor_returns_full_snapshot():
    repository = Mock()
    repository.get_published_courses.return_value = [
        {
            "id": 5,
            "name": "Matematika",
            "user_id": [3, "Guru"],
            "total_slides": 2,
            "description": "",
        }
    ]
    repository.get_progress_by_course.return_value = {5: {10}}

    result = ElearningService(repository).get_courses_sync(
        uid=22,
        password="secret",
        partner_id=7,
        cursor=None,
    )

    assert result["full_sync"] is True
    assert result["removed_ids"] == []
    assert result["items"][0]["completed_slides"] == 1
    assert result["items"][0]["progress_percent"] == 50
    assert result["next_cursor"].endswith("Z")
    repository.get_course_sync_changes.assert_not_called()


def test_course_sync_returns_only_modified_courses_and_removals():
    repository = Mock()
    repository.get_course_sync_changes.return_value = (
        [
            {
                "id": 6,
                "name": "IPA",
                "user_id": [3, "Guru"],
                "total_slides": 4,
                "description": "",
            }
        ],
        [5],
    )
    repository.get_progress_by_course.return_value = {6: {12, 13}}
    cursor = datetime(2026, 10, 1, tzinfo=timezone.utc)

    result = ElearningService(repository).get_courses_sync(
        uid=22,
        password="secret",
        partner_id=7,
        cursor=cursor,
    )

    assert result["full_sync"] is False
    assert [course["id"] for course in result["items"]] == [6]
    assert result["items"][0]["progress_percent"] == 50
    assert result["removed_ids"] == [5]
    repository.get_course_sync_changes.assert_called_once_with(
        uid=22,
        password="secret",
        partner_id=7,
        modified_after="2026-09-30 23:58:00",
    )


def test_repository_collects_courses_changed_by_channel_slide_and_progress():
    odoo = Mock()
    odoo.search_read.side_effect = [
        [{"id": 5}],
        [{"id": 10, "channel_id": [7, "IPA"]}],
        [{"slide_id": [11, "Bab"]}],
        [{"channel_id": [6, "Matematika"]}, {"channel_id": [7, "IPA"]}],
        [
            {"id": 5, "is_published": False},
            {"id": 6, "is_published": True},
            {"id": 7, "is_published": True},
        ],
    ]
    repository = ElearningRepository(odoo)

    courses, removed_ids = repository.get_course_sync_changes(
        uid=22,
        password="secret",
        partner_id=9,
        modified_after="2026-10-01 00:00:00",
    )

    assert [course["id"] for course in courses] == [6, 7]
    assert removed_ids == [5]
    assert odoo.search_read.call_count == 5
