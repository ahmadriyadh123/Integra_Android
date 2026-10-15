def migrate(cr, version):
    group_names = ("group_school_admin_manager", "group_school_config_reader")
    cr.execute(
        """
        SELECT res_id
          FROM ir_model_data
         WHERE module = %s
           AND model = %s
           AND name = ANY(%s)
        """,
        ("integra_school_admin", "res.groups", list(group_names)),
    )
    group_ids = [row[0] for row in cr.fetchall()]

    cr.execute(
        """
        SELECT res_id
          FROM ir_model_data
         WHERE module = %s
           AND model = %s
           AND name = %s
        """,
        ("integra_school_admin", "ir.module.category", "module_category_integra_school_admin"),
    )
    category_ids = [row[0] for row in cr.fetchall()]

    if group_ids:
        cr.execute(
            """
            DELETE FROM ir_model_data
             WHERE module = %s
               AND model = %s
               AND res_id IN (
                   SELECT id FROM ir_model_access WHERE group_id = ANY(%s)
               )
            """,
            ("integra_school_admin", "ir.model.access", group_ids),
        )
        cr.execute(
            "DELETE FROM ir_model_access WHERE group_id = ANY(%s)",
            (group_ids,),
        )
        cr.execute(
            "DELETE FROM res_groups_users_rel WHERE gid = ANY(%s)",
            (group_ids,),
        )
        cr.execute(
            """
            DELETE FROM res_groups_implied_rel
             WHERE gid = ANY(%s) OR hid = ANY(%s)
            """,
            (group_ids, group_ids),
        )
        cr.execute(
            "DELETE FROM ir_ui_menu_group_rel WHERE gid = ANY(%s)",
            (group_ids,),
        )
        cr.execute(
            """
            DELETE FROM ir_model_data
             WHERE module = %s AND model = %s AND name = ANY(%s)
            """,
            ("integra_school_admin", "res.groups", list(group_names)),
        )
        cr.execute("DELETE FROM res_groups WHERE id = ANY(%s)", (group_ids,))

    if category_ids:
        cr.execute(
            """
            DELETE FROM ir_model_data
             WHERE module = %s
               AND model = %s
               AND name = %s
            """,
            (
                "integra_school_admin",
                "ir.module.category",
                "module_category_integra_school_admin",
            ),
        )
        cr.execute(
            """
            DELETE FROM ir_module_category
             WHERE id = ANY(%s)
               AND NOT EXISTS (
                   SELECT 1 FROM res_groups WHERE category_id = ir_module_category.id
               )
            """,
            (category_ids,),
        )
