import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';

class CustomInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  const CustomInput({
    required this.controller,
    required this.label,
    this.hint = '',
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText   = false,
    this.maxLines      = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
      const SizedBox(height: 7),
      TextFormField(
        controller:        controller,
        obscureText:       obscureText,
        maxLines:          obscureText ? 1 : maxLines,
        keyboardType:      keyboardType,
        inputFormatters:   inputFormatters,
        validator:         validator,
        onChanged:         onChanged,
        readOnly:          readOnly,
        onTap:             onTap,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText:   hint,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 20,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)
              : null,
          suffixIcon: suffixIcon,
          filled:     true,
          fillColor:  isDark ? AppTheme.darkSurface : AppTheme.surfaceCard,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: isDark ? const Color(0xFF4A90D9) : context.primary,
                  width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.error)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.error, width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
              fontWeight: FontWeight.w400),
          errorStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    ]);
  }
}
