import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

class MathBlockEmbed extends CustomBlockEmbed {
  const MathBlockEmbed(String value) : super(mathType, value);

  static const String mathType = 'math';
}

class MathEmbedBuilder extends EmbedBuilder {
  @override
  String get key => MathBlockEmbed.mathType;

  @override
  String toPlainText(Embed node) {
    return node.value.data.toString();
  }

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final String formula = embedContext.node.value.data.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      child: Math.tex(
        formula,
        mathStyle: MathStyle.display,
        textStyle: const TextStyle(
          fontSize: 24,
        ),
        onErrorFallback: (error) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Invalid LaTeX formula:\n'
              '${error.messageWithType}',
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
          );
        },
      ),
    );
  }
}

List<EmbedBuilder> buildQuillEmbedBuilders() => [
      ...(kIsWeb
          ? FlutterQuillEmbeds.editorWebBuilders()
          : FlutterQuillEmbeds.editorBuilders()),
      MathEmbedBuilder(),
    ];

String cleanLatex(String input) {
  String expression = input.trim();

  if (expression.startsWith(r'$$') &&
      expression.endsWith(r'$$') &&
      expression.length >= 4) {
    expression = expression.substring(
      2,
      expression.length - 2,
    );
  } else if (expression.startsWith(r'$') &&
      expression.endsWith(r'$') &&
      expression.length >= 2) {
    expression = expression.substring(
      1,
      expression.length - 1,
    );
  }

  return expression.trim();
}
