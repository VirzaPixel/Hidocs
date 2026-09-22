import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/providers/theme_provider.dart';
import 'package:hi_docs/providers/language_provider.dart';
import 'package:hi_docs/widgets/common/gradient_button.dart';
import 'package:hi_docs/widgets/common/page_top_bar.dart';
import 'package:hi_docs/utils/custom_page_route.dart';
import 'package:hi_docs/screens/home/about_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isCreatorMode;

  const SettingsScreen({super.key, this.isCreatorMode = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    final l10n = AppLocalizations.of(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: PageTopBar(
        title: user.name.isEmpty ? l10n.profile : user.name,
        subtitle: user.email,
        icon: Icons.person_rounded,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editProfile,
            onPressed: () => _showEditProfileDialog(
              context,
              auth,
              user.name,
              user.email,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(label: l10n.appearance, isDark: isDark),
            const SizedBox(height: 10),

            _GroupCard(
              isDark: isDark,
              children: [
                _LanguageRow(
                  l10n: l10n,
                  isDark: isDark,
                  languageProvider: languageProvider,
                ),
                _ThemeRow(
                  l10n: l10n,
                  isDark: isDark,
                  themeProvider: themeProvider,
                  onPickColor: () =>
                      _showColorSchemePicker(context, themeProvider),
                  onReset: () => _confirmResetTheme(context, themeProvider),
                ),
              ],
            ),

            const SizedBox(height: 28),

            _SectionHeader(label: l10n.others, isDark: isDark),
            const SizedBox(height: 10),

            _GroupCard(
              isDark: isDark,
              children: [
                _ModeRow(
                  l10n: l10n,
                  isDark: isDark,
                  isCreatorMode: auth.isCreatorMode,
                  onTap: () async {
                    final a = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    await a.toggleMode();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      a.isCreatorMode ? '/creator-home' : '/user-home',
                      (_) => false,
                    );
                  },
                ),
                _NavRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: context.primary,
                  title: l10n.aboutApp,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    CustomPageRoute(page: const AboutScreen()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.error.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: GradientButton(
                text: l10n.logout,
                onPressed: () async {
                  final nav = Navigator.of(context);

                  nav.pushNamedAndRemoveUntil('/login', (_) => false);

                  await auth.logout();
                },
                fullWidth: true,
                icon: Icons.logout_rounded,
                colors: const [
                  AppTheme.error,
                  Color(0xFFB71C1C),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorSchemePicker(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;

            final sheetL10n = AppLocalizations.of(ctx);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: 32 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sheetL10n.pickColorScheme,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sheetL10n.pickColorSchemeSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextMuted
                          : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppColorScheme.values
                        .where((s) => s != AppColorScheme.custom)
                        .map((scheme) {
                      final selected = themeProvider.colorScheme == scheme;

                      return GestureDetector(
                        onTap: () {
                          themeProvider.setColorScheme(scheme);
                          setSheet(() {});
                          setState(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? scheme.primaryColor.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? scheme.primaryColor
                                  : AppTheme.border,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: scheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                scheme.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? scheme.primaryColor
                                      : AppTheme.textSecondary,
                                ),
                              ),
                              if (selected) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 15,
                                  color: scheme.primaryColor,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sheetL10n.customColor,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sheetL10n.pickAnyColor,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.darkTextMuted
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final initial = themeProvider.customPrimary ??
                              themeProvider.primary;

                          await _showFullColorPicker(
                            ctx,
                            initial,
                            themeProvider,
                          );

                          setSheet(() {});

                          if (mounted) {
                            setState(() {});
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                themeProvider.colorScheme ==
                                        AppColorScheme.custom
                                    ? themeProvider.primary
                                        .withValues(alpha: 0.12)
                                    : context.primaryFaint,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  themeProvider.colorScheme ==
                                          AppColorScheme.custom
                                      ? themeProvider.primary
                                      : AppTheme.border,
                              width:
                                  themeProvider.colorScheme ==
                                          AppColorScheme.custom
                                      ? 2
                                      : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  gradient: SweepGradient(
                                    colors: [
                                      Colors.red,
                                      Colors.yellow,
                                      Colors.green,
                                      Colors.cyan,
                                      Colors.blue,
                                      Colors.purple,
                                      Colors.red,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                themeProvider.colorScheme ==
                                        AppColorScheme.custom
                                    ? sheetL10n.customActive
                                    : sheetL10n.pickColor,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: themeProvider.colorScheme ==
                                          AppColorScheme.custom
                                      ? themeProvider.primary
                                      : context.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showFullColorPicker(
    BuildContext ctx,
    Color initialColor,
    ThemeProvider themeProvider,
  ) async {
    Color picked = initialColor;

    await showDialog(
      context: ctx,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppLocalizations.of(dialogCtx).pickCustomColor),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: picked,
              onColorChanged: (c) => picked = c,
              enableAlpha: false,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
              hexInputBar: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppLocalizations.of(dialogCtx).cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppLocalizations.of(dialogCtx).apply),
            ),
          ],
        );
      },
    );

    themeProvider.setCustomColor(picked);
  }

  void _confirmResetTheme(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.themeReset),
        content: Text(l10n.themeResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              themeProvider.resetTheme();

              messenger.showSnackBar(
                SnackBar(content: Text(l10n.themeResetDone)),
              );
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    AuthProvider auth,
    String currentName,
    String currentEmail,
  ) {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return _EditProfileDialog(
          auth: auth,
          currentName: currentName,
          currentEmail: currentEmail,
          messenger: messenger,
        );
      },
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final AuthProvider auth;
  final String currentName;
  final String currentEmail;
  final ScaffoldMessengerState messenger;

  const _EditProfileDialog({
    required this.auth,
    required this.currentName,
    required this.currentEmail,
    required this.messenger,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController emailCtrl;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.currentName);
    emailCtrl = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (isSaving) return;

    final name = nameCtrl.text.trim();

    if (name.length < 2) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    final l10n = AppLocalizations.of(context);

    await widget.auth.updateProfile(name: name);

    if (!mounted) return;

    final error = widget.auth.error;

    Navigator.of(context).pop();

    widget.messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? l10n.profileUpdated),
        backgroundColor: error != null ? AppTheme.error : null,
      ),
    );

    widget.auth.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.editProfile),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            enabled: !isSaving,
            decoration: InputDecoration(
              labelText: l10n.username,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailCtrl,
            readOnly: true,
            decoration: InputDecoration(
              labelText: l10n.email,
              prefixIcon: const Icon(Icons.email_outlined),
              helperText: l10n.emailCannotChange,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isSaving
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _save,
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _GroupCard({
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: isDark ? AppTheme.darkBorder : AppTheme.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;
  final LanguageProvider languageProvider;

  const _LanguageRow({
    required this.l10n,
    required this.isDark,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.primaryWith(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.translate_rounded,
              size: 20,
              color: context.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.pilihBahasa,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: languageProvider.languageCode,
              borderRadius: BorderRadius.circular(14),
              items: [
                DropdownMenuItem(
                  value: 'id',
                  child: Text(
                    l10n.indonesian,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(
                    l10n.english,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
              onChanged: (code) {
                if (code != null) {
                  languageProvider.setLanguage(code);
                }
              },
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;
  final ThemeProvider themeProvider;
  final VoidCallback onPickColor;
  final VoidCallback onReset;

  const _ThemeRow({
    required this.l10n,
    required this.isDark,
    required this.themeProvider,
    required this.onPickColor,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: themeProvider.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.palette_rounded,
                  size: 20,
                  color: themeProvider.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.themeCustomize,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.pickColorSchemeSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onPickColor,
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkBorder
                            : AppTheme.border,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: themeProvider.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.darkBorder
                                  : AppTheme.border,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            themeProvider.colorScheme.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onReset,
                tooltip: l10n.themeReset,
                icon: const Icon(
                  Icons.restart_alt_rounded,
                  size: 21,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;
  final bool isCreatorMode;
  final VoidCallback onTap;

  const _ModeRow({
    required this.l10n,
    required this.isDark,
    required this.isCreatorMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isCreatorMode
        ? Icons.person_rounded
        : Icons.dashboard_rounded;
    final title =
        isCreatorMode ? l10n.modeUser : l10n.modeCreator;
    final desc = isCreatorMode
        ? l10n.modeUserDesc
        : l10n.modeCreatorDesc;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.primaryWith(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: context.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.switchToMode} $title',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isDark;
  final VoidCallback? onTap;

  const _NavRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
      ),
    );
  }
}