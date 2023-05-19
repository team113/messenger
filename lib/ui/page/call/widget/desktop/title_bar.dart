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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';

import '../tooltip_button.dart';
import '/domain/repository/chat.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/call/controller.dart';

/// [Widget] that displays the title bar at the top of the screen.
///
/// [TitleBar] contains information such as the recipient or caller's
/// name, avatar, and call state, as well as buttons for full-screen mode
/// and other actions.
class TitleBar extends StatelessWidget {
  const TitleBar({
    super.key,
    required this.constraints,
    required this.chat,
    required this.titleArguments,
    required this.fullscreen,
    this.onDoubleTap,
    this.onTap,
    this.toggleFullscreen,
  });

  /// Chat information.
  final Rx<RxChat?> chat;

  /// Indicator whether the application is in full-screen mode.
  final RxBool fullscreen;

  /// Variable that imposes restrictions on the size of the element.
  final BoxConstraints constraints;

  /// Header arguments.
  final Map<String, String> titleArguments;

  /// Callback, called when you click on the `full-screen` button.
  final Function()? toggleFullscreen;

  /// Callback, called when you touch on the left side
  /// of this [TitleBar].
  final Function()? onTap;

  /// Callback, called when double-tapping on this [TitleBar].
  final Function()? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        key: const ValueKey('TitleBar'),
        color: const Color(0xFF162636),
        height: CallController.titleHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Handles double tap to toggle fullscreen.
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: onDoubleTap,
            ),

            // Left part of the title bar that displays the recipient or
            // the caller, its avatar and the call's state.
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: constraints,
                child: InkWell(
                  onTap: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 10),
                      AvatarWidget.fromRxChat(chat.value, radius: 8),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'label_call_title'.l10nfmt(titleArguments),
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontSize: 13,
                            color: const Color(0xFFFFFFFF),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Right part of the title bar that displays buttons.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TooltipButton(
                      onTap: toggleFullscreen,
                      hint: fullscreen.value
                          ? 'btn_fullscreen_exit'.l10n
                          : 'btn_fullscreen_enter'.l10n,
                      child: SvgImage.asset(
                        'assets/icons/fullscreen_${fullscreen.value ? 'exit' : 'enter'}.svg',
                        width: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
