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

import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/repository/chat.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of the forward messages modal.
class ChatForwardView extends StatelessWidget {
  const ChatForwardView(this.fromId, this.forwardItems, {Key? key})
      : super(key: key);

  /// ID of [Chat] from messages will forward.
  final ChatId fromId;

  /// Map of forwarded items.
  final RxMap<ChatItemId, ChatItemQuote> forwardItems;

  /// [Container] representing a divider for content.
  static final Widget _divider = Container(
    margin: const EdgeInsets.symmetric(horizontal: 9),
    color: const Color(0x99000000),
    height: 1,
    width: double.infinity,
  );

  @override
  Widget build(BuildContext context) {
    TextStyle font17 = context.theme.outlinedButtonTheme.style!.textStyle!
        .resolve({MaterialState.disabled})!.copyWith(color: Colors.black);

    return Theme(
        data: Theme.of(context).copyWith(
          shadowColor: const Color(0x55000000),
          iconTheme: const IconThemeData(color: Colors.blue),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
            focusColor: Colors.white,
            fillColor: Colors.white,
            hoverColor: Colors.transparent,
            filled: true,
            isDense: true,
            contentPadding: EdgeInsets.fromLTRB(
              15,
              PlatformUtils.isDesktop ? 30 : 23,
              15,
              0,
            ),
          ),
        ),
        child: MediaQuery.removeViewInsets(
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          context: context,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
                maxHeight: 500,
              ),
              child: Scaffold(
                key: const Key('ForwardModal'),
                backgroundColor: Colors.transparent,
                body: Material(
                  color: const Color(0xFFFFFFFF),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  type: MaterialType.card,
                  child: GetBuilder(
                    init: ChatForwardController(
                      (bool? forwarded) => Navigator.of(context).pop(forwarded),
                      Get.find(),
                      fromId,
                      forwardItems,
                    ),
                    builder: (ChatForwardController c) => Obx(
                      () => Column(
                        children: [
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 5, 0),
                            child: Row(
                              children: [
                                Text(
                                  (c.forwardItems.length < 2)
                                      ? 'btn_forward_message'.tr
                                      : 'btn_forward_messages'.tr,
                                  style: font17,
                                ),
                                const Spacer(),
                                IconButton(
                                  key: const Key('CloseModal'),
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  onPressed: Navigator.of(context).pop,
                                  icon: const Icon(Icons.close, size: 20),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          _divider,
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView(
                                    children: [
                                      ...c.chats.map((e) => _chat(
                                            c,
                                            e,
                                            font17,
                                          ))
                                    ],
                                  ),
                                ),
                                _divider,
                                const SizedBox(height: 5),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(11, 7, 11, 7),
                                  child: (c.selectedChats.length > 1)
                                      ? Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Material(
                                                elevation: 6,
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                                child: ReactiveTextField(
                                                  key: const Key(
                                                      'ModalForwardMessageField'),
                                                  state: c.sendForward,
                                                  hint:
                                                      'label_send_message_hint'
                                                          .tr,
                                                  minLines: 1,
                                                  maxLines: 6,
                                                  style: const TextStyle(
                                                      fontSize: 17),
                                                  type: PlatformUtils.isDesktop
                                                      ? TextInputType.text
                                                      : TextInputType.multiline,
                                                  textInputAction:
                                                      TextInputAction.send,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _button(
                                              icon: const Padding(
                                                key: Key('SendForwardInModal'),
                                                padding: EdgeInsets.only(
                                                    left: 2, top: 1),
                                                child:
                                                    Icon(Icons.send, size: 24),
                                              ),
                                              onTap: c.sendForward.submit,
                                            ),
                                          ],
                                        )
                                      : TextButton(
                                          key: const Key('SendForwardInModal'),
                                          onPressed: c.selectedChats.isEmpty
                                              ? null
                                              : c.sendForward.submit,
                                          child: Text(
                                            (c.forwardItems.length < 2)
                                                ? 'btn_forward_message'.tr
                                                : 'btn_forward_messages'.tr,
                                            style: c.selectedChats.isEmpty
                                                ? font17.copyWith(
                                                    color: Colors.grey)
                                                : font17,
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  /// Returns an [InkWell] circular button with an [icon].
  Widget _button({
    void Function()? onTap,
    required Widget icon,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 0.5),
        child: Material(
          type: MaterialType.circle,
          color: Colors.white,
          elevation: 6,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              width: 42,
              height: 42,
              child: Center(child: icon),
            ),
          ),
        ),
      );

  /// Returns [ListTile] with [Chat]'s information.
  Widget _chat(
    ChatForwardController c,
    RxChat chat,
    TextStyle titleStyle,
  ) {
    return ListTile(
        key: Key('ForwardChat_${chat.chat.value.id.val}'),
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: (c.selectedChats
                      .firstWhereOrNull((e) => e == chat.chat.value.id) !=
                  null)
              ? const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white),
                )
              : AvatarWidget.fromChat(
                  chat.chat.value,
                  chat.title.value,
                  chat.avatar.value,
                  c.me,
                ),
        ),
        selected:
            (c.selectedChats.firstWhereOrNull((e) => e == chat.chat.value.id) !=
                    null)
                ? true
                : false,
        selectedTileColor: const Color(0x11000000),
        title: Text(chat.title(), style: titleStyle),
        onTap: () {
          if (c.selectedChats
                  .firstWhereOrNull((e) => e == chat.chat.value.id) !=
              null) {
            c.selectedChats.removeWhere((e) => e == chat.chat.value.id);
          } else {
            c.selectedChats.add(chat.chat.value.id);
          }
        });
  }
}
