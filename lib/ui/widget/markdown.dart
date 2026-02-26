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
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/util/platform_utils.dart';
import '../page/home/page/chat/widget/context_buttons.dart';
import 'context_menu/region.dart';
import 'obscured_menu_interceptor.dart';
import 'obscured_selection_area.dart';

/// [MarkdownBody] stylized with the [Style].
class MarkdownWidget extends StatefulWidget {
  const MarkdownWidget(this.body, {super.key});

  /// Text to parse and render as a markdown.
  final String body;

  @override
  State<MarkdownWidget> createState() => _MarkdownWidgetState();
}

class _MarkdownWidgetState extends State<MarkdownWidget> {
  /// Reconstructed selection used to extract text from the markdown source.
  String _selectedText = '';

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    if (kIsWeb) {
      return ContextMenuRegion(
        preventContextMenu: kIsWeb,
        actions: [
          CopyContextMenuButton(
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: _selectedText)),
          ),
        ],
        child: ObscuredSelectionArea(
          contextMenuBuilder: (_, _) => CopyContextMenuButton(
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: _selectedText)),
          ),

          selectionControls: EmptyTextSelectionControls(),

          /// Called when the text selection changes.
          ///
          /// Selected plain text is reconstructed against the original
          /// markdown source to preserve formatting and stored locally.
          ///
          /// Reconstructed value is copied to the clipboard only when
          /// the copy action is explicitly triggered from the context menu.
          onSelectionChanged: (selectedContent) {
            setState(() {
              _selectedText = (selectedContent?.plainText ?? '')
                  .reconstructFrom(widget.body);
            });
          },
          child: ObscuredMenuInterceptor(
            enabled: kIsWeb,
            child: _Markdown(style: style, widget: widget),
          ),
        ),
      );
    } else {
      return SelectionArea(
        contextMenuBuilder: (context, editableTextState) {
          final List<ContextMenuButtonItem> buttonItems =
              editableTextState.contextMenuButtonItems;
          buttonItems.removeWhere(
            (e) => e.type != ContextMenuButtonType.selectAll,
          );
          buttonItems.add(
            ContextMenuButtonItem(
              type: ContextMenuButtonType.copy,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _selectedText));
                editableTextState.hideToolbar();
              },
              label: PlatformUtils.isMobile
                  ? 'btn_copy'.l10n
                  : 'btn_copy_text'.l10n,
            ),
          );

          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: buttonItems,
          );
        },

        /// Called when the text selection changes.
        ///
        /// Selected plain text is reconstructed against the original
        /// markdown source to preserve formatting and stored locally.
        ///
        /// Reconstructed value is copied to the clipboard only when
        /// the copy action is explicitly triggered from the context menu.
        onSelectionChanged: (selectedContent) {
          setState(() {
            _selectedText = (selectedContent?.plainText ?? '').reconstructFrom(
              widget.body,
            );
          });
        },
        child: _Markdown(style: style, widget: widget),
      );
    }
  }
}

class _Markdown extends StatelessWidget {
  const _Markdown({required this.style, required this.widget});

  final Style style;
  final MarkdownWidget widget;

  @override
  Widget build(BuildContext context) {
    return GptMarkdownTheme(
      gptThemeData: GptMarkdownThemeData(
        brightness: Theme.of(context).brightness,

        highlightColor: style.colors.secondaryHighlight,

        h2: style.fonts.largest.bold.onBackground.copyWith(fontSize: 20),
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
    );
  }
}

/// Provides utilities for reconstructing selected markdown text.
///
/// This extension restores formatting that may be lost when selecting
/// rendered markdown content.
extension MarkdownSelectionParser on String {
  /// Reconstructs selected plain text using the provided [fullText].
  ///
  /// Attempts to restore formatting by matching the selection
  /// against the original markdown source.
  ///
  /// Returns empty string if selection is empty.
  String reconstructFrom(String fullText) {
    String selectedText = this;

    fullText = fullText.replaceAll(RegExp(r'[#\[\]`]|[^\x20-\x7E\n\r]'), '');

    selectedText = selectedText.replaceAll(RegExp(r'#|[^\x20-\x7E\n\r]'), '');

    if (selectedText.isEmpty) {
      return '';
    }

    if (fullText.contains(selectedText)) {
      return selectedText;
    }

    String reconstructedText = '';

    String prefixMatch = '';

    for (int i = 0; i < selectedText.length; i++) {
      prefixMatch += selectedText[i];

      if (!fullText.contains(prefixMatch)) {
        prefixMatch = prefixMatch.substring(0, prefixMatch.length - 1);
        break;
      }
    }

    String suffixMatch = '';

    for (int i = selectedText.length - 1; i >= 0; i--) {
      suffixMatch = selectedText[i] + suffixMatch;

      if (!fullText.contains(suffixMatch)) {
        suffixMatch = suffixMatch.substring(1, suffixMatch.length);
        break;
      }
    }

    final List<String> prefixSplit = fullText.split(prefixMatch);
    prefixSplit.removeAt(0);

    reconstructedText = prefixMatch + prefixSplit.join(prefixMatch);

    final List<String> suffixSplit = reconstructedText.split(suffixMatch);

    if (suffixSplit.length > 2) {
      final String selectedWithoutSuffix = selectedText.substring(
        0,
        selectedText.length - suffixMatch.length,
      );

      String refinedSuffix = '';

      for (int i = selectedWithoutSuffix.length - 1; i >= 0; i--) {
        refinedSuffix = selectedWithoutSuffix[i] + refinedSuffix;

        if (!fullText.contains(refinedSuffix)) {
          refinedSuffix = refinedSuffix.substring(1, refinedSuffix.length);
          break;
        }
      }

      final List<String> refinedSplit = reconstructedText.split(refinedSuffix);

      refinedSplit.removeLast();

      reconstructedText = refinedSplit.join(refinedSuffix) + refinedSuffix;
    } else {
      suffixSplit.removeLast();

      reconstructedText = suffixSplit.join(suffixMatch) + suffixMatch;
    }

    return reconstructedText;
  }
}
