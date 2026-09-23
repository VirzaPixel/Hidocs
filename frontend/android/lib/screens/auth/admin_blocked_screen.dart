import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/l10n/l10n_extension.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/utils/theme_context.dart';

/// Layar "akun admin tidak didukung di Android".
///
/// Sebelumnya login admin/superadmin langsung memuat AdminDashboardScreen
/// sehingga layar menjadi blank putih. Kini akun admin diblokir lebih dulu dan
/// diarahkan ke layar ini dengan penjelasan yang jelas.
class AdminBlockedScreen extends StatefulWidget {
  const AdminBlockedScreen({super.key});

  @override
  State<AdminBlockedScreen> createState() => _AdminBlockedScreenState();
}

class _AdminBlockedScreenState extends State<AdminBlockedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Buang sesi admin dari perangkat (token & user tersimpan) supaya tidak
      // mencoba memuat dashboard admin lagi.
      if (auth.isLoggedIn) {
        await auth.logout();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final l10n = AppLocalizations.of(context);
    final secondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final primaryText =
        isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(
          l10n.isIndonesian ? 'Akses Admin Dibatasi' : 'Admin Access Limited',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: context.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.border,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 38,
                      color: AppTheme.warning,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.isIndonesian
                        ? 'Akun Admin tidak dapat dipakai di aplikasi Android'
                        : 'Admin account cannot be used in the Android app',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: primaryText,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AuthProvider.adminBlockedMessage,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13.5, height: 1.55, color: secondary),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.primaryFaint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.primaryWith(0.22)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.language_rounded,
                            size: 18, color: context.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.isIndonesian
                                ? 'Buka hidocs.my.id lalu login memakai akun Admin / Super Admin Anda untuk mengelola dashboard.'
                                : 'Open hidocs.my.id and sign in with your Admin / Super Admin account to manage the dashboard.',
                            style:
                                TextStyle(fontSize: 12.5, height: 1.45, color: secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (r) => false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.login_rounded, size: 19),
                      label: Text(
                        l10n.isIndonesian
                            ? 'Kembali ke Halaman Login'
                            : 'Back to Login',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
