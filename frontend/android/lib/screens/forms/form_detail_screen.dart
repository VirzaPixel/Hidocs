import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/providers/response_provider.dart';
import 'package:hi_docs/widgets/form/form_theme.dart';
import 'package:hi_docs/widgets/common/gradient_button.dart';
import 'package:hi_docs/screens/forms/create_form_screen.dart';
import 'package:hi_docs/screens/forms/grading_screen.dart';
import 'package:hi_docs/screens/exam/qr_generator_screen.dart';
import 'package:hi_docs/screens/forms/results_screen.dart';
import 'package:hi_docs/utils/custom_page_route.dart';

class FormDetailScreen extends StatefulWidget {
  final FormModel form;
  const FormDetailScreen({required this.form, super.key});

  @override
  State<FormDetailScreen> createState() => _FormDetailScreenState();
}

class _FormDetailScreenState extends State<FormDetailScreen> {
  late FormModel _form;

  @override
  void initState() {
    super.initState();
    _form = widget.form;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetail();
    });
  }

  Future<void> _loadDetail() async {
    final provider = Provider.of<FormProvider>(context, listen: false);
    final detail = await provider.loadFormDetail(widget.form.id);

    if (mounted && detail != null) {
      setState(() {
        _form = detail;
      });
      // Jika detail ternyata sudah lewat jadwal tapi masih rawIsActive,
      // paksa sync agar dashboard juga langsung Tutup tanpa perlu hot restart.
      if (detail.isExpired && detail.rawIsActive) {
        // update lokal detail juga
        setState(() {
          _form = copyFormModel(detail, isActive: false);
        });
        provider.syncExpiredForms();
      }
    }
  }

  void _shareLink() {
    SharePlus.instance.share(ShareParams(text: 'Fill out this form: ${_form.fullLink}'));
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _form.fullLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Link copied to clipboard!'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = Provider.of<FormProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppTheme.darkCard : AppTheme.surfaceCard;
    final borderClr = isDark ? AppTheme.darkBorder : AppTheme.border;
    final primaryTxt = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    final canEdit = _form.totalResponses == 0;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      body: CustomScrollView(
        slivers: [
          // Blue Gradient Flexible Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: FormTheme.primaryOf(_form.themeColor),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              PopupMenuButton<String?>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (val) async {
                  if (val == null) return;
                  if (val == 'qr') {
                    Navigator.push(
                      context,
                      CustomPageRoute(page: QRGeneratorScreen(form: _form),
                      ),
                    );
                  } else if (val == 'edit') {
                    Navigator.push(
                      context,
                      CustomPageRoute(page: CreateFormScreen(existingForm: _form),
                      ),
                    );
                  } else if (val == 'toggle') {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await formProvider.toggleFormActive(_form.id);
                    if (!mounted) return;
                    if (ok) {
                      setState(() {
                        _form = copyFormModel(_form, isActive: !_form.isActive);
                      });
                    } else {
                      final message =
                          formProvider.error ?? 'Gagal mengubah status form.';
                      formProvider.clearError();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: AppTheme.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  } else if (val == 'delete') {
                    _confirmDelete(context, formProvider);
                  } else if (val == 'share') {
                    _shareLink();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Share Link'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'qr',
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Show QR Code'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: canEdit ? 'edit' : null,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: canEdit ? null : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Edit Form',
                              style: TextStyle(
                                color: canEdit ? null : AppTheme.textMuted,
                              ),
                            ),
                            if (!canEdit)
                              const Text(
                                'Form sudah ada responden — tidak bisa diedit',
                                style: TextStyle(
                                    fontSize: 12, color: AppTheme.textMuted),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          _form.isActive
                              ? Icons.pause_circle_outline_rounded
                              : Icons.play_circle_outline_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(_form.isActive ? 'Close Form' : 'Activate Form'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 20, color: AppTheme.error),
                        SizedBox(width: 12),
                        Text('Delete Form',
                            style: TextStyle(color: AppTheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: FormTheme.headerGradient(
                      _form.themeColor, _form.coverGradient),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            _StatusBadgeHeader(isActive: _form.isActive),
                            const SizedBox(width: 8),
                            _VisibilityBadgeHeader(isPublic: _form.isPublic),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _form.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main Content Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Unified Top Stats Card (2 Columns — duration removed)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderClr),
                    ),
                    child: Row(
                      children: [
                        _StatColumn(
                          icon: Icons.group_outlined,
                          value: '${_form.totalResponses}',
                          label: 'Responses',
                          iconColor: const Color(0xFF0D1B2A),
                        ),
                        Container(width: 1, height: 44, color: borderClr),
                        _StatColumn(
                          icon: Icons.help_outline_rounded,
                          value: '${_form.questions.length}',
                          label: 'Questions',
                          iconColor: context.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Public Form / Share Link Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkCard
                          : const Color(0xFFEFF4FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkBorder
                            : context.primaryWith(0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _form.isPublic
                                      ? Icons.public_rounded
                                      : Icons.lock_outline_rounded,
                                  size: 16,
                                  color: AppTheme.success,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _form.isPublic ? 'Public Form' : 'Private Form',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Share link',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.darkSurface
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderClr),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.link_rounded,
                                      size: 16,
                                      color: context.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _form.fullLink,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: context.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Salin Link',
                              child: InkWell(
                                onTap: _copyLink,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.darkSurface
                                        : const Color(0xFFE2ECF7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 18,
                                    color: context.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Show QR',
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CustomPageRoute(page: QRGeneratorScreen(form: _form),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.darkSurface
                                        : const Color(0xFFE2ECF7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 18,
                                    color: context.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Form Settings Box
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderClr),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: primaryTxt,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Form Settings',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: primaryTxt,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SettingsChip(
                              icon: Icons.shuffle_rounded,
                              label: 'Shuffle questions',
                              color: _form.shuffleQuestions
                                  ? context.primary
                                  : AppTheme.textMuted,
                              active: _form.shuffleQuestions,
                            ),
                            _SettingsChip(
                              icon: Icons.swap_vert_rounded,
                              label: 'Shuffle answers',
                              color: _form.shuffleOptions
                                  ? context.primary
                                  : AppTheme.textMuted,
                              active: _form.shuffleOptions,
                            ),
                            _SettingsChip(
                              icon: Icons.lock_outline_rounded,
                              label: 'One-time only',
                              color: _form.oneTimeOnly
                                  ? AppTheme.error
                                  : AppTheme.textMuted,
                              active: _form.oneTimeOnly,
                            ),
                            if (_form.isScheduled)
                              const _SettingsChip(
                                icon: Icons.access_time_rounded,
                                label: 'Scheduled',
                                color: AppTheme.success,
                                active: true,
                              ),
                            _SettingsChip(
                              icon: Icons.public_rounded,
                              label: _form.isPublic ? 'Public' : 'Private',
                              color: _form.isPublic
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              active: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: borderClr),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Opens',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _form.isScheduled
                                        ? '${_form.scheduledOpen.day}/${_form.scheduledOpen.month}/${_form.scheduledOpen.year}'
                                        : '1/6/2024',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: primaryTxt,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 32, color: borderClr),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Closes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _form.isScheduled
                                        ? '${_form.scheduledClose.day}/${_form.scheduledClose.month}/${_form.scheduledClose.year}'
                                        : '15/7/2024',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: primaryTxt,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Action Buttons
                  GradientButton(
                    text: 'View Results',
                    onPressed: () => Navigator.push(
                      context,
                      CustomPageRoute(page: ResultsScreen(form: _form),
                      ),
                    ),
                    fullWidth: true,
                    icon: Icons.bar_chart_rounded,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        CustomPageRoute(page: GradingScreen(form: _form),
                        ),
                      ),
                      icon: const Icon(
                        Icons.grading_rounded,
                        size: 18,
                        color: AppTheme.warning,
                      ),
                      label: const Text(
                        'Manual Grading',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warning,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppTheme.warning
                            .withValues(alpha: 0.06),
                        foregroundColor: AppTheme.warning,
                        side: BorderSide(
                          color: AppTheme.warning.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: canEdit
                          ? () => Navigator.push(
                                context,
                                CustomPageRoute(page:
                                      CreateFormScreen(existingForm: _form),
                                ),
                              )
                          : null,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: canEdit ? context.primary : AppTheme.textMuted,
                      ),
                      label: Text(
                        canEdit ? 'Edit Form' : 'Edit dikunci (ada responden)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: canEdit ? context.primary : AppTheme.textMuted,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: cardBg,
                        foregroundColor: canEdit
                            ? context.primary
                            : AppTheme.textMuted,
                        side: BorderSide(
                          color: canEdit
                              ? borderClr
                              : borderClr.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, FormProvider fp) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Form?'),
        content: Text(
            'Apakah Anda yakin ingin menghapus "${_form.title}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogCtx);

              final rp = Provider.of<ResponseProvider>(context, listen: false);
              final ok = await fp.deleteForm(_form.id);

              if (ok) {
                rp.removeResponsesByForm(_form.id);
                messenger.showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Form berhasil dihapus.'),
                      ],
                    ),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                nav.pop();
              } else {
                final message = fp.error ?? 'Gagal menghapus form.';
                fp.clearError();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadgeHeader extends StatelessWidget {
  final bool isActive;
  const _StatusBadgeHeader({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF1B9E5E).withValues(alpha: 0.25)
            : AppTheme.error.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFF26D07C) : AppTheme.error,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Closed',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityBadgeHeader extends StatelessWidget {
  final bool isPublic;
  const _VisibilityBadgeHeader({required this.isPublic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1B9E5E).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            isPublic ? 'Public' : 'Private',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTxt = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: primaryTxt,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;

  const _SettingsChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: 0.10)
            : (isDark ? AppTheme.darkSurface : const Color(0xFFF2F4F7)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? color.withValues(alpha: 0.25)
              : (isDark ? AppTheme.darkBorder : AppTheme.border),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: active ? color : AppTheme.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? color : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

