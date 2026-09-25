import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/widgets/common/gradient_button.dart';
import 'package:hi_docs/widgets/common/custom_input.dart';
import 'package:hi_docs/widgets/common/hidocs_logo.dart';
import 'package:hi_docs/screens/auth/register_screen.dart';
import 'package:hi_docs/utils/custom_page_route.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _key = GlobalKey<FormState>();

  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_key.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    await auth.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;

    if (auth.error != null) {
      _showSnack(auth.error!, AppTheme.error);
      auth.clearError();
      return;
    }

    if (auth.isLoggedIn) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (_) => false,
      );
    }
  }

  void _showSnack(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
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
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12) ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context);

    final size = MediaQuery.of(context).size;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      // Force default HiDocs blue theme on login screen regardless of user's
      // saved color scheme — ensures brand identity for new / logged-out users.
      backgroundColor: AppTheme.primary,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -75,
              child: _Blob(
                230,
                AppTheme.primaryLight.withValues(alpha: 0.20),
              ),
            ),

            Positioned(
              top: 145,
              left: -115,
              child: _Blob(
                210,
                AppTheme.primaryLight.withValues(alpha: 0.10),
              ),
            ),

            Positioned(
              bottom: -75,
              left: -110,
              child: _Blob(
                260,
                AppTheme.primaryDark.withValues(alpha: 0.42),
              ),
            ),

            Positioned(
              top: 190,
              right: -35,
              child: _Blob(
                100,
                AppTheme.accent.withValues(alpha: 0.07),
              ),
            ),

            Positioned(
              top: 130,
              left: 90,
              child: _Dot(
                6,
                Colors.white.withValues(alpha: 0.30),
              ),
            ),
            Positioned(
              top: 235,
              right: 40,
              child: _Dot(
                5,
                AppTheme.accent.withValues(alpha: 0.70),
              ),
            ),
            Positioned(
              bottom: 235,
              right: 30,
              child: _Dot(
                5,
                Colors.white.withValues(alpha: 0.22),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: bottom + 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom -
                            20)
                        .clamp(0.0, double.infinity),
                  ),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          30,
                          28,
                          30,
                          0,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HiDocsLogo(
                                size: 38,
                                showShadow: false,
                              ),
                              SizedBox(width: 11),
                              Text(
                                'HiDocs!',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          30,
                          32,
                          30,
                          28,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkCard
                              : Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: isDark
                              ? Border.all(
                                  color: AppTheme.darkBorder,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.32 : 0.20,
                              ),
                              blurRadius: 35,
                              spreadRadius: 0,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _key,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.loginScreenTitle,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.textPrimary,
                                  letterSpacing: -0.7,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                l10n.loginScreenSubtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppTheme.darkTextMuted
                                      : AppTheme.textMuted,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 25),

                              CustomInput(
                                controller: _emailCtrl,
                                label: l10n.email,
                                hint: l10n.emailPlaceholder,
                                prefixIcon:
                                    Icons.mail_outline_rounded,
                                keyboardType:
                                    TextInputType.emailAddress,
                                validator: (v) =>
                                    (v == null ||
                                            !RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                                .hasMatch(v.trim()))
                                        ? l10n.wrongEmail
                                        : null,
                              ),

                              const SizedBox(height: 16),

                              CustomInput(
                                controller: _passCtrl,
                                label: l10n.password,
                                hint: l10n.passMin6,
                                prefixIcon:
                                    Icons.lock_outline_rounded,
                                obscureText: _obscure,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons
                                            .visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: isDark
                                        ? AppTheme.darkTextMuted
                                        : AppTheme.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscure = !_obscure;
                                    });
                                  },
                                ),
                                validator: (v) =>
                                    (v == null || v.length < 6)
                                        ? l10n.passMin6
                                        : null,
                              ),

                              const SizedBox(height: 30),

                              GradientButton(
                                text: l10n.login,
                                onPressed: _login,
                                isLoading: auth.isLoading,
                                fullWidth: true,
                                icon: Icons.login_rounded,
                              ),

                              const SizedBox(height: 14),

                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    CustomPageRoute(page:
                                          const RegisterScreen(),
                                    ),
                                  ),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? AppTheme.darkTextMuted
                                            : AppTheme.textMuted,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              l10n.dontHaveAccount,
                                        ),
                                        TextSpan(
                                          text: l10n.signUpNow,
                                          style: TextStyle(
                                            color: context.primary,
                                            fontWeight:
                                                FontWeight.w700,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                context.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        l10n.authFooterTagline,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          color: Colors.white.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob(this.size, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final double size;
  final Color color;

  const _Dot(this.size, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}