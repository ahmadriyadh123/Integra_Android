def migrate(cr, version):
    cr.execute(
        """
        SELECT res_id
          FROM ir_model_data
         WHERE module = %s
           AND name = %s
        """,
        ("integra_school_admin", "menu_integra_school_model_config"),
    )
    menu = cr.fetchone()
    if menu:
        cr.execute("DELETE FROM ir_ui_menu WHERE id = %s", (menu[0],))

    cr.execute(
        """
        DELETE FROM ir_model_data
         WHERE module = %s
           AND name = %s
        """,
        ("integra_school_admin", "menu_integra_school_model_config"),
    )
