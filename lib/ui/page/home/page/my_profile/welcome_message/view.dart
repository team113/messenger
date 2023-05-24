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
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/themes.dart';

import '/domain/model/chat.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/page/chat/widget/custom_drop_target.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for forwarding the provided [quotes] into the selected [Chat]s.
///
/// Intended to be displayed with the [show] method.
class WelcomeMessageView extends StatelessWidget {
  const WelcomeMessageView({super.key, this.initial});

  final ChatMessage? initial;

  /// Displays a [ChatForwardView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, {ChatMessage? initial}) {
    return ModalPopup.show(
      context: context,
      desktopConstraints:
          const BoxConstraints(maxWidth: double.infinity, maxHeight: 800),
      mobilePadding: const EdgeInsets.all(0),
      desktopPadding: const EdgeInsets.all(0),
      child: WelcomeMessageView(
        key: const Key('ChatForwardView'),
        initial: initial,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder(
      init: WelcomeMessageController(
        Get.find(),
        Get.find(),
        Get.find(),
        initial: initial,
        pop: (a) => Navigator.of(context).pop(a),
      ),
      builder: (WelcomeMessageController c) {
        final TextStyle? thin = Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: Colors.black);

        // return Obx(() {
        return CustomDropTarget(
          key: const Key('WelcomeMessageView'),
          onDragDone: c.dropFiles,
          onDragEntered: (_) => c.isDraggingFiles.value = true,
          onDragExited: (_) => c.isDraggingFiles.value = false,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  ModalPopupHeader(
                    header: Center(
                      child: Text(
                        'label_welcome_message'.l10n,
                        style: thin?.copyWith(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                      child: MessageFieldView(
                        fieldKey: const Key('ForwardField'),
                        sendKey: const Key('SendForward'),
                        constraints: const BoxConstraints(),
                        controller: c.send,
                      ),
                    ),
                  ),
                ],
              ),
              // IgnorePointer(
              //   child: AnimatedSwitcher(
              //     duration: 200.milliseconds,
              //     child: c.isDraggingFiles.value
              //         ? Container(
              //             color: const Color(0x40000000),
              //             child: Center(
              //               child: AnimatedDelayedScale(
              //                 duration: const Duration(milliseconds: 300),
              //                 beginScale: 1,
              //                 endScale: 1.06,
              //                 child: ConditionalBackdropFilter(
              //                   borderRadius: BorderRadius.circular(16),
              //                   child: Container(
              //                     decoration: BoxDecoration(
              //                       borderRadius: BorderRadius.circular(16),
              //                       color: const Color(0x40000000),
              //                     ),
              //                     child: const Padding(
              //                       padding: EdgeInsets.all(16),
              //                       child: Icon(
              //                         Icons.add_rounded,
              //                         size: 50,
              //                         color: Colors.white,
              //                       ),
              //                     ),
              //                   ),
              //                 ),
              //               ),
              //             ),
              //           )
              //         : null,
              //   ),
              // ),
            ],
          ),
        );
        // });
      },
    );
  }
}
