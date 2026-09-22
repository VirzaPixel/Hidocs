import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/l10n/app_localizations.dart';

class CodeBlockWidget extends StatelessWidget {
  final String code;
  final String language;

  const CodeBlockWidget({
    required this.code,
    this.language = 'code',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:        const Color(0xFF13192B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF252D40)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF1A2236),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            _dot(const Color(0xFFFF5F57)),
            const SizedBox(width: 6),
            _dot(const Color(0xFFFFBD2E)),
            const SizedBox(width: 6),
            _dot(const Color(0xFF28C840)),
            const Spacer(),
            Text(language, style: const TextStyle(
                color: Color(0xFF6B7A99), fontSize: 12,
                fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(AppLocalizations.of(context).copied),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ));
              },
              child: const Icon(Icons.copy_rounded,
                  size: 15, color: Color(0xFF6B7A99)),
            ),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(18),
          child: SelectableText(
            code,
            style: const TextStyle(
              color:      Color(0xFFA8D8EA),
              fontSize:   13.5,
              fontFamily: 'monospace',
              height:     1.65,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _dot(Color c) => Container(
      width: 10, height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c));
}
