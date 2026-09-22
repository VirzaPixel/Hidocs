import 'package:flutter/material.dart';

import 'package:hi_docs/utils/theme_context.dart';

/// Top bar bergaya untuk halaman (Forms / Profile / History dsb).
/// Gradient + blob dekoratif + judul & subtitle, tanpa terlihat native kaku.
class PageTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> actions;
  final bool showBack;

  const PageTopBar({
    required this.title,
    this.subtitle,
    this.icon,
    this.actions = const [],
    this.showBack = false,
    super.key,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 84 : 100);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final p = context.primary;
    final pd = context.primaryDark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [pd, p],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: p.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -36,
              right: -24,
              child: _blob(120, Colors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: -30,
              left: -20,
              child: _blob(96, Colors.white.withValues(alpha: 0.06)),
            ),
            Positioned(
              top: 28,
              right: 86,
              child: _blob(10, Colors.white.withValues(alpha: 0.22)),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  showBack ? 6 : 20,
                  showBack ? 8 : 14,
                  12,
                  16,
                ),
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                      )
                    else if (icon != null) ...[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Icon(icon, size: 21, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ],
                      ),
                    ),
                    for (final a in actions)
                      IconTheme(
                        data: IconThemeData(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                        child: a,
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      );
}
