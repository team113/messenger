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
import 'package:get/get.dart';

import '../dense.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
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

  /// Reactive [Uint8List] that returns the current background as a
  /// [Uint8List].
  final Rx<Uint8List?> background;

  /// Opens an image choose popup and sets the selected file as a [background].
  final Future<void> Function() pickBackground;

  /// Removes the currently set [background].
  final Future<void> Function() removeBackground;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    Widget message({
      bool fromMe = true,
      bool isRead = true,
      String text = '123',
    }) {
      return Container(
        padding: const EdgeInsets.fromLTRB(5 * 2, 6, 5 * 2, 6),
        child: IntrinsicWidth(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              color: fromMe
                  ? isRead
                      ? style.readMessageColor
                      : style.unreadMessageColor
                  : style.messageColor,
              borderRadius: BorderRadius.circular(15),
              border: fromMe
                  ? isRead
                      ? style.secondaryBorder
                      : Border.all(color: const Color(0xFFDAEDFF), width: 0.5)
                  : style.primaryBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  child: Text(text, style: style.boldBody),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Dense(
      Column(
        children: [
          WidgetButton(
            onPressed: pickBackground,
            child: Container(
              decoration: BoxDecoration(
                border: style.primaryBorder,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Obx(() {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: background.value == null
                              ? SvgImage.asset(
                                  'assets/images/background_light.svg',
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.memory(
                                  background.value!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: message(
                                  fromMe: false,
                                  text: 'label_hello'.l10n,
                                ),
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: message(
                                  fromMe: true,
                                  text: 'label_hello_reply'.l10n,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          Obx(() {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WidgetButton(
                      onPressed: background.value == null
                          ? pickBackground
                          : removeBackground,
                      child: Text(
                        background.value == null
                            ? 'btn_upload'.l10n
                            : 'btn_delete'.l10n,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
