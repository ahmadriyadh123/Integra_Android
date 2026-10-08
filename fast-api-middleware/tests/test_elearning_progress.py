from unittest.mock import Mock

from app.features.elearning.repository import ElearningRepository
from app.features.elearning.service import ElearningService


def test_course_detail_maps_student_completion_to_slides_and_percentage():
    repository = Mock()
    repository.get_course_by_id.return_value = {
        "id": 5,
        "name": "Matematika",
        "user_id": [3, "Guru"],
        "description": "",
        "total_slides": 2,
    }
    repository.get_slides_by_course_id.return_value = [
        {"id": 10, "name": "Bab 1", "sequence": 1},
        {"id": 11, "name": "Bab 2", "sequence": 2},
    ]
    repository.get_completed_slide_ids.return_value = {10}
    service = ElearningService(repository)

    course = service.get_course_detail(22, "secret", 5, partner_id=7)

    assert course["completed_slides"] == 1
    assert course["progress_percent"] == 50
    assert [slide["is_completed"] for slide in course["slides"]] == [True, False]
    repository.get_completed_slide_ids.assert_called_once_with(22, "secret", 5, 7)


def test_course_list_progress_is_scoped_to_student_and_course_ids():
    repository = Mock()
    repository.get_published_courses.return_value = [
        {
            "id": 5,
            "name": "Matematika",
            "user_id": [3, "Guru"],
            "total_slides": 4,
            "description": "",
        }
    ]
    repository.get_progress_by_course.return_value = {5: {10, 11}, 99: {20}}

    courses = ElearningService(repository).get_courses_list(
        22,
        "secret",
        partner_id=7,
    )

    assert courses[0]["completed_slides"] == 2
    assert courses[0]["progress_percent"] == 50
    repository.get_progress_by_course.assert_called_once_with(22, "secret", 7)


def test_repository_creates_native_odoo_completion_record():
    odoo = Mock()
    odoo.search_read.side_effect = [
        [{"id": 10, "slide_type": "document", "slide_category": "document"}],
        [],
    ]
    odoo.execute_kw.return_value = 45
    repository = ElearningRepository(odoo)

    assert repository.mark_slide_completed(
        uid=22,
        password="secret",
        course_id=5,
        slide_id=10,
        partner_id=7,
        source="opened",
    )

    odoo.execute_kw.assert_called_once_with(
        uid=22,
        password="secret",
        model="slide.slide.partner",
        method="create",
        args=[{"slide_id": 10, "partner_id": 7, "completed": True}],
    )


def test_repository_does_not_mark_scorm_complete_when_only_opened():
    odoo = Mock()
    odoo.search_read.return_value = [
        {"id": 10, "slide_type": "scorm", "slide_category": "scorm"}
    ]
    repository = ElearningRepository(odoo)

    assert not repository.mark_slide_completed(
        uid=22,
        password="secret",
        course_id=5,
        slide_id=10,
        partner_id=7,
        source="opened",
    )
    odoo.execute_kw.assert_not_called()


def test_repository_does_not_mark_quiz_complete_when_opened():
    odoo = Mock()
    odoo.search_read.return_value = [
        {"id": 10, "slide_type": "quiz", "slide_category": "quiz"}
    ]
    repository = ElearningRepository(odoo)

    assert not repository.mark_slide_completed(
        uid=22,
        password="secret",
        course_id=5,
        slide_id=10,
        partner_id=7,
        source="opened",
    )
    odoo.execute_kw.assert_not_called()
