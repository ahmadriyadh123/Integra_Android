from odoo.exceptions import ValidationError
from odoo.tests import TransactionCase


class TestSchoolTenant(TransactionCase):
    def test_create_normalizes_code_and_text(self):
        tenant = self.env["school.tenant"].create(
            {
                "school_code": " sdn-001 ",
                "school_name": " SD Negeri 1 ",
                "odoo_url": " https://odoo.example.test/ ",
                "odoo_db": " sekolah_db ",
            }
        )

        self.assertEqual(tenant.school_code, "SDN-001")
        self.assertEqual(tenant.school_name, "SD Negeri 1")
        self.assertEqual(tenant.odoo_url, "https://odoo.example.test")
        self.assertEqual(tenant.odoo_db, "sekolah_db")

    def test_rejects_invalid_odoo_url(self):
        for invalid_url in (
            "ftp://odoo.example.test",
            "https://odoo.example.test:99999",
            "https://odoo.example.test/?database=other",
        ):
            with self.subTest(url=invalid_url), self.assertRaises(ValidationError):
                self.env["school.tenant"].create(
                    {
                        "school_code": "SDN-002",
                        "school_name": "SD Negeri 2",
                        "odoo_url": invalid_url,
                        "odoo_db": "sekolah_db_2",
                    }
                )

    def test_rejects_duplicate_odoo_database(self):
        values = {
            "school_code": "SDN-003",
            "school_name": "SD Negeri 3",
            "odoo_url": "https://odoo.example.test",
            "odoo_db": "sekolah_db_3",
        }
        self.env["school.tenant"].create(values)

        with self.assertRaises(ValidationError):
            self.env["school.tenant"].create(
                dict(values, school_code="SDN-004", school_name="SD Negeri 4")
            )
