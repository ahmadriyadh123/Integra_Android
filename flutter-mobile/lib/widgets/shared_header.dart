import 'package:flutter/material.dart';

class SharedHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool centerTitle;
  final Color backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const SharedHeader({
    Key? key,
    this.title,
    this.titleWidget,
    this.centerTitle = true,
    this.backgroundColor = Colors.white,
    this.foregroundColor,
    this.elevation = 0,
    this.showBackButton = false,
    this.onBack,
    this.actions,
    this.bottom,
  })  : assert(title != null || titleWidget != null, 'Provide title or titleWidget'),
        super(key: key);

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? const Color(0xFF0F172A);
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: fg, size: 18),
              onPressed: onBack ?? () => Navigator.maybePop(context),
            )
          : null,
      title: titleWidget ?? Text(
        title!,
        style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w800),
      ),
      actions: actions,
      bottom: bottom,
      foregroundColor: fg,
    );
  }
}
