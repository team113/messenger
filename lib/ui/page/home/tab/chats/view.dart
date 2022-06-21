import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
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
            title: Text('label_chats'.tr),
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
                    ? Center(child: Text('label_no_chats'.tr))
                    : ContextMenuInterceptor(
                        child: ListView(
                          controller: ScrollController(),
                          children:
                              c.chats.map((e) => buildChatTile(c, e)).toList(),
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
                        ? 'label_typings'.tr
                        : 'label_typing'.tr),
                    const AnimatedDots(color: Colors.black)
                  ],
                ),
              )
            ];
          } else if (chat.lastItem != null) {
            if (chat.lastItem is ChatCall) {
              var item = chat.lastItem as ChatCall;
              String description = 'label_chat_call_ended'.tr;
              if (item.finishedAt == null && item.finishReason == null) {
                subtitle = [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                    child: ElevatedButton(
                      onPressed: () => c.joinCall(chat.id),
                      child: Text('btn_chat_join_call'.tr),
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
                desc.write('${'label_you'.tr}: ');
              }

              if (item.text != null) {
                desc.write(item.text!.val);
                if (item.attachments.isNotEmpty) {
                  desc.write(
                      ' [${item.attachments.length} ${'label_attachments'.tr}]');
                }
              } else if (item.attachments.isNotEmpty) {
                desc.write(
                    '[${item.attachments.length} ${'label_attachments'.tr}]');
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
                  child: Text(
                    'btn_chat_join_call'.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                label: 'btn_hide_chat'.tr,
                onPressed: () => c.hideChat(chat.id),
              ),
              if (chat.isGroup)
                ContextMenuButton(
                  key: const Key('ButtonLeaveChat'),
                  label: 'btn_leave_chat'.tr,
                  onPressed: () => c.leaveChat(chat.id),
                ),
            ],
          ),
          child: ListTile(
            leading: AvatarWidget.fromRxChat(rxChat),
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
      });
}
