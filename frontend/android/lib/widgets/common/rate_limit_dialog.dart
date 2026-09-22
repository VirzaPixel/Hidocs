import 'dart:async';
import 'package:flutter/material.dart';

class RateLimitDialog extends StatefulWidget {
  final int retryAfterSeconds;
  final String message;
  final VoidCallback? onRetry;

  const RateLimitDialog({
    super.key,
    required this.retryAfterSeconds,
    this.message = 'Server sedang padat. Silakan tunggu beberapa detik.',
    this.onRetry,
  });

  static Future<void> show(
    BuildContext context, {
    required int retryAfterSeconds,
    String? message,
    VoidCallback? onRetry,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RateLimitDialog(
        retryAfterSeconds: retryAfterSeconds,
        message: message ?? 'Server sedang padat. Silakan tunggu beberapa detik.',
        onRetry: onRetry,
      ),
    );
  }

  @override
  State<RateLimitDialog> createState() => _RateLimitDialogState();
}

class _RateLimitDialogState extends State<RateLimitDialog> {
  late int _remaining;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.retryAfterSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        if (mounted) {
          Navigator.of(context).pop();
          widget.onRetry?.call();
        }
      } else {
        if (mounted) {
          setState(() {
            _remaining--;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      title: const Row(
        children: [
          Icon(Icons.speed_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 10),
          Text(
            'Traffic Server Padat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: widget.retryAfterSeconds > 0
                      ? _remaining / widget.retryAfterSeconds
                      : 0.0,
                  strokeWidth: 6,
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  color: Colors.orange,
                ),
              ),
              Text(
                '${_remaining}s',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Mencoba ulang secara otomatis...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
