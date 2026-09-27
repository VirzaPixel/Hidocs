import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/screens/home/user_home_screen.dart';
import 'package:hi_docs/screens/home/history_screen.dart';
import 'package:hi_docs/screens/home/creator_home_screen.dart';
import 'package:hi_docs/screens/home/settings_screen.dart';
import 'package:hi_docs/screens/forms/create_form_screen.dart';
import 'package:hi_docs/utils/custom_page_route.dart';
import 'package:hi_docs/utils/theme_context.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FormProvider>().loadForms();
    });
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        CustomPageRoute(page: const CreateFormScreen()),
      ).then((_) {
        if (mounted) {
          context.read<FormProvider>().loadForms();
        }
      });
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    if ((index == 0 || index == 3) && mounted) {
      context.read<FormProvider>().loadForms();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final List<Widget> pages = [
      const UserHomeScreen(),
      const HistoryScreen(),
      const SizedBox.shrink(),
      const CreatorHomeScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _TikTokStyleBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        isDark: isDark,
        l10n: l10n,
      ),
    );
  }
}

class _TikTokStyleBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final AppLocalizations l10n;

  const _TikTokStyleBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.primary;
    final bg = isDark ? AppTheme.darkCard : Colors.white;
    final border = isDark ? AppTheme.darkBorder : AppTheme.border;
    final unselectedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: l10n.home,
                primary: primary,
                unselectedColor: unselectedColor,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.history_outlined,
                activeIcon: Icons.history_rounded,
                label: 'Riwayat',
                primary: primary,
                unselectedColor: unselectedColor,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: SizedBox(
                      width: 48,
                      height: 32,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 0,
                            child: Container(
                              width: 38,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F2FE),
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: Container(
                              width: 38,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF0050),
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : AppTheme.primary,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              size: 22,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.dashboard_customize_outlined,
                activeIcon: Icons.dashboard_customize_rounded,
                label: 'Form Maker',
                primary: primary,
                unselectedColor: unselectedColor,
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outlined,
                activeIcon: Icons.person_rounded,
                label: l10n.profile,
                primary: primary,
                unselectedColor: unselectedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color primary,
    required Color unselectedColor,
  }) {
    final active = currentIndex == index;
    final color = active ? primary : unselectedColor;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
