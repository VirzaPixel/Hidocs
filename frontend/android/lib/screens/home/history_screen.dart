import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/response_model.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/providers/response_provider.dart';
import 'package:hi_docs/providers/theme_provider.dart';
import 'package:hi_docs/widgets/common/custom_card.dart';
import 'package:hi_docs/widgets/common/page_top_bar.dart';
import 'package:hi_docs/screens/home/history_detail_screen.dart';
import 'package:hi_docs/utils/custom_page_route.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final responseProvider =
        Provider.of<ResponseProvider>(context, listen: false);
    final formProvider = Provider.of<FormProvider>(context, listen: false);
    try {
      await responseProvider.loadMySubmissions(formProvider: formProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat riwayat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final formProvider = Provider.of<FormProvider>(context);
    final responseProvider = Provider.of<ResponseProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final l10n = AppLocalizations.of(context);
    final primaryColor = themeProvider.primary;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    final userId = auth.currentUser?.id ?? '';

    final responses = responseProvider
        .getResponsesByRespondent(userId)
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    // Tampilkan semua submission tanpa filter form — form mungkin belum
    // dimuat di FormProvider untuk user biasa (bukan creator).
    final visibleResponses = responses.toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PageTopBar(
        title: l10n.history,
        subtitle: visibleResponses.isEmpty
            ? l10n.noSubmissionHistory
            : '${visibleResponses.length} pengisian tersimpan',
        icon: Icons.history_rounded,
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: visibleResponses.isEmpty
          ? _EmptyState(
              icon: Icons.history_rounded,
              title: l10n.noSubmissionHistory,
              subtitle: l10n.noHistorySub,
              primaryColor: primaryColor,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Riwayat Pengisian',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${visibleResponses.length} pengisian tersimpan',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 16,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${visibleResponses.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...visibleResponses.map((response) {
                  final form = formProvider.getFormById(response.formId) ??
                      // Fallback: buat FormModel minimal dari data response
                      FormModel(
                        id: response.formId,
                        title: response.formTitle.isNotEmpty
                            ? response.formTitle
                            : 'Form',
                        creatorId: '',
                        scheduledOpen: response.submittedAt,
                        scheduledClose: response.submittedAt,
                        createdAt: response.submittedAt,
                      );

                  return _HistoryCard(
                    form: form,
                    response: response,
                    onTap: () {
                      Navigator.push(
                        context,
                        CustomPageRoute(page: HistoryDetailScreen(
                            form: form,
                            response: response,
                          ),
                        ),
                      );
                    },
                    primaryColor: primaryColor,
                  );
                }),
              ],
            ),
        ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final FormModel form;
  final ResponseModel response;
  final VoidCallback onTap;
  final Color primaryColor;

  const _HistoryCard({
    required this.form,
    required this.response,
    required this.onTap,
    required this.primaryColor,
  });

  String _formatDate(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');

    return '${dt.day}/${dt.month}/${dt.year} • $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final primaryTextColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    final hasScore =
        response.score > 0 || response.essayScores.isNotEmpty;

    final showScore =
        form.resultVisibility == ResultVisibility.resultAndScore;

    return CustomCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 22,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatDate(response.submittedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: secondaryTextColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l10n.historySubmitted,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (showScore && hasScore)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 14,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.scorePct(
                          response.percentage.round(),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primaryColor;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 40,
          vertical: 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                icon,
                size: 40,
                color: primaryColor.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}