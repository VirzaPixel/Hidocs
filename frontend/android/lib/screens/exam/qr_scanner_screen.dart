import 'package:flutter/material.dart';
import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool scanned = false;
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = context.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  color: AppTheme.accent,
                  size: 28,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(height: 24),

              Center(
                child: Column(
                  children: [
                    const Text(
                      "Scan QR Code",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please point the camera at the QR Code",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.accent.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: MobileScanner(
                            controller: controller,
                            onDetect: (capture) async {
                                if (scanned) return;
                                if (capture.barcodes.isEmpty) return;

                                final barcode = capture.barcodes.first;
                                final String? code = barcode.rawValue;

                                if (code != null) {
                                    setState(() {
                                    scanned = true;
                                    });

                                    controller.stop();

                                    showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) {
                                        return Dialog(
                                        backgroundColor: context.primary,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Padding(
                                            padding: EdgeInsets.all(28),
                                            child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                                CircularProgressIndicator(
                                                color: AppTheme.accent,
                                                ),
                                                SizedBox(height: 20),
                                                Text(
                                                "Loading Form...",
                                                style: TextStyle(
                                                    color: AppTheme.accent,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                ),
                                                ),
                                            ],
                                            ),
                                        ),
                                        );
                                    },
                                    );

                                    await Future.delayed(const Duration(seconds: 2));

                                    if (context.mounted) {
                                    Navigator.pop(context); 
                                    Navigator.pop(context, code); 
                                    }
                                }
                            },
                          ),
                        ),

                        const Positioned.fill(
                          child: CustomPaint(
                            painter: _CornerPainter(
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  const _CornerPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 36.0;
    const strokeWidth = 6.0;
    const radius = 20.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, radius)
        ..arcToPoint(
          const Offset(radius, 0),
          radius: const Radius.circular(radius),
        )
        ..lineTo(cornerLength, 0),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(w - cornerLength, 0)
        ..lineTo(w - radius, 0)
        ..arcToPoint(
          Offset(w, radius),
          radius: const Radius.circular(radius),
        )
        ..lineTo(w, cornerLength),
      paint,
    );

    canvas.drawPath(
    Path()
        ..moveTo(0, h - cornerLength)
        ..lineTo(0, h - radius)
        ..arcToPoint(
        Offset(radius, h),
        radius: const Radius.circular(radius),
        clockwise: false,
        )
        ..lineTo(cornerLength, h),
    paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(w, h - cornerLength)
        ..lineTo(w, h - radius)
        ..arcToPoint(
          Offset(w - radius, h),
          radius: const Radius.circular(radius),
        )
        ..lineTo(w - cornerLength, h),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}