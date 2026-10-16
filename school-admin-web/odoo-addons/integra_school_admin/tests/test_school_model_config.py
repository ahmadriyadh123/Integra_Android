from odoo.exceptions import ValidationError
from odoo.tests import TransactionCase


class TestSchoolModelConfig(TransactionCase):
    def test_create_model_config_with_relation_and_selected_fields(self):
        model = self.env["ir.model"]._get("res.users")
        partner_field = self.env["ir.model.fields"].search(
            [("model_id", "=", model.id), ("name", "=", "partner_id")],
            limit=1,
        )
        user_name_field = self.env["ir.model.fields"].search(
            [("model_id", "=", model.id), ("name", "=", "name")],
            limit=1,
        )
        partner_email_field = self.env["ir.model.fields"].search(
            [("model", "=", "res.partner"), ("name", "=", "email")],
            limit=1,
        )

        config = self.env["school.model.config"].create(
            {
                "name": "Profil akun",
                "model_id": model.id,
                "field_ids": [(6, 0, user_name_field.ids)],
                "relation_ids": [
                    (
                        0,
                        0,
                        {
                            "source_field_id": partner_field.id,
                            "field_ids": [(6, 0, partner_email_field.ids)],
                        },
                    )
                ],
            }
        )

        self.assertEqual(config.model_id.model, "res.users")
        self.assertEqual(config.field_ids, user_name_field)
        self.assertEqual(config.relation_ids.source_field_id, partner_field)
        self.assertEqual(config.relation_ids.relation_model, "res.partner")
        self.assertEqual(config.relation_ids.field_ids, partner_email_field)

    def test_rejects_selected_field_from_another_model(self):
        users_model = self.env["ir.model"]._get("res.users")
        partner_name = self.env["ir.model.fields"].search(
            [("model", "=", "res.partner"), ("name", "=", "name")],
            limit=1,
        )

        with self.assertRaises(ValidationError):
            self.env["school.model.config"].create(
                {
                    "name": "Konfigurasi tidak valid",
                    "model_id": users_model.id,
                    "field_ids": [(6, 0, partner_name.ids)],
                }
            )

    def test_rejects_relation_to_field_from_unrelated_model(self):
        users_model = self.env["ir.model"]._get("res.users")
        partner_field = self.env["ir.model.fields"].search(
            [("model_id", "=", users_model.id), ("name", "=", "partner_id")],
            limit=1,
        )
        user_name = self.env["ir.model.fields"].search(
            [("model", "=", "res.users"), ("name", "=", "name")],
            limit=1,
        )

        with self.assertRaises(ValidationError):
            self.env["school.model.config"].create(
                {
                    "name": "Konfigurasi relasi tidak valid",
                    "model_id": users_model.id,
                    "relation_ids": [
                        (
                            0,
                            0,
                            {
                                "source_field_id": partner_field.id,
                                "field_ids": [(6, 0, user_name.ids)],
                            },
                        )
                    ],
                }
            )
