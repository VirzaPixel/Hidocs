import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/providers/theme_provider.dart';

class DynamicHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DynamicHeader({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Stack(
          children: [
            // Gradient harus menutupi area status bar (icon baterai/jam tetap
            // terbaca di atasnya) — persis seperti PageTopBar pada halaman
            // Riwayat / Profile / Forms.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.primaryDark, theme.primary],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            // Konten digeser oleh SafeArea (bukan oleh padding container)
            // supaya tinggi header konsisten dengan PageTopBar.
            SafeArea(
              bottom: false,
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
