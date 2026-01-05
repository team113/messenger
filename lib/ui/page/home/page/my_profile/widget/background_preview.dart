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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// Rectangular preview of the provided [background] displaying messages above
/// it along with manipulation buttons under the preview, if [onPick] and
/// [onRemove] are provided.
///
/// Intended to be used as a [AbstractSettingsRepository.background] preview.
class BackgroundPreview extends StatelessWidget {
  const BackgroundPreview(
    this.background, {
    super.key,
    this.onPick,
    this.onRemove,
  });

  /// [Uint8List] to display as a background.
  final Uint8List? background;

  /// Callback, called when picking of [background] is requested.
  final void Function()? onPick;

  /// Callback, called when the [background] should be removed.
  final void Function()? onRemove;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      children: [
        WidgetButton(
          onPressed: onPick,
          child: Container(
            decoration: BoxDecoration(
              border: style.primaryBorder,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: double.infinity,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: background == null
                          ? const SvgImage.asset(
                              'assets/images/background_light.svg',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.memory(background!, fit: BoxFit.cover),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: MessagePreviewWidget(
                              fromMe: false,
                              text: 'label_hello'.l10n,
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: MessagePreviewWidget(
                              text: 'label_hello_reply'.l10n,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (onPick != null && onRemove != null) ...[
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WidgetButton(
                  onPressed: background == null ? onPick : onRemove,
                  child: Text(
                    background == null ? 'btn_upload'.l10n : 'btn_delete'.l10n,
                    style: style.fonts.small.regular.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Message-styled [Container].
class MessagePreviewWidget extends StatelessWidget {
  const MessagePreviewWidget({
    super.key,
    this.text,
    this.fromMe = true,
    this.style,
  });

  /// Indicator whether the message is sent by the user or received from
  /// other users.
  final bool fromMe;

  /// Text to display in this [MessagePreviewWidget].
  final String? text;

  /// Optional [TextStyle] to apply to the [text].
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: IntrinsicWidth(
        child: Container(
          decoration: BoxDecoration(
            color: fromMe ? style.readMessageColor : style.messageColor,
            borderRadius: BorderRadius.circular(15),
            border: fromMe ? style.secondaryBorder : style.primaryBorder,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (text != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  child: Text(
                    text!,
                    style:
                        this.style ?? style.fonts.medium.regular.onBackground,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
