import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/themes.dart';

/// [MarkdownBody] stylized with the [Style].
class MarkdownWidget extends StatelessWidget {
  const MarkdownWidget(this.body, {super.key});

  final String body;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return MarkdownBody(
      data: body,
      onTapLink: (_, href, __) async => await launchUrlString(href!),
      styleSheet: MarkdownStyleSheet(
        h2Padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),

        // TODO: Exception.
        h2: style.fonts.largest.bold.onBackground.copyWith(fontSize: 20),

        p: style.fonts.normal.regular.onBackground,
        code: style.fonts.small.regular.onBackground.copyWith(
          letterSpacing: 1.2,
          backgroundColor: style.colors.secondaryHighlight,
        ),
        codeblockDecoration: BoxDecoration(
          color: style.colors.secondaryHighlight,
        ),
        codeblockPadding: const EdgeInsets.all(16),
        blockquoteDecoration: BoxDecoration(
          color: style.colors.secondaryHighlight,
        ),
      ),
    );
  }
}
