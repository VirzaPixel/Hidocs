import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/screens/forms/user_form_detail_screen.dart';
import 'package:hi_docs/utils/custom_page_route.dart';

class DeepLinkFormScreen extends StatefulWidget {
  final String slug;

  const DeepLinkFormScreen({required this.slug, super.key});

  @override
  State<DeepLinkFormScreen> createState() => _DeepLinkFormScreenState();
}

class _DeepLinkFormScreenState extends State<DeepLinkFormScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final fp = Provider.of<FormProvider>(context, listen: false);
    final form = await fp.loadPublicForm(widget.slug);
    if (!mounted) return;
    if (form == null) {
      setState(() => _error = fp.error ?? 'Form tidak ditemukan.');
      return;
    }
    Navigator.pushReplacement(
      context,
      CustomPageRoute(page: UserFormDetailScreen(form: form)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      body: Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link_off_rounded, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/', (_) => false),
                      child: const Text('Kembali ke Beranda'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
