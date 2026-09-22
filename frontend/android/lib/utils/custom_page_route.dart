import 'package:flutter/material.dart';

enum PageTransitionType { slide, scaleFade, bottomSheet }

class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final PageTransitionType type;

  CustomPageRoute({
    required Widget page,
    this.type = PageTransitionType.slide,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            switch (type) {
              case PageTransitionType.scaleFade:
                final fade = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                );
                final scale = Tween<double>(begin: 0.94, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );
                return FadeTransition(
                  opacity: fade,
                  child: ScaleTransition(scale: scale, child: child),
                );
              case PageTransitionType.bottomSheet:
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                final slide = Tween<Offset>(
                  begin: const Offset(0, 0.18),
                  end: Offset.zero,
                ).animate(curved);
                final fade = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                );
                return SlideTransition(
                  position: slide,
                  child: FadeTransition(opacity: fade, child: child),
                );
              case PageTransitionType.slide:
                final slide = Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );
                final fade = CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0, 0.85, curve: Curves.easeOut),
                );
                return SlideTransition(
                  position: slide,
                  child: FadeTransition(opacity: fade, child: child),
                );
            }
          },
        );

  static CustomPageRoute forRoute(RouteSettings settings, Widget page) {
    final name = settings.name ?? '';
    const scaleFadeRoutes = {
      '/user-home',
      '/creator-home',
      '/role-select',
      '/admin-home',
      '/super-admin-home',
      '/login',
      '/register',
    };
    if (scaleFadeRoutes.contains(name)) {
      return CustomPageRoute(
        settings: settings,
        page: page,
        type: PageTransitionType.scaleFade,
      );
    }
    if (name == '/scan-form') {
      return CustomPageRoute(
        settings: settings,
        page: page,
        type: PageTransitionType.bottomSheet,
      );
    }
    return CustomPageRoute(
      settings: settings,
      page: page,
      type: PageTransitionType.slide,
    );
  }
}

class AppNavigator {
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      CustomPageRoute<T>(page: page, type: PageTransitionType.slide),
    );
  }

  static Future<T?> pushSheet<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      CustomPageRoute<T>(page: page, type: PageTransitionType.bottomSheet),
    );
  }

  static Future<T?> pushScaleFade<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      CustomPageRoute<T>(page: page, type: PageTransitionType.scaleFade),
    );
  }
}
