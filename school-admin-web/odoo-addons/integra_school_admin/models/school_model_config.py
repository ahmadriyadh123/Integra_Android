from odoo import _, api, fields, models
from odoo.exceptions import ValidationError


RELATIONAL_FIELD_TYPES = ("many2one", "one2many", "many2many")


class SchoolModelConfig(models.Model):
    _name = "integra.school.model.config"
    _description = "Konfigurasi Model Sekolah"
    _rec_name = "name"
    _order = "name"
    _sql_constraints = [
        (
            "model_id_unique",
            "unique(model_id)",
            "Setiap model hanya boleh memiliki satu konfigurasi.",
        ),
    ]

    sequence = fields.Integer(default=10)
    name = fields.Char(required=True, index=True)
    model_id = fields.Many2one(
        "ir.model",
        string="Model Odoo",
        required=True,
        ondelete="restrict",
        domain=[("transient", "=", False)],
    )
    field_ids = fields.Many2many(
        "ir.model.fields",
        "integra_school_model_config_field_rel",
        "config_id",
        "field_id",
        string="Field terpilih",
        domain="[('model_id', '=', model_id)]",
    )
    relation_ids = fields.One2many(
        "integra.school.model.config.relation",
        "config_id",
        string="Relasi",
    )
    active = fields.Boolean(default=True)
    notes = fields.Text(string="Catatan")

    @api.constrains("model_id", "field_ids")
    def _check_selected_fields(self):
        for config in self:
            invalid_fields = config.field_ids.filtered(
                lambda field: field.model_id != config.model_id
            )
            if invalid_fields:
                raise ValidationError(
                    _("Semua field terpilih harus berasal dari model yang dipilih.")
                )


class SchoolModelConfigRelation(models.Model):
    _name = "integra.school.model.config.relation"
    _description = "Relasi Konfigurasi Model Sekolah"
    _order = "sequence, id"

    sequence = fields.Integer(default=10)
    config_id = fields.Many2one(
        "integra.school.model.config",
        string="Konfigurasi model",
        required=True,
        ondelete="cascade",
    )
    source_field_id = fields.Many2one(
        "ir.model.fields",
        string="Field relasi",
        required=True,
        ondelete="restrict",
        domain=(
            "[('model_id', '=', parent.model_id), "
            "('ttype', 'in', ['many2one', 'one2many', 'many2many'])]"
        ),
    )
    relation_model = fields.Char(
        string="Model tujuan",
        related="source_field_id.relation",
        readonly=True,
    )
    field_ids = fields.Many2many(
        "ir.model.fields",
        "integra_school_model_config_relation_field_rel",
        "relation_config_id",
        "field_id",
        string="Field model tujuan",
        domain="[('model', '=', relation_model)]",
    )

    @api.constrains("config_id", "source_field_id", "field_ids")
    def _check_relation_fields(self):
        for relation in self:
            source_field = relation.source_field_id
            if source_field.model_id != relation.config_id.model_id:
                raise ValidationError(
                    _("Field relasi harus berasal dari model konfigurasi.")
                )
            if source_field.ttype not in RELATIONAL_FIELD_TYPES or not source_field.relation:
                raise ValidationError(
                    _("Field relasi harus berupa field relasional dengan model tujuan.")
                )
            invalid_fields = relation.field_ids.filtered(
                lambda field: field.model != source_field.relation
            )
            if invalid_fields:
                raise ValidationError(
                    _("Field tujuan harus berasal dari model relasi yang dipilih.")
                )
