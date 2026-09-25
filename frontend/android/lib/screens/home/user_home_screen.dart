import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/models/response_model.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/providers/response_provider.dart';
import 'package:hi_docs/widgets/common/dynamic_header.dart';
import 'package:hi_docs/widgets/form/form_theme.dart';

import 'package:hi_docs/screens/home/history_screen.dart';
import 'package:hi_docs/screens/home/history_detail_screen.dart';
import 'package:hi_docs/screens/exam/link_input_screen.dart';
import 'package:hi_docs/screens/exam/scan_form_screen.dart';
import 'package:hi_docs/screens/home/settings_screen.dart';
import 'package:hi_docs/utils/custom_page_route.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final auth = Provider.of<AuthProvider>(context);
    final fp = Provider.of<FormProvider>(context);

    final tabs = [
      _HomeTab(
        auth: auth,
        fp: fp,
      ),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      body: IndexedStack(
        index: _tab,
        children: tabs,
      ),
      bottomNavigationBar: _BottomBar(
        current: _tab,
        cs: cs,
        isDark: isDark,
        onTap: (i) {
          setState(() => _tab = i);

          if (i == 0 && mounted) {
          }
        },
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final AuthProvider auth;
  final FormProvider fp;

  const _HomeTab({
    required this.auth,
    required this.fp,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _refreshAll(
      FormProvider fp, ResponseProvider rp) async {
    try {
      await fp.loadForms();
      await rp.loadMySubmissions(formProvider: fp);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat ulang: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final rp = Provider.of<ResponseProvider>(context);
    final auth = widget.auth;
    final fp = widget.fp;

    final name = auth.currentUser?.name.split(' ').first ?? l10n.user;

    final id = (auth.currentUser?.id ?? '').toLowerCase();

    final email = (auth.currentUser?.email ?? '').toLowerCase();

    final recent = rp.responses
        .where(
          (r) =>
              r.respondentId.toLowerCase() == id ||
              r.respondentEmail.toLowerCase() == email,
        )
        .toList()
      ..sort(
        (a, b) => b.submittedAt.compareTo(a.submittedAt),
      );

    final recentWithForm = recent.take(20).map((r) {
      final form = fp.getFormById(r.formId) ??
          FormModel(
            id: r.formId,
            title: r.formTitle,
            creatorId: '',
            scheduledOpen: r.submittedAt,
            scheduledClose: r.submittedAt,
            createdAt: r.submittedAt,
          );
      return (form, r);
    }).toList();

    final filtered = recentWithForm.take(5).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      body: RefreshIndicator(
        onRefresh: () => _refreshAll(fp, rp),
        color: cs.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _header(
                context,
                name,
                isDark,
                auth,
              ),
            ),
            SliverToBoxAdapter(
              child: _actions(
                context,
                isDark,
                cs,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                35,
                20,
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l10n.lastHistory,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (recent.isEmpty)
                      _emptyState(
                        isDark,
                        Icons.history_rounded,
                        l10n.noFormsYetU,
                      )
                    else ...[
                      _RecentHistoryList(
                        isDark: isDark,
                        items: filtered,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    String name,
    bool isDark,
    AuthProvider auth,
  ) {
    final l10n = AppLocalizations.of(context);

    // Padding tanpa inset status bar: SafeArea sudah ditangani DynamicHeader
    // sehingga tinggi top bar sama dengan halaman Riwayat/Profile/Forms.
    return DynamicHeader(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        24,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.helloWave,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Colors.white.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CustomPageRoute(page: const SettingsScreen(),
                ),
              );
            },
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white.withValues( alpha: 0.16 ),
              child: Text(
                auth.currentUser?.name.isNotEmpty == true
                    ? auth.currentUser!.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(
    BuildContext context,
    bool isDark,
    ColorScheme cs,
  ) {
    final l10n = AppLocalizations.of(context);
    final divider = isDark ? AppTheme.darkBorder : AppTheme.border;

    return Container(
      color: isDark ? AppTheme.darkCard : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: _ActionItem(
              label: l10n.scanQrAction,
              icon: Icons.qr_code_scanner_rounded,
              color: cs.primary,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(page:
                        const ScanFormScreen(),
                  ),
                );
              },
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: divider,
          ),
          Expanded(
            child: _ActionItem(
              label: l10n.pasteLinkAction,
              icon: Icons.link_rounded,
              color: cs.primary,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  CustomPageRoute(page:
                        const LinkInputScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(
    bool isDark,
    IconData icon,
    String msg,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isDark
                  ? AppTheme.darkTextMuted
                  : AppTheme.border,
            ),
            const SizedBox(height: 10),
            Text(
              msg,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextMuted
                    : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentHistoryList extends StatelessWidget {
  final bool isDark;
  final List<(FormModel, ResponseModel)> items;

  const _RecentHistoryList({
    required this.isDark,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder
              : AppTheme.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _RecentHistoryRow(
              form: items[i].$1,
              response: items[i].$2,
              isDark: isDark,
            ),
            if (i != items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: isDark
                    ? AppTheme.darkBorder
                    : AppTheme.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _RecentHistoryRow extends StatelessWidget {
  final FormModel form;
  final ResponseModel response;
  final bool isDark;

  const _RecentHistoryRow({
    required this.form,
    required this.response,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.textPrimary;

    final textMuted = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.textMuted;

    final dt = response.submittedAt;

    final date =
        '${dt.day}/${dt.month}/${dt.year} · '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin:
                    const EdgeInsets.only(right: 12),
                decoration:
                    BoxDecoration(
                  color: FormTheme.resolvePrimary(context, form.themeColor),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (response.score > 0)
                Text(
                  '${response.score.round()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark
                      ? AppTheme.darkTextMuted
                      : AppTheme.border,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int current;
  final ColorScheme cs;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.current,
    required this.cs,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final items = [
      (
        Icons.home_outlined,
        Icons.home_rounded,
        l10n.home,
      ),
      (
        Icons.history_outlined,
        Icons.history_rounded,
        l10n.history,
      ),
      (
        Icons.person_outlined,
        Icons.person_rounded,
        l10n.profile,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? AppTheme.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkBorder
                : AppTheme.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(
              items.length,
              (i) {
                final active = current == i;
                final (off, on, label) =
                    items[i];

                final color = active
                    ? cs.primary
                    : isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.textMuted;

                return Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          active ? on : off,
                          size: 22,
                          color: color,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}