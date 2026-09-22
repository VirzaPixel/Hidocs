import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/widgets/common/gradient_button.dart';
import 'package:hi_docs/widgets/common/custom_input.dart';
import 'package:hi_docs/widgets/common/hidocs_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscure = true;

  late final List<TextEditingController> _otpCtrls;
  late final List<FocusNode> _otpNodes;

  String get _otpValue => _otpCtrls.map((c) => c.text).join();

  Timer? _timer;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();

    _resendCooldown = 0;
    _otpCtrls = List.generate(
      6,
      (_) => TextEditingController(),
    );
    _otpNodes = List.generate(
      6,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();

    for (final c in _otpCtrls) {
      c.dispose();
    }

    for (final f in _otpNodes) {
      f.dispose();
    }

    super.dispose();
  }

  void _startCooldownTimer() {
    _timer?.cancel();

    setState(() => _resendCooldown = 180);

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (t) {
        if (!mounted) {
          t.cancel();
          return;
        }

        if (_resendCooldown > 0) {
          setState(() => _resendCooldown--);
        } else {
          t.cancel();
        }
      },
    );
  }

  String _formatCooldown(int totalSeconds) {
    try {
      final safe = totalSeconds < 0 ? 0 : totalSeconds;
      final m = (safe / 60).floor().toString().padLeft(2, '0');
      final s = (safe % 60).toString().padLeft(2, '0');

      return '$m:$s';
    } catch (_) {
      return '03:00';
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    await auth.register(
      _emailCtrl.text.trim(),
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;

    if (auth.error != null) {
      _showSnack(
        auth.error!,
        AppTheme.error,
      );

      auth.clearError();
      return;
    }

    if (auth.otpSent) {
      _startCooldownTimer();

      _showSnack(
        AppLocalizations.of(context).otpSentTo(
          auth.pendingEmail,
        ),
        AppTheme.success,
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final l10n = AppLocalizations.of(context);
    final otp = _otpValue;

    if (otp.length != 6) {
      _showSnack(
        l10n.otp6digit,
        AppTheme.warning,
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final success = await auth.verifyOtp(otp);

    if (!mounted) return;

    if (auth.error != null) {
      _showSnack(
        auth.error!,
        AppTheme.error,
      );

      auth.clearError();
      return;
    }

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (r) => false,
      );
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCooldown > 0) return;

    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    await auth.resendOtp();

    if (!mounted) return;

    if (auth.error != null) {
      _showSnack(
        auth.error!,
        AppTheme.warning,
      );

      auth.clearError();
      return;
    }

    _startCooldownTimer();

    _showSnack(
      AppLocalizations.of(context).otpSentSuccess,
      AppTheme.success,
    );
  }

  void _changeEmailAddress() {
    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    auth.backToRegister();

    for (final c in _otpCtrls) {
      c.clear();
    }

    for (final node in _otpNodes) {
      node.unfocus();
    }

    _timer?.cancel();

    setState(() {
      _resendCooldown = 0;
    });

    FocusScope.of(context).unfocus();
  }

  void _showSnack(
    String message,
    Color backgroundColor,
  ) {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDigitBox(
    int index,
    bool isDark,
  ) {
    final isFilled = _otpCtrls[index].text.isNotEmpty;

    return SizedBox(
      width: 42,
      height: 50,
      child: TextField(
        controller: _otpCtrls[index],
        focusNode: _otpNodes[index],
        keyboardType: TextInputType.number,
        textCapitalization: TextCapitalization.none,
        textAlign: TextAlign.center,
        maxLength: 1,
        obscureText: false,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark
              ? AppTheme.darkTextPrimary
              : AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: isFilled
              ? context.primaryWith(0.07)
              : (isDark
                  ? AppTheme.darkCard
                  : Colors.grey.shade100),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isFilled
                  ? context.primaryWith(0.4)
                  : (isDark
                      ? AppTheme.darkBorder
                      : Colors.grey.shade300),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: context.primary,
              width: 2,
            ),
          ),
        ),
        onChanged: (val) {
          setState(() {});

          if (val.isNotEmpty && index < 5) {
            _otpNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _otpNodes[index - 1].requestFocus();
          }
        },
        onTap: () {
          _otpCtrls[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _otpCtrls[index].text.length,
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        30,
        28,
        30,
        0,
      ),
      child: Row(
        children: [
          const HiDocsLogo(
            size: 38,
            showShadow: false,
          ),
          const SizedBox(width: 11),
          const Text(
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
    );
  }

  Widget _buildOtpStep(
    AuthProvider auth,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);

    final isExpired = _resendCooldown <= 0;

    final email = auth.pendingEmail.isNotEmpty
        ? auth.pendingEmail
        : _emailCtrl.text.trim();

    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.textMuted;

    final primaryColor =
        context.primary;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Text(
          l10n.verifyEmailBtn,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.textPrimary,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: mutedColor,
            ),
            children: [
              TextSpan(
                text: 'Kami telah mengirimkan ',
              ),
              TextSpan(
                text: l10n.otpVerification,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: '\nke email ',
              ),
              TextSpan(
                text: email,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
            (i) => _buildDigitBox(
              i,
              isDark,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text('Belum menerima kode?',
              style: TextStyle(
                fontSize: 12,
                color: mutedColor,
              ),
            ),
            Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isExpired
                      ? _handleResendOtp
                      : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration:
                        BoxDecoration(
                      color: isExpired
                          ? primaryColor
                              .withValues(
                              alpha: 0.09,
                            )
                          : mutedColor
                              .withValues(
                              alpha: 0.07,
                            ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                      border: Border.all(
                        color: isExpired
                            ? primaryColor
                                .withValues(
                                alpha: 0.30,
                              )
                            : mutedColor
                                .withValues(
                                alpha: 0.18,
                              ),
                      ),
                    ),
                    child: Text(
                      l10n.resendOtp,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                        color: isExpired
                            ? primaryColor
                            : mutedColor
                                .withValues(
                                alpha: 0.4,
                              ),
                      ),
                    ),
                  ),
                ),
                if (!isExpired) ...[
                  const SizedBox(width: 10),
                  Text(
                    _formatCooldown(
                      _resendCooldown,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                      color: mutedColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        Center(
          child: auth.isLoading
              ? const CircularProgressIndicator()
              : GestureDetector(
                  onTap:
                      _handleVerifyOtp,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    decoration:
                        BoxDecoration(
                      gradient:
                          LinearGradient(
                        colors: [
                          context.primary,
                          context.primaryDark,
                        ],
                        begin:
                            Alignment.topLeft,
                        end: Alignment
                            .bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        50,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme
                              .primary
                              .withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 12,
                          offset:
                              const Offset(
                            0,
                            5,
                          ),
                        ),
                      ],
                    ),
                    child: Text(
                      l10n.verifyCreate,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _changeEmailAddress,
          child: Text(
            l10n.backToRegister,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color: primaryColor,
              decoration:
                  TextDecoration.underline,
              decorationColor:
                  primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(
    AuthProvider auth,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.createAccount,
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
            l10n.registerSubtitle,
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
            label: l10n.emailAddress,
            hint: l10n.emailExample,
            prefixIcon:
                Icons.mail_outline_rounded,
            keyboardType:
                TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return l10n.emailRequired;
              }

              if (!RegExp(
                r'^[^@]+@[^@]+\.[^@]+',
              ).hasMatch(v)) {
                return l10n.invalidEmailFmt;
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomInput(
            controller: _usernameCtrl,
            label: l10n.username,
            hint: l10n.usernameHint,
            prefixIcon:
                Icons.badge_outlined,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return l10n.userRequired;
              }

              if (v.length < 3) {
                return l10n.min3;
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomInput(
            controller: _passwordCtrl,
            label: l10n.password,
            hint: l10n.min6,
            prefixIcon:
                Icons.lock_outline_rounded,
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons
                        .visibility_off_rounded
                    : Icons
                        .visibility_rounded,
                color: isDark
                    ? AppTheme.darkTextMuted
                    : AppTheme.textMuted,
                size: 20,
              ),
              onPressed: () {
                setState(
                  () => _obscure =
                      !_obscure,
                );
              },
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return l10n.passRequired;
              }

              if (v.length < 6) {
                return l10n.min6;
              }

              return null;
            },
          ),
          const SizedBox(height: 30),
          GradientButton(
            text: l10n.createAccount,
            onPressed: _handleRegister,
            isLoading: auth.isLoading,
            fullWidth: true,
            icon:
                Icons.how_to_reg_rounded,
          ),
          const SizedBox(height: 25),
          Center(
            child: GestureDetector(
              onTap: () =>
                  Navigator.pop(context),
              child: RichText(
                textAlign:
                    TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme
                            .darkTextMuted
                        : AppTheme
                            .textMuted,
                  ),
                  children: [
                    TextSpan(
                      text:
                          l10n.haveAccount,
                    ),
                    TextSpan(
                      text: l10n.signIn,
                      style:
                          TextStyle(
                        color:
                            context.primary,
                        fontWeight:
                            FontWeight.w700,
                        decoration:
                            TextDecoration
                                .underline,
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
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final auth =
        Provider.of<AuthProvider>(
      context,
    );

    final size =
        MediaQuery.of(context).size;

    final bottom =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final showOtp = auth.otpSent;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor:
          context.primary,
      body: GestureDetector(
        onTap: () =>
            FocusScope.of(context)
                .unfocus(),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -75,
              child: _Blob(
                230,
                context.primaryLight
                    .withValues(
                  alpha: 0.20,
                ),
              ),
            ),
            Positioned(
              top: 145,
              left: -115,
              child: _Blob(
                210,
                context.primaryLight
                    .withValues(
                  alpha: 0.10,
                ),
              ),
            ),
            Positioned(
              bottom: -75,
              left: -110,
              child: _Blob(
                260,
                context.primaryDark
                    .withValues(
                  alpha: 0.42,
                ),
              ),
            ),
            Positioned(
              top: 190,
              right: -35,
              child: _Blob(
                100,
                AppTheme.accent
                    .withValues(
                  alpha: 0.07,
                ),
              ),
            ),
            Positioned(
              top: 130,
              left: 90,
              child: _Dot(
                6,
                Colors.white
                    .withValues(
                  alpha: 0.30,
                ),
              ),
            ),
            Positioned(
              top: 235,
              right: 40,
              child: _Dot(
                5,
                AppTheme.accent
                    .withValues(
                  alpha: 0.70,
                ),
              ),
            ),
            Positioned(
              bottom: 235,
              right: 30,
              child: _Dot(
                5,
                Colors.white
                    .withValues(
                  alpha: 0.22,
                ),
              ),
            ),
            SafeArea(
              child:
                  SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    EdgeInsets.only(
                  bottom: bottom + 20,
                ),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(
                    minHeight: (size.height -
                            MediaQuery.of(
                              context,
                            ).padding.top -
                            MediaQuery.of(
                              context,
                            ).padding.bottom -
                            20)
                        .clamp(0.0, double.infinity),
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(
                        height: 42,
                      ),
                      Container(
                        margin:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 24,
                        ),
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          28,
                          32,
                          28,
                          28,
                        ),
                        decoration:
                            BoxDecoration(
                          color: isDark
                              ? AppTheme
                                  .darkCard
                              : Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            32,
                          ),
                          border: isDark
                              ? Border.all(
                                  color: AppTheme
                                      .darkBorder,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .black
                                  .withValues(
                                alpha: isDark
                                    ? 0.32
                                    : 0.20,
                              ),
                              blurRadius: 35,
                              spreadRadius: 0,
                              offset:
                                  const Offset(
                                0,
                                15,
                              ),
                            ),
                          ],
                        ),
                        child: showOtp
                            ? _buildOtpStep(
                                auth,
                                isDark,
                              )
                            : _buildRegisterForm(
                                auth,
                                isDark,
                              ),
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      Text(
                        'HiDocs • Dynamic Form & Smart Assessment Platform',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w500,
                          letterSpacing: 0.2,
                          color: Colors.white
                              .withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
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

  const _Blob(
    this.size,
    this.color,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
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

  const _Dot(
    this.size,
    this.color,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
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