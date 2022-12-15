// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item_quote.dart';
import '/l10n/l10n.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/call/widget/animated_delayed_scale.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/forward/controller.dart';
import '/ui/page/home/page/chat/widget/custom_drop_target.dart';
import '/ui/page/home/page/chat/widget/message_field/view.dart';
import '/ui/widget/modal_popup.dart';

/// View for forwarding the provided [quotes] into the selected [Chat]s.
///
/// Intended to be displayed with the [show] method.
class ChatForwardView extends StatelessWidget {
  const ChatForwardView({
    Key? key,
    required this.from,
    required this.quotes,
    this.text,
    this.attachments,
  }) : super(key: key);

  /// ID of the [Chat] the [quotes] are forwarded from.
  final ChatId from;

  /// [ChatItemQuote]s to be forwarded.
  final List<ChatItemQuote> quotes;

  /// Initial [String] to put in the send field.
  final String? text;

  /// Initial [Attachment]s to attach to the provided [quotes].
  final RxList<MapEntry<GlobalKey, Attachment>>? attachments;

  /// Displays a [ChatForwardView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context,
    ChatId from,
    List<ChatItemQuote> quotes, {
    String? text,
    List<Attachment>? attachments,
  }) {
    RxList<MapEntry<GlobalKey, Attachment>> attachmentsToSend =
        RxList<MapEntry<GlobalKey, Attachment>>();
    attachments?.forEach((e) {
      attachmentsToSend.add(MapEntry(GlobalKey(), e));
    });
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: 650,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      mobilePadding: const EdgeInsets.all(0),
      desktopPadding: const EdgeInsets.all(0),
      child: ChatForwardView(
        key: const Key('ChatForwardView'),
        from: from,
        quotes: quotes,
        attachments: attachmentsToSend,
        text: text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          onChanged: (result) => c.searchResults.value = result,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                        child: MessageFieldView(
                          messageFieldKey: const Key('ForwardField'),
                          messageSendButtonKey: const Key('SendForward'),
                          controller: c.sendController,
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
                            color: const Color(0x40000000),
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
                                      color: const Color(0x40000000),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 50,
                                        color: Colors.white,
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
