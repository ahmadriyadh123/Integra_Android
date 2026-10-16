from odoo import _, http
from odoo.exceptions import AccessError, UserError
from odoo.http import request


class SchoolAdminController(http.Controller):
    @http.route(
        "/integra_school_admin/tenant/configurations",
        type="json",
        auth="user",
        methods=["POST"],
        csrf=False,
    )
    def tenant_configurations(self, tenant_id=None, login=None, password=None):
        if not request.env.user.has_group("base.group_system"):
            raise AccessError(
                _("Only Odoo administrators can access tenant configurations.")
            )
        if not isinstance(tenant_id, int) or tenant_id <= 0:
            raise UserError(_("Select a valid school tenant."))

        tenant = request.env["school.tenant"].browse(tenant_id).exists()
        if not tenant or not tenant.active:
            raise UserError(_("The selected school tenant is missing or archived."))

        return tenant.read_model_configurations(login, password)
