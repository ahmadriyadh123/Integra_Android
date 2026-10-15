import xmlrpc.client
from urllib.parse import urlsplit

from odoo import _, api, fields, models
from odoo.exceptions import ValidationError


CONNECTION_TIMEOUT_SECONDS = 8


class _TimeoutTransport(xmlrpc.client.Transport):
    def make_connection(self, host):
        connection = super().make_connection(host)
        connection.timeout = CONNECTION_TIMEOUT_SECONDS
        return connection


class _TimeoutSafeTransport(xmlrpc.client.SafeTransport):
    def make_connection(self, host):
        connection = super().make_connection(host)
        connection.timeout = CONNECTION_TIMEOUT_SECONDS
        return connection


class SchoolTenant(models.Model):
    _name = "integra.school.tenant"
    _description = "Sekolah"
    _rec_name = "school_name"
    _order = "school_name"
    _sql_constraints = [
        (
            "school_code_unique",
            "unique(school_code)",
            "Kode sekolah harus unik.",
        ),
        (
            "odoo_db_unique",
            "unique(odoo_db)",
            "Nama database Odoo harus unik.",
        ),
    ]

    school_code = fields.Char(required=True, index=True, size=50)
    school_name = fields.Char(required=True, index=True, size=150)
    odoo_url = fields.Char(required=True, size=500)
    odoo_db = fields.Char(required=True, size=120)
    # This mirrors registry.school_tenants.is_active for display and local
    # validation only. The middleware registry remains the source of truth.
    active = fields.Boolean(
        string="Aktif di addon",
        default=True,
        help=(
            "Pemetaan lokal ke school_tenants.is_active. Perubahan pada "
            "field ini tidak mengubah database registry middleware."
        ),
    )

    @api.model_create_multi
    def create(self, vals_list):
        normalized_vals = [self._normalize_values(vals) for vals in vals_list]
        return super().create(normalized_vals)

    def write(self, vals):
        return super().write(self._normalize_values(vals))

    @api.model
    def _normalize_values(self, vals):
        normalized = dict(vals)
        for field_name in ("school_name", "odoo_url", "odoo_db"):
            if isinstance(normalized.get(field_name), str):
                normalized[field_name] = normalized[field_name].strip()
        if isinstance(normalized.get("school_code"), str):
            normalized["school_code"] = normalized["school_code"].strip().upper()
        if isinstance(normalized.get("odoo_url"), str):
            normalized["odoo_url"] = normalized["odoo_url"].rstrip("/")
        return normalized

    @api.constrains("odoo_url")
    def _check_odoo_url(self):
        for tenant in self:
            try:
                parsed = urlsplit(tenant.odoo_url or "")
                _ = parsed.port
            except ValueError:
                parsed = None
            if (
                parsed is None
                or parsed.scheme not in {"http", "https"}
                or not parsed.hostname
                or parsed.username
                or parsed.password
                or parsed.query
                or parsed.fragment
            ):
                raise ValidationError(
                    _("URL Odoo harus berupa alamat http/https yang valid.")
                )

    def action_check_connection(self):
        self.ensure_one()
        transport_class = (
            _TimeoutSafeTransport
            if urlsplit(self.odoo_url).scheme == "https"
            else _TimeoutTransport
        )
        common = xmlrpc.client.ServerProxy(
            f"{self.odoo_url}/xmlrpc/2/common",
            transport=transport_class(),
        )
        try:
            response = common.version()
        except (OSError, xmlrpc.client.Error) as error:
            return {
                "type": "ir.actions.client",
                "tag": "display_notification",
                "params": {
                    "title": _("Koneksi Odoo gagal"),
                    "message": str(error),
                    "type": "danger",
                    "sticky": True,
                },
            }
        finally:
            common.close()

        version = response.get("server_version") if isinstance(response, dict) else None
        message = (
            _("Server Odoo merespons dengan versi %s.") % version
            if version
            else _("Server Odoo merespons.")
        )
        return {
            "type": "ir.actions.client",
            "tag": "display_notification",
            "params": {
                "title": _("Koneksi Odoo berhasil"),
                "message": message,
                "type": "success",
                "sticky": False,
            },
        }

    def read_model_configurations(self, login, password):
        self.ensure_one()
        if not login or not password:
            raise ValidationError(
                _("Login dan password administrator Odoo tenant wajib diisi.")
            )

        parsed = urlsplit(self.odoo_url)
        if parsed.scheme != "https" and parsed.hostname not in {"localhost", "127.0.0.1"}:
            raise ValidationError(
                _("Koneksi akun administrator tenant wajib menggunakan HTTPS.")
            )

        transport_class = (
            _TimeoutSafeTransport
            if parsed.scheme == "https"
            else _TimeoutTransport
        )
        common = xmlrpc.client.ServerProxy(
            f"{self.odoo_url}/xmlrpc/2/common",
            transport=transport_class(),
        )
        try:
            uid = common.authenticate(self.odoo_db, login, password, {})
        except (OSError, xmlrpc.client.Error) as error:
            raise ValidationError(
                _("Tidak dapat mengautentikasi ke Odoo tenant: %s") % error
            ) from error
        finally:
            common.close()

        if not uid:
            raise ValidationError(
                _("Login atau password akun service ditolak oleh Odoo tenant.")
            )

        models_proxy = xmlrpc.client.ServerProxy(
            f"{self.odoo_url}/xmlrpc/2/object",
            transport=transport_class(),
        )

        def search_read(model, domain, field_names, **kwargs):
            return models_proxy.execute_kw(
                self.odoo_db,
                uid,
                password,
                model,
                "search_read",
                [domain],
                {"fields": field_names, **kwargs},
            )

        try:
            configs = search_read(
                "integra.school.model.config",
                [],
                [
                    "id",
                    "name",
                    "model_id",
                    "field_ids",
                    "relation_ids",
                    "active",
                    "notes",
                    "sequence",
                ],
                order="sequence, name",
                context={"active_test": False},
            )
            config_ids = [config["id"] for config in configs]
            relations = (
                search_read(
                    "integra.school.model.config.relation",
                    [("config_id", "in", config_ids)],
                    [
                        "id",
                        "config_id",
                        "source_field_id",
                        "relation_model",
                        "field_ids",
                        "sequence",
                    ],
                    order="sequence, id",
                )
                if config_ids
                else []
            )
            model_ids = sorted(
                {
                    config["model_id"][0]
                    for config in configs
                    if config.get("model_id")
                }
            )
            models = (
                search_read(
                    "ir.model",
                    [("id", "in", model_ids)],
                    ["id", "model", "name"],
                )
                if model_ids
                else []
            )
            field_ids = {
                field_id
                for config in configs
                for field_id in config.get("field_ids", [])
            }
            for relation in relations:
                source_field = relation.get("source_field_id")
                if source_field:
                    field_ids.add(source_field[0])
                field_ids.update(relation.get("field_ids", []))
            fields_data = (
                search_read(
                    "ir.model.fields",
                    [("id", "in", sorted(field_ids))],
                    [
                        "id",
                        "name",
                        "field_description",
                        "model",
                        "ttype",
                        "relation",
                    ],
                )
                if field_ids
                else []
            )
        except xmlrpc.client.Fault as error:
            if "Access" in error.faultString or "allowed" in error.faultString:
                raise ValidationError(
                    _(
                        "Akun Odoo tenant tidak memiliki izin baca konfigurasi "
                        "atau metadata model. Pastikan pengguna termasuk grup "
                        "Administration/Settings bawaan Odoo (base.group_system)."
                    )
                ) from error
            raise ValidationError(
                _("Odoo tenant menolak pembacaan konfigurasi: %s")
                % error.faultString
            ) from error
        except (OSError, xmlrpc.client.Error) as error:
            raise ValidationError(
                _("Gagal membaca konfigurasi dari Odoo tenant: %s") % error
            ) from error
        finally:
            models_proxy.close()

        return {
            "configs": configs,
            "relations": relations,
            "models": models,
            "fields": fields_data,
        }
