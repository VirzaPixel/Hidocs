import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/widgets/common/custom_button.dart';
import 'package:hi_docs/screens/forms/user_form_detail_screen.dart';
import 'package:hi_docs/screens/exam/scan_form_screen.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/utils/custom_page_route.dart';

class LinkInputScreen extends StatefulWidget {
  const LinkInputScreen({super.key});

  @override
  State<LinkInputScreen> createState() => _LinkInputScreenState();
}

class _LinkInputScreenState extends State<LinkInputScreen> {
  final TextEditingController _linkController = TextEditingController();
  final FocusNode _linkFocus = FocusNode();

  bool _isResolving = false;
  bool _hasHandled = false;

  @override
  void dispose() {
    _linkController.dispose();
    _linkFocus.dispose();
    super.dispose();
  }

  Future<void> _resolveLink() async {
    if (_isResolving || _hasHandled) return;

    final l10n = AppLocalizations.of(context);

    final raw = _linkController.text.trim();
    _linkFocus.unfocus();

    if (raw.isEmpty) {
      _showMessage(
        l10n.enterLinkFirst,
        isError: true,
      );
      return;
    }

    final code = extractFormCode(raw);
    if (code.isEmpty) {
      _showMessage(
        l10n.scanFailed,
        isError: true,
      );
      return;
    }

    setState(() {
      _isResolving = true;
    });

    final formProvider = context.read<FormProvider>();
    final form = await formProvider.loadPublicForm(code);

    if (!mounted) return;

    setState(() {
      _isResolving = false;
    });

    if (form == null) {
      _showMessage(
        formProvider.error ?? l10n.formNotFound,
        isError: true,
      );
      return;
    }

    if (formProvider.hasSubmitted(form.id)) {
      _showMessage(
        l10n.alreadySubmitted,
        isError: false,
      );
      return;
    }

    _hasHandled = true;

    await Navigator.push(
      context,
      CustomPageRoute(page: UserFormDetailScreen(form: form),
      ),
    );

    _hasHandled = false;
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.info_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Mengambil warna header/primary tema yang aktif
    final headerColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(l10n.linkInput),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: headerColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.link_rounded,
                  size: 38,
                  color: headerColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.enterFormLink,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.pasteLinkToOpen,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _linkController,
                focusNode: _linkFocus,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _resolveLink(),
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'hidocs.app/f/<slug> atau URL',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.qr_code_2_rounded,
                    size: 20,
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.darkCard
                      : AppTheme.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppTheme.darkBorder : AppTheme.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: headerColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: headerColor,
                        ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: headerColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    filledButtonTheme: FilledButtonThemeData(
                      style: FilledButton.styleFrom(
                        backgroundColor: headerColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  child: CustomButton(
                text: 'Buka Form',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: _isResolving,
                    onPressed: _resolveLink,
                    height: 52,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}