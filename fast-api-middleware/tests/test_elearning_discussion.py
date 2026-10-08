from unittest.mock import Mock

import pytest

from app.features.elearning.repository import ElearningRepository
from app.features.elearning.service import ElearningService


def test_course_messages_are_mapped_to_safe_plain_text_and_own_status():
    repository = Mock()
    repository.get_course_messages.return_value = [
        {
            "id": 13,
            "author_id": [8, "Guru"],
            "body": "Silakan lanjutkan",
            "date": "2026-10-07 08:01:00",
        },
        {
            "id": 12,
            "author_id": [7, "Siswa"],
            "body": "<p>Halo &amp; selamat belajar</p>",
            "date": "2026-10-07 08:00:00",
        },
    ]
    service = ElearningService(repository)

    messages = service.get_course_messages(
        uid=22,
        password="not-logged",
        course_id=42,
        partner_id=7,
    )

    assert messages == [
        {
            "id": 12,
            "author_name": "Siswa",
            "body": "Halo & selamat belajar",
            "created_at": "2026-10-07 08:00:00",
            "is_own": True,
        },
        {
            "id": 13,
            "author_name": "Guru",
            "body": "Silakan lanjutkan",
            "created_at": "2026-10-07 08:01:00",
            "is_own": False,
        },
    ]
    repository.get_course_messages.assert_called_once_with(
        uid=22,
        password="not-logged",
        course_id=42,
    )


def test_post_course_message_escapes_html_and_preserves_newlines():
    repository = Mock()
    repository.post_course_message.return_value = 54
    service = ElearningService(repository)

    message_id = service.post_course_message(
        uid=22,
        password="not-logged",
        course_id=42,
        body="  <script>\nPertanyaan & jawaban  ",
    )

    assert message_id == 54
    repository.post_course_message.assert_called_once_with(
        uid=22,
        password="not-logged",
        course_id=42,
        body="&lt;script&gt;<br/>Pertanyaan &amp; jawaban",
    )


def test_post_course_message_rejects_blank_text():
    service = ElearningService(Mock())

    with pytest.raises(ValueError, match="Pesan tidak boleh kosong"):
        service.post_course_message(22, "not-logged", 42, "  \n ")


def test_repository_reads_only_course_comments_and_limits_to_latest_messages():
    odoo = Mock()
    odoo.search_read.side_effect = [[{"id": 42}], [{"id": 54}]]
    repository = ElearningRepository(odoo)

    messages = repository.get_course_messages(
        uid=22,
        password="not-logged",
        course_id=42,
    )

    assert messages == [{"id": 54}]
    assert odoo.search_read.call_args_list[1].kwargs == {
        "uid": 22,
        "password": "not-logged",
        "model": "mail.message",
        "domain": [
            ("model", "=", "slide.channel"),
            ("res_id", "=", 42),
            ("message_type", "=", "comment"),
        ],
        "fields": ["id", "author_id", "body", "date"],
        "limit": 100,
        "order": "date desc, id desc",
    }


def test_repository_posts_as_a_course_comment_only_for_published_course():
    odoo = Mock()
    odoo.search_read.return_value = [{"id": 42}]
    odoo.execute_kw.return_value = 54
    repository = ElearningRepository(odoo)

    message_id = repository.post_course_message(
        uid=22,
        password="not-logged",
        course_id=42,
        body="Pertanyaan baru",
    )

    assert message_id == 54
    assert odoo.search_read.call_count == 1
    odoo.execute_kw.assert_called_once_with(
        uid=22,
        password="not-logged",
        model="slide.channel",
        method="message_post",
        args=[[42]],
        kwargs={
            "body": "Pertanyaan baru",
            "message_type": "comment",
            "subtype_xmlid": "mail.mt_comment",
        },
    )
