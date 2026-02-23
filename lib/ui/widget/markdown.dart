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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_utils/src/extensions/dynamic_extensions.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/themes.dart';
import '../page/work/page/freelance/helper_function/markdown_selected_text_from_full_text.dart';

/// [MarkdownBody] stylized with the [Style].
class MarkdownWidget extends StatefulWidget {
  const MarkdownWidget(this.body, {super.key});

  /// Text to parse and render as a markdown.
  final String body;

  @override
  State<MarkdownWidget> createState() => _MarkdownWidgetState();
}

class _MarkdownWidgetState extends State<MarkdownWidget> {
  /// Stores the most recently reconstructed selected text.
  ///
  /// The reconstruction is necessary because Flutter selection returns
  /// flattened plain text without original newline characters.
  String selectedText = '';

  /// Disables the default browser context menu on web.
  ///
  /// This ensures that Flutter's selection system is used instead of
  /// the native browser context menu, providing consistent cross-platform
  /// selection behavior.
  ///
  /// Returns `1` when context menu is successfully disabled or when
  /// running on non-web platforms. Returns `0` if disabling fails.
  Future<int> _disableContextMenu() async {
    if (kIsWeb) {
      return await BrowserContextMenu.disableContextMenu().then(
        (_) => 1,
        onError: (e) => 0,
      );
    } else {
      return 1;
    }
  }

  @override
  void dispose() {
    // Re-enables browser context menu when widget is disposed
    // to avoid affecting other parts of the application.
    if (kIsWeb && BrowserContextMenu.enabled) {
      BrowserContextMenu.enableContextMenu();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return FutureBuilder(
      future: _disableContextMenu(),
      builder: (context, snapshot) {
        if (snapshot.data == 1) {
          return SelectableRegion(
            /// Triggered whenever the selection changes.
            ///
            /// When text is selected, the selected content is reconstructed
            /// to preserve original formatting and stored locally.
            ///
            /// When selection is copied,
            /// the previously selected text is copied to clipboard.
            onSelectionChanged: (selectedContent) {
              if (!(selectedContent?.isBlank ?? true)) {
                setState(() {
                  selectedText = markdownSelectedTextFromFullText(
                    fullText: widget.body,
                    selectedText: selectedContent?.plainText ?? '',
                  );
                });
              } else {
                Clipboard.setData(ClipboardData(text: selectedText));
              }
            },
            selectionControls: MaterialTextSelectionControls(),
            child: GptMarkdownTheme(
              gptThemeData: GptMarkdownThemeData(
                brightness: Theme.of(context).brightness,

               highlightColor: style.colors.secondaryHighlight,

                h2: style.fonts.largest.bold.onBackground.copyWith(
                  fontSize: 20,
                ),
              ),
              child: GptMarkdown(
                widget.body,
                maxLines: 1000,
                linkBuilder: (context, span, link, textStyle) {
                  return Text(
                    span.toPlainText(),
                    style: textStyle.copyWith(color: style.colors.primary),
                  );
                },
                style: style.fonts.normal.regular.onBackground,
                onLinkTap: (link, href) async => await launchUrlString(link),
              ),
            ),
          );
        } else {
          return CircularProgressIndicator.adaptive();
        }
      },
    );
  }
}
