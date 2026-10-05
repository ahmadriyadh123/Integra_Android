import logging
import xmlrpc.client
from unittest.mock import Mock

import pytest

from app.features.elearning.repository import ElearningRepository


def test_scorm_attachment_fault_logs_context_without_credentials(caplog):
    odoo = Mock()
    odoo.db = "school_db"
    odoo.search_read.side_effect = xmlrpc.client.Fault(
        4, "Sorry, you are not allowed to access this document."
    )
    repository = ElearningRepository(odoo)

    with caplog.at_level(logging.ERROR):
        with pytest.raises(xmlrpc.client.Fault):
            repository.get_scorm_attachment(
                uid=42,
                password="must-not-be-logged",
                slide_id=321,
            )

    assert "db=school_db" in caplog.text
    assert "uid=42" in caplog.text
    assert "slide_id=321" in caplog.text
    assert "model=ir.attachment" in caplog.text
    assert "method=search_read" in caplog.text
    assert "fault_code=4" in caplog.text
    assert "must-not-be-logged" not in caplog.text
    odoo.search_read.assert_called_once_with(
        uid=42,
        password="must-not-be-logged",
        model="ir.attachment",
        domain=[("res_model", "=", "slide.slide"), ("res_id", "=", 321)],
        fields=["id", "name", "datas", "mimetype"],
        limit=1,
        use_sudo=False,
    )