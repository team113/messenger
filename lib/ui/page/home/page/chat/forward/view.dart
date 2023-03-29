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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/themes.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item_quote_input.dart';
import '/l10n/l10n.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/call/widget/animated_delayed_scale.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/page/chat/widget/custom_drop_target.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for forwarding the provided [quotes] into the selected [Chat]s.
///
/// Intended to be displayed with the [show] method.
class ChatForwardView extends StatelessWidget {
  const ChatForwardView({
    Key? key,
    required this.from,
    required this.quotes,
    this.text,
    this.attachments = const [],
  }) : super(key: key);

  /// ID of the [Chat] the [quotes] are forwarded from.
  final ChatId from;

  /// [ChatItemQuoteInput]s to be forwarded.
  final List<ChatItemQuoteInput> quotes;

  /// Initial [String] to put in the send field.
  final String? text;

  /// Initial [Attachment]s to attach to the provided [quotes].
  final List<Attachment> attachments;

  /// Displays a [ChatForwardView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context,
    ChatId from,
    List<ChatItemQuoteInput> quotes, {
    String? text,
    List<Attachment> attachments = const [],
  }) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: 800,
      ),
      mobilePadding: const EdgeInsets.all(0),
      desktopPadding: const EdgeInsets.all(0),
      child: ChatForwardView(
        key: const Key('ChatForwardView'),
        from: from,
        quotes: quotes,
        attachments: attachments,
        text: text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<Style>()!;
    return GetBuilder(
      init: ChatForwardController(
        Get.find(),
        Get.find(),
        from: from,
        quotes: quotes,
        text: text,
        attachments: attachments,
        pop: () => Navigator.of(context).pop(true),
      ),
      builder: (ChatForwardController c) {
        return Obx(() {
          return CustomDropTarget(
            key: Key('ChatForwardView_$from'),
            onDragDone: c.dropFiles,
            onDragEntered: (_) => c.isDraggingFiles.value = true,
            onDragExited: (_) => c.isDraggingFiles.value = false,
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height: 16),
                      Expanded(
                        child: SearchView(
                          key: const Key('SearchView'),
                          categories: const [
                            SearchCategory.chat,
                            SearchCategory.contact,
                            SearchCategory.user,
                          ],
                          title: 'label_forward_message'.l10n,
                          onSelected: (r) => c.searchResults.value = r,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                        child: MessageFieldView(
                          fieldKey: const Key('ForwardField'),
                          sendKey: const Key('SendForward'),
                          constraints: BoxConstraints(
                            maxHeight: min(
                                    MediaQuery.of(context).size.height - 10,
                                    800) /
                                4,
                          ),
                          controller: c.send,
                        ),
                      ),
                    ],
                  ),
                ),
                IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: 200.milliseconds,
                    child: c.isDraggingFiles.value
                        ? Container(
                            color: Theme.of(context)
                                .extension<Style>()!
                                .transparentOpacity74,
                            child: Center(
                              child: AnimatedDelayedScale(
                                duration: const Duration(milliseconds: 300),
                                beginScale: 1,
                                endScale: 1.06,
                                child: ConditionalBackdropFilter(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Theme.of(context)
                                          .extension<Style>()!
                                          .transparentOpacity74,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 50,
                                        color: style.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
