{
    "name": "Integra School Admin",
    "summary": "Kelola direktori tenant sekolah dan koneksi Odoo",
    "version": "1.1.0",
    "category": "Administration",
    "license": "LGPL-3",
    "author": "Integra",
    "depends": ["base"],
    "data": [
        "security/ir.model.access.csv",
        "views/school_tenant_views.xml",
        "views/school_model_config_views.xml",
    ],
    "application": True,
    "installable": True,
}
