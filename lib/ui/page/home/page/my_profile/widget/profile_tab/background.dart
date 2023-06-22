// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// [Widget] which returns the contents of a [ProfileTab.background] section.
class ProfileBackground extends StatelessWidget {
  const ProfileBackground(
    this.background,
    this.pickBackground,
    this.removeBackground, {
    super.key,
  });

  /// [Uint8List] that returns the current background.
  final Uint8List? background;

  /// Opens an image choose popup and sets the selected file as a [background].
  final Future<void> Function() pickBackground;

  /// Removes the currently set [background].
  final Future<void> Function() removeBackground;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Paddings.dense(
      Column(
        children: [
          WidgetButton(
            onPressed: pickBackground,
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
                            ? SvgImage.asset(
                                'assets/images/background_light.svg',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.memory(
                                background!,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: _MessageWidget(
                                fromMe: false,
                                text: 'label_hello'.l10n,
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: _MessageWidget(
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
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WidgetButton(
                    onPressed:
                        background == null ? pickBackground : removeBackground,
                    child: Text(
                      background == null
                          ? 'btn_upload'.l10n
                          : 'btn_delete'.l10n,
                      style: fonts.labelSmall!.copyWith(
                        color: style.colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget which display a message on [ProfileBackground].
class _MessageWidget extends StatelessWidget {
  const _MessageWidget({
    this.text,
    this.fromMe = true,
  });

  /// Indicator whether the message is sent by the user or received from
  /// other users.
  final bool fromMe;

  /// Text to display in this [_MessageWidget].
  final String? text;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Container(
      padding: const EdgeInsets.fromLTRB(5 * 2, 6, 5 * 2, 6),
      child: IntrinsicWidth(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
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
                  child: Text(text!, style: fonts.bodyLarge),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
