import 'package:flutter/material.dart';
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

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.primary, theme.primaryDark],
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}
