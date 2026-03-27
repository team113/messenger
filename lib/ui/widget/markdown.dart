// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/themes.dart';

/// [GptMarkdown] stylized with the [Style].
class MarkdownWidget extends StatelessWidget {
  const MarkdownWidget(this.body, {super.key});

  /// Text to parse and render as a markdown.
  final String body;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return SelectionArea(
      child: GptMarkdownTheme(
        gptThemeData: GptMarkdownThemeData(
          brightness: Theme.of(context).brightness,
          highlightColor: style.colors.secondaryHighlight,

          // TODO: Exception.
          h2: style.fonts.largest.bold.onBackground.copyWith(fontSize: 20),
        ),
        child: GptMarkdown(
          body,
          linkBuilder: (context, span, link, textStyle) {
            return Text(
              span.toPlainText(),
              style: textStyle.copyWith(color: style.colors.primary),
            );
          },
          maxLines: 1 << 31,
          style: style.fonts.normal.regular.onBackground,
          onLinkTap: (link, href) async => await launchUrlString(link),
        ),
      ),
    );
  }
}
