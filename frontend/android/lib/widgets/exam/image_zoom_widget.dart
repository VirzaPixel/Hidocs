import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/utils/custom_page_route.dart';

class ImageZoomWidget extends StatelessWidget {
  final String? imageUrl;
  final String? filePath;
  final double height;

  const ImageZoomWidget({
    required this.imageUrl,
    this.filePath,
    this.height = 200,
    super.key,
  });

  const ImageZoomWidget.file({
    required String this.filePath,
    this.height = 200,
    super.key,
  }) : imageUrl = null;

  @override
  Widget build(BuildContext context) {
    final isFile = filePath != null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CustomPageRoute(page: _FullScreenZoom(
            imageUrl: imageUrl,
            filePath: filePath,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: height,
          color: context.primaryFaint,
          child: Stack(fit: StackFit.expand, children: [
            if (isFile)
              Image.file(
                File(filePath!),
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.broken_image_rounded, size: 52,
                        color: context.primaryWith(0.30)),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context).formImageGagal,
                        style: const TextStyle(fontSize: 13,
                            color: AppTheme.textMuted)),
                  ]),
                ),
              )
            else
              Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.primaryWith(0.5),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.broken_image_rounded, size: 52,
                      color: context.primaryWith(0.30)),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context).formImageGagal,
                      style: const TextStyle(fontSize: 13,
                          color: AppTheme.textMuted)),
                ]),
              ),
            ),
            Positioned(top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('HD', style: TextStyle(
                    color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
            Positioned(bottom: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.zoom_in_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String? imageUrl;
  final String? filePath;

  const FullScreenImageViewer({super.key, this.imageUrl, this.filePath});

  @override
  Widget build(BuildContext context) {
    return _FullScreenZoom(imageUrl: imageUrl, filePath: filePath);
  }
}

class _FullScreenZoom extends StatelessWidget {
  final String? imageUrl;
  final String? filePath;

  const _FullScreenZoom({
    this.imageUrl,
    this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
        title: Text(AppLocalizations.of(context).hdImage, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: filePath != null
                ? Image.file(File(filePath!))
                : Hero(
                    tag: imageUrl!,
                    child: Image.network(imageUrl!,
                        errorBuilder: (_, __, ___) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.image_rounded,
                                    size: 100, color: Colors.white24),
                                const SizedBox(height: 16),
                                Text(
                                    AppLocalizations.of(context)
                                        .formImageGagal,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 14)),
                              ],
                            )),
                  ),
          ),
        ),
      ),
    );
  }
}
