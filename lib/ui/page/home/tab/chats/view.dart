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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import 'package:messenger/api/backend/schema.dart' show ChatMemberInfoAction;
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/widget/animated_typing.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart' show ChatCallFinishReasonL10n;
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/custom_app_bar.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/chat_tile.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/custom_timer_widget.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/svg/svg.dart';
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
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            title: Text('label_chats'.l10n),
            leading: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const CreateGroupView(),
                  ),
                  icon: SvgLoader.asset(
                    'assets/icons/search.svg',
                    width: 17.77,
                  ),
                ),
              ),
            ],
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const CreateGroupView(),
                  ),
                  icon: SvgLoader.asset(
                    'assets/icons/group.svg',
                    height: 18.44,
                  ),
                ),
              ),
            ],
          ),
          body: Obx(() {
            if (c.chatsReady.value) {
              if (c.chats.isEmpty) {
                return Center(child: Text('label_no_chats'.l10n));
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ContextMenuInterceptor(
                  child: AnimationLimiter(
                    child: ListView.builder(
                      controller: ScrollController(),
                      itemCount: c.chats.length,
                      itemBuilder: (_, int i) {
                        final RxChat rxChat = c.chats[i];

                        return AnimationConfiguration.staggeredList(
                          position: i,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            horizontalOffset: 50,
                            child: FadeInAnimation(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: _ChatTileConfiguration(
                                  rxChat: rxChat,
                                  controller: c,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          }),
        );
      },
    );
  }
}

/// Reactive [ChatTile] with [RxChat]'s information.
class _ChatTileConfiguration extends StatelessWidget {
  const _ChatTileConfiguration({
    required this.rxChat,
    required this.controller,
  });

  /// Unified reactive [Chat] entity with its [ChatItem]s.
  final RxChat rxChat;

  /// Controller of the [HomeTab.chats] tab.
  final ChatsTabController controller;

  @override
  Widget build(BuildContext context) {
    final Chat chat = rxChat.chat.value;
    final Style style = Theme.of(context).extension<Style>()!;

    return ContextMenuRegion(
      key: Key('ContextMenuRegion_${chat.id}'),
      preventContextMenu: false,
      menu: ContextMenu(
        actions: [
          ContextMenuButton(
            key: const Key('ButtonHideChat'),
            label: 'btn_hide_chat'.l10n,
            onPressed: () => controller.hideChat(chat.id),
          ),
          if (chat.isGroup)
            ContextMenuButton(
              key: const Key('ButtonLeaveChat'),
              label: 'btn_leave_chat'.l10n,
              onPressed: () => controller.leaveChat(chat.id),
            ),
        ],
      ),
      child: Obx(
        () {
          return ChatTile(
            leading: AvatarWidget.fromRxChat(rxChat, radius: 30),
            trailing: _trailing(controller, chat),
            title: _title(context, controller, rxChat, style.subtitle2Color),
            subtitle: _extendedSubtitle(
                context, controller, rxChat, style.subtitleColor),
            style: style,
            selected: router.routeStartsWith(
              Routes.chat,
              '${Routes.chat}/${chat.id}',
            ),
            onTap: () => router.chat(chat.id),
          );
        },
      ),
    );
  }

  /// Creates [_subtitle] with a count of unread [ChatItem].
  Widget _extendedSubtitle(
    BuildContext context,
    ChatsTabController c,
    RxChat rxChat,
    Color subtitleColor,
  ) {
    final Chat chat = rxChat.chat.value;

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          const SizedBox(height: 3),
          Expanded(
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.subtitle2!,
              overflow: TextOverflow.ellipsis,
              child: Row(
                children: _subtitle(context, c, rxChat, subtitleColor) ?? [],
              ),
            ),
          ),
          if (chat.unreadCount != 0) ...[
            const SizedBox(width: 10),
            Container(
              height: 20,
              width: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
              padding: const EdgeInsets.all(2),
              alignment: Alignment.center,
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Creates additional content displayed below the title.
  List<Widget>? _subtitle(
    BuildContext context,
    ChatsTabController c,
    RxChat rxChat,
    Color subtitleColor,
  ) {
    final Chat chat = rxChat.chat.value;
    final Iterable<String> typings = rxChat.typingUsers
        .where((User user) => user.id != c.me)
        .map((User user) => user.name?.val ?? user.num.val);
    List<Widget>? subtitle;
    ChatItem? item;
    if (rxChat.messages.isNotEmpty) {
      item = rxChat.messages.last.value;
    }

    item ??= chat.lastItem;

    if (typings.isNotEmpty) {
      if (!rxChat.chat.value.isGroup) {
        subtitle = [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'label_typing'.l10n,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 3),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: AnimatedTyping(),
              ),
            ],
          ),
        ];
      } else {
        subtitle = [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    typings.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: AnimatedTyping(),
                ),
              ],
            ),
          )
        ];
      }
    } else if (item != null) {
      if (item is ChatCall) {
        final Widget widget = Padding(
          padding: const EdgeInsets.fromLTRB(0, 2, 6, 2),
          child: Icon(Icons.call, size: 16, color: subtitleColor),
        );

        if (item.finishedAt == null && item.finishReason == null) {
          subtitle = [
            widget,
            Flexible(child: Text('label_call_active'.l10n, maxLines: 2)),
          ];
        } else {
          final String description =
              item.finishReason?.localizedString(item.authorId == c.me) ??
                  'label_chat_call_ended'.l10n;
          subtitle = [
            widget,
            Flexible(child: Text(description, maxLines: 2)),
          ];
        }
      } else if (item is ChatMessage) {
        final desc = StringBuffer();

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
                        chat.getUser(item!.authorId),
                        radius: 10,
                      ),
              ),
            ),
          Flexible(child: Text(desc.toString(), maxLines: 2)),
          ElasticAnimatedSwitcher(
            child: item.status.value == SendingStatus.sending
                ? const Icon(Icons.access_alarm, size: 15)
                : item.status.value == SendingStatus.error
                    ? const Icon(
                        Icons.error_outline,
                        size: 15,
                        color: Colors.red,
                      )
                    : const SizedBox.shrink(),
          ),
        ];
      } else if (item is ChatForward) {
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
                        chat.getUser(item!.authorId),
                        radius: 10,
                      ),
              ),
            ),
          Flexible(child: Text('[${'label_forwarded_message'.l10n}]')),
          ElasticAnimatedSwitcher(
            child: item.status.value == SendingStatus.sending
                ? const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.access_alarm, size: 15),
                  )
                : item.status.value == SendingStatus.error
                    ? const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.error_outline,
                          size: 15,
                          color: Colors.red,
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ];
      } else if (item is ChatMemberInfo) {
        Widget content = Text('${item.action}');

        switch (item.action) {
          case ChatMemberInfoAction.created:
            content = const Text('Chat created');
            break;

          case ChatMemberInfoAction.added:
            content = Text('${item.user.name ?? item.user.num} was added');
            break;

          case ChatMemberInfoAction.removed:
            content = Text('${item.user.name ?? item.user.num} was removed');
            break;

          case ChatMemberInfoAction.artemisUnknown:
            // No-op.
            break;
        }

        subtitle = [Flexible(child: content)];
      } else {
        subtitle = [
          Flexible(child: Text('label_empty_message'.l10n, maxLines: 2))
        ];
      }
    }

    return subtitle;
  }

  /// Creates a widget to display after the title.
  Widget? _trailing(ChatsTabController c, Chat chat) {
    if (chat.currentCall != null) {
      final Widget dropButton = WidgetButton(
        key: const Key('Drop'),
        onPressed: () => c.dropCall(chat.id),
        child: Container(
          key: const Key('Drop'),
          height: 32,
          width: 32,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgLoader.asset(
              'assets/icons/call_end.svg',
              width: 32,
              height: 32,
            ),
          ),
        ),
      );
      final Widget joinButton = WidgetButton(
        key: const Key('Join'),
        onPressed: () => c.joinCall(chat.id),
        child: Container(
          key: const Key('Join'),
          height: 32,
          width: 32,
          decoration: const BoxDecoration(
            color: Color(0xFF63B4FF),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgLoader.asset(
              'assets/icons/audio_call_start.svg',
              width: 15,
              height: 15,
            ),
          ),
        ),
      );

      return Column(
        children: [
          const SizedBox(width: 10),
          AnimatedSwitcher(
            key: const Key('ActiveCallButton'),
            duration: 300.milliseconds,
            child: c.isInCall(chat.id) ? dropButton : joinButton,
          ),
        ],
      );
    } else {
      return null;
    }
  }

  /// Creates the primary content of the chat tile.
  Widget _title(
    BuildContext context,
    ChatsTabController c,
    RxChat rxChat,
    Color subtitle2Color,
  ) {
    final Chat chat = rxChat.chat.value;
    final int? microsecondsSinceEpoch =
        c.getCallStart(chat.id)?.microsecondsSinceEpoch;
    final TextStyle? textStyle = Theme.of(context)
        .textTheme
        .subtitle2
        ?.copyWith(color: chat.currentCall == null ? null : subtitle2Color);

    return Row(
      children: [
        Expanded(
          child: Text(
            rxChat.title.value,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.headline5,
          ),
        ),
        const SizedBox(height: 10),
        if (chat.currentCall == null &&
            chat.lastDelivery.microsecondsSinceEpoch != 0)
          Text(
            chat.lastDelivery.toDate(),
            style: textStyle,
          ),
        if (chat.currentCall != null && microsecondsSinceEpoch != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CustomTimerWidget(
              duration: const Duration(seconds: 1),
              getWidget: () => Text(
                Duration(
                  microseconds: DateTime.now().microsecondsSinceEpoch -
                      microsecondsSinceEpoch,
                ).hhMmSs(),
                style: textStyle,
              ),
            ),
          ),
      ],
    );
  }
}
