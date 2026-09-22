import 'package:flutter/material.dart';
import 'package:hi_docs/app_theme.dart';

enum ButtonType { primary, outlined, danger, success }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final double height;
  final Color? color;

  const CustomButton({
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.fullWidth = false,
    this.icon,
    this.height = 50,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themePrimary = Theme.of(context).colorScheme.primary;

    Color bgColor;
    Color fgColor = Colors.white;
    Color bdColor = Colors.transparent;
    bool outlined = false;

    switch (type) {
      case ButtonType.primary:
        bgColor = color ?? themePrimary;
        break;

      case ButtonType.danger:
        bgColor = AppTheme.error;
        break;

      case ButtonType.success:
        bgColor = AppTheme.success;
        break;

      case ButtonType.outlined:
        bgColor = Colors.transparent;
        fgColor = color ?? themePrimary;
        bdColor = color ?? themePrimary;
        outlined = true;
        break;
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: outlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: fgColor,
                side: BorderSide(
                  color: bdColor,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: _content(fgColor),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: fgColor,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: _content(fgColor),
            ),
    );
  }

  Widget _content(Color fgColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: fgColor,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon!,
            size: 18,
            color: fgColor,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: fgColor,
          ),
        ),
      ],
    );
  }
}