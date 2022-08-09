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

import 'package:badges/badges.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/widget/avatar_image/controller.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/call/widget/animated_dots.dart';
import '/ui/page/home/page/chat/controller.dart' show ChatCallFinishReasonL10n;
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import 'controller.dart';
import 'create_group/controller.dart';

/// View of the `HomeTab.chats` tab.
class ChatsTabView extends StatelessWidget {
  const ChatsTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('ChatsTab'),
      init: ChatsTabController(Get.find(), Get.find(), Get.find(), Get.find()),
      builder: (ChatsTabController c) {
        return Scaffold(
          appBar: AppBar(
            title: Text('label_chats'.l10n),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(
                color: const Color(0xFFE0E0E0),
                height: 0.5,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (c) => const CreateGroupView(),
                ),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          body: Obx(
            () => c.chatsReady.value
                ? c.chats.isEmpty
                    ? Center(child: Text('label_no_chats'.l10n))
                    : ContextMenuInterceptor(
                        child: ListView(
                          controller: ScrollController(),
                          children: c.chats
                              .map(
                                (e) => KeyedSubtree(
                                  key: Key('Chat_${e.chat.value.id}'),
                                  child: buildChatTile(c, e),
                                ),
                              )
                              .toList(),
                        ),
                      )
                : const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  /// Reactive [ListTile] with [chat]'s information.
  Widget buildChatTile(ChatsTabController c, RxChat rxChat) => Obx(() {
        Chat chat = rxChat.chat.value;

        const Color subtitleColor = Color(0xFF666666);
        List<Widget>? subtitle;

        Iterable<String> typings = rxChat.typingUsers
            .where((e) => e.id != c.me)
            .map((e) => e.name?.val ?? e.num.val);

        if (chat.currentCall == null) {
          if (typings.isNotEmpty) {
            subtitle = [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(Icons.edit, size: 15),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        typings.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(typings.length > 1
                        ? 'label_typings'.l10n
                        : 'label_typing'.l10n),
                    const AnimatedDots(color: Colors.black)
                  ],
                ),
              )
            ];
          } else if (chat.lastItem != null) {
            if (chat.lastItem is ChatCall) {
              var item = chat.lastItem as ChatCall;
              String description = 'label_chat_call_ended'.l10n;
              if (item.finishedAt == null && item.finishReason == null) {
                subtitle = [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                    child: ElevatedButton(
                      onPressed: () => c.joinCall(chat.id),
                      child: Text('btn_join_call'.l10n),
                    ),
                  ),
                ];
              } else {
                description =
                    item.finishReason?.localizedString(item.authorId == c.me) ??
                        description;
                subtitle = [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 2, 6, 2),
                    child: Icon(Icons.call, size: 16, color: subtitleColor),
                  ),
                  Flexible(child: Text(description, maxLines: 2)),
                ];
              }
            } else if (chat.lastItem is ChatMessage) {
              var item = chat.lastItem as ChatMessage;

              var desc = StringBuffer();

              if (!chat.isGroup && item.authorId == c.me) {
                desc.write('${'label_you'.l10n}: ');
              }

              if (item.text != null) {
                desc.write(item.text!.val);
                if (item.attachments.isNotEmpty) {
                  desc.write(
                      ' [${item.attachments.length} ${'label_attachments'.l10n}]');
                }
              } else if (item.attachments.isNotEmpty) {
                desc.write(
                    '[${item.attachments.length} ${'label_attachments'.l10n}]');
              }

              subtitle = [
                if (chat.isGroup)
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: FutureBuilder<RxUser?>(
                      future: c.getUser(item.authorId),
                      builder: (_, snapshot) => snapshot.data != null
                          ? Obx(
                              () => AvatarWidget.fromUser(
                                snapshot.data!.user.value,
                                radius: 10,
                              ),
                            )
                          : AvatarWidget.fromUser(
                              chat.getUser(item.authorId),
                              radius: 10,
                            ),
                    ),
                  ),
                Flexible(child: Text(desc.toString(), maxLines: 2)),
              ];
            } else {
              // TODO: Implement other ChatItems.
            }
          }
        } else {
          subtitle = [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                child: ElevatedButton(
                  onPressed: () => c.joinCall(chat.id),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.call, size: 21, color: Colors.white),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'btn_join_call'.l10n,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 0, 4),
              child: ElevatedButton(
                onPressed: () => c.joinCall(chat.id, withVideo: true),
                child:
                    const Icon(Icons.video_call, size: 22, color: Colors.white),
              ),
            ),
          ];
        }

        return ContextMenuRegion(
          key: Key('ContextMenuRegion_${chat.id}'),
          preventContextMenu: false,
          menu: ContextMenu(
            actions: [
              ContextMenuButton(
                key: const Key('ButtonHideChat'),
                label: 'btn_hide_chat'.l10n,
                onPressed: () => c.hideChat(chat.id),
              ),
              if (chat.isGroup)
                ContextMenuButton(
                  key: const Key('ButtonLeaveChat'),
                  label: 'btn_leave_chat'.l10n,
                  onPressed: () => c.leaveChat(chat.id),
                ),
            ],
          ),
          child: GetBuilder(
              init: AvatarImageController(),
              builder: (AvatarImageController avatarController) {
                return MouseRegion(
                  onHover: avatarController.onHover,
                  onExit: avatarController.onHover,
                  child: ListTile(
                    leading: Obx(
                      () => Badge(
                        showBadge: rxChat.chat.value.isDialog &&
                            rxChat.members.values
                                    .firstWhereOrNull((e) => e.id != c.me)
                                    ?.user
                                    .value
                                    .online ==
                                true,
                        badgeContent: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          padding: const EdgeInsets.all(5),
                        ),
                        padding: const EdgeInsets.all(2),
                        badgeColor: Colors.white,
                        animationType: BadgeAnimationType.scale,
                        position: BadgePosition.bottomEnd(bottom: 0, end: 0),
                        elevation: 0,
                        child: AvatarWidget.fromRxChat(rxChat,
                            avatarImageController: avatarController),
                      ),
                    ),
                    title: Text(
                      rxChat.title.value,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    subtitle: subtitle == null
                        ? null
                        : DefaultTextStyle.merge(
                            style: const TextStyle(color: subtitleColor),
                            overflow: TextOverflow.ellipsis,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(children: subtitle),
                            ),
                          ),
                    trailing: chat.unreadCount == 0
                        ? null
                        : Badge(
                            toAnimate: false,
                            elevation: 0,
                            badgeContent: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text(
                                '${chat.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                    onTap: () => router.chat(chat.id),
                  ),
                );
              }),
        );
      });
}
