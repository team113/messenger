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

import '../controller.dart';
import '../widget/tooltip_button.dart';
import '../../home/widget/avatar.dart';
import '../../../widget/svg/svg.dart';

import '/routes.dart';
import '/themes.dart';
import '/util/web/non_web.dart';

/// Combines all the stackable content into [Scaffold].
class DesktopScaffoldWidget extends StatelessWidget {
  const DesktopScaffoldWidget(
    this.c, {
    Key? key,
    required this.content,
    required this.ui,
  }) : super(key: key);

  /// Controller of an [OngoingCall] overlay.
  final CallController c;

  /// Stackable content.
  final List<Widget> content;

  /// List of [Widget] that make up the user interface
  final List<Widget> ui;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!WebUtils.isPopup)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: (d) {
                c.left.value = c.left.value + d.delta.dx;
                c.top.value = c.top.value + d.delta.dy;
                c.applyConstraints(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    CustomBoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      blurStyle: BlurStyle.outer,
                    )
                  ],
                ),
                child: _TitleBarWidget(c),
              ),
            ),
          Expanded(child: Stack(children: [...content, ...ui])),
        ],
      ),
    );
  }
}

/// Title bar of the call containing information about the call and control
/// buttons.
class _TitleBarWidget extends StatelessWidget {
  const _TitleBarWidget(
    this.c, {
    Key? key,
  }) : super(key: key);

  /// Controller of an [OngoingCall] overlay.
  final CallController c;

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
              onDoubleTap: c.toggleFullscreen,
            ),

            // Left part of the title bar that displays the recipient or
            // the caller, its avatar and the call's state.
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: c.size.width - 60),
                child: InkWell(
                  onTap: WebUtils.isPopup
                      ? null
                      : () {
                          router.chat(c.chatId.value);
                          if (c.fullscreen.value) {
                            c.toggleFullscreen();
                          }
                        },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 10),
                      AvatarWidget.fromRxChat(c.chat.value, radius: 8),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'label_call_title'.l10nfmt(c.titleArguments),
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
                      onTap: c.toggleFullscreen,
                      hint: c.fullscreen.value
                          ? 'btn_fullscreen_exit'.l10n
                          : 'btn_fullscreen_enter'.l10n,
                      child: SvgImage.asset(
                        asset:
                            'assets/icons/fullscreen_${c.fullscreen.value ? 'exit' : 'enter'}.svg',
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
