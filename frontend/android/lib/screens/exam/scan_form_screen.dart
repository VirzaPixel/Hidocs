import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/screens/forms/user_form_detail_screen.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/utils/custom_page_route.dart';

class ScanFormScreen extends StatefulWidget {
  const ScanFormScreen({super.key});

  @override
  State<ScanFormScreen> createState() => _ScanFormScreenState();
}

class _ScanFormScreenState extends State<ScanFormScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    formats: BarcodeFormat.values,
  );

  bool _isResolving = false;
  bool _hasHandled = false;
  bool _torchEnabled = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _resolveCode(String raw) async {
    if (_isResolving || _hasHandled) return;

    final l10n = AppLocalizations.of(context);

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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanQrCode),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final code = capture.barcodes.isNotEmpty
                  ? capture.barcodes.first.rawValue ?? ''
                  : '';
              if (code.isNotEmpty) {
                _resolveCode(code);
              }
            },
          ),
          const _ScannerOverlay(),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _ScannerHintCard(),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _RoundIconButton(
                  icon: _torchEnabled
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  onPressed: () async {
                    await _scannerController.toggleTorch();
                    setState(() {
                      _torchEnabled = !_torchEnabled;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String extractFormCode(String input) {
  final raw = input.trim().replaceAll('"', '').trim();
  if (raw.isEmpty) return '';

  var uri = Uri.tryParse(raw);
  if (uri != null && !uri.hasScheme) {
    uri = Uri.tryParse('https://$raw');
  }

  if (uri != null && uri.hasAuthority) {
    final segments =
        uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      return Uri.decodeComponent(segments.last);
    }
  }

  return raw;
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ScannerOverlayPainter(),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black54;
    final side = size.shortestSide * 0.62;
    final frame = Rect.fromCenter(
      center: size.center(const Offset(0, -20)),
      width: side,
      height: side,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(
          RRect.fromRectAndRadius(
            frame,
            const Radius.circular(24),
          ),
        ),
      ),
      overlayPaint,
    );

    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;
    final path = Path()
      ..moveTo(frame.left, frame.top + cornerLength)
      ..lineTo(frame.left, frame.top)
      ..lineTo(frame.left + cornerLength, frame.top)
      ..moveTo(frame.right - cornerLength, frame.top)
      ..lineTo(frame.right, frame.top)
      ..lineTo(frame.right, frame.top + cornerLength)
      ..moveTo(frame.right, frame.bottom - cornerLength)
      ..lineTo(frame.right, frame.bottom)
      ..lineTo(frame.right - cornerLength, frame.bottom)
      ..moveTo(frame.left + cornerLength, frame.bottom)
      ..lineTo(frame.left, frame.bottom)
      ..lineTo(frame.left, frame.bottom - cornerLength);

    canvas.drawPath(path, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScannerHintCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner_rounded, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n.scanInstruction,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}
