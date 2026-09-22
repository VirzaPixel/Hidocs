import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:hi_docs/widgets/form/quill_embeds.dart';

class RichTextContentView extends StatefulWidget {
  final String? content;
  final String fallbackText;
  final TextStyle? style;

  const RichTextContentView({
    super.key,
    this.content,
    required this.fallbackText,
    this.style,
  });

  @override
  State<RichTextContentView> createState() => _RichTextContentViewState();
}

class _RichTextContentViewState extends State<RichTextContentView> {
  QuillController? _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
  }

  @override
  void didUpdateWidget(covariant RichTextContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != oldWidget.content) {
      _controller?.dispose();
      _controller = null;
      _controller = _buildController();
    }
  }

  QuillController? _buildController() {
    final content = widget.content;
    if (content == null || content.trim().isEmpty) return null;

    try {
      final document = Document.fromJson(jsonDecode(content) as List);
      return QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (controller == null) {
      return Text(
        widget.fallbackText,
        style: widget.style,
      );
    }

    return DefaultTextStyle(
      style: widget.style ?? const TextStyle(fontSize: 14),
      child: QuillEditor(
        controller: controller,
        focusNode: _focusNode,
        scrollController: _scrollController,
        config: QuillEditorConfig(
          scrollable: false,
          expands: false,
          padding: EdgeInsets.zero,
          embedBuilders: buildQuillEmbedBuilders(),
        ),
      ),
    );
  }
}
