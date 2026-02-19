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
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get/get_utils/src/extensions/dynamic_extensions.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../page/work/page/freelance/helper_function/markdown_selected_text_from_full_text.dart';
import '/themes.dart';

/// [MarkdownBody] stylized with the [Style].
class MarkdownWidget extends StatefulWidget {
  const MarkdownWidget(this.body, {super.key});

  /// Text to parse and render as a markdown.
  final String body;

  @override
  State<MarkdownWidget> createState() => _MarkdownWidgetState();
}

class _MarkdownWidgetState extends State<MarkdownWidget> {
  String selectedText = '';
  late SelectionListenerNotifier selectionListenerNotifier;

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
  void initState() {
    selectionListenerNotifier = SelectionListenerNotifier();
    super.initState();
  }

  @override
  void dispose() {
    if (kIsWeb && BrowserContextMenu.enabled) {
      BrowserContextMenu.enableContextMenu();
    }
    selectionListenerNotifier.dispose();
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
            child: SelectionListener(
              selectionNotifier: selectionListenerNotifier,
              child: MarkdownBody(

                selectable: false,
                data: widget.body,
                onTapLink: (_, href, _) async => await launchUrlString(href!),
                styleSheet: MarkdownStyleSheet(
                  h2Padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),

                  // TODO: Exception.
                  h2: style.fonts.largest.bold.onBackground.copyWith(
                    fontSize: 20,
                  ),

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
