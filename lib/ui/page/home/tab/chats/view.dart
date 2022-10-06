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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show ChatMemberInfoAction;
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
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/custom_app_bar.dart';
import '/ui/widget/chat_tile.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import 'controller.dart';
import 'create_group/controller.dart';
import 'widget/periodic_builder.dart';

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
                                child: _ChatTile(c, rxChat),
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
class _ChatTile extends StatelessWidget {
  const _ChatTile(this.c, this.rxChat);

  /// Unified reactive [Chat] entity with its [ChatItem]s.
  final RxChat rxChat;

  /// Controller of the [HomeTab.chats] tab.
  final ChatsTabController c;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Obx(() {
      final Chat chat = rxChat.chat.value;

      final DateTime? startCall = c.getCallStart(chat.id)?.val;

      final TextStyle? textStyle = Theme.of(context)
          .textTheme
          .subtitle2
          ?.copyWith(
              color: chat.ongoingCall == null
                  ? null
                  : Theme.of(context).colorScheme.secondary);

      bool selected = router.routes
              .lastWhereOrNull((e) => e.startsWith(Routes.chat))
              ?.startsWith('${Routes.chat}/${chat.id}') ==
          true;

      final Widget trailing;

      if (chat.ongoingCall != null) {
        if (c.isInCall(chat.id)) {
          trailing = WidgetButton(
            key: const Key('DropCallButton'),
            onPressed: () => c.dropCall(chat.id),
            child: Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: style.dropButtonColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgLoader.asset(
                  'assets/icons/call_end.svg',
                  width: 38,
                  height: 38,
                ),
              ),
            ),
          );
        } else {
          trailing = WidgetButton(
            key: const Key('JoinCallButton'),
            onPressed: () => c.joinCall(chat.id),
            child: Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: style.joinButtonColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgLoader.asset(
                  'assets/icons/audio_call_start.svg',
                  width: 18,
                  height: 18,
                ),
              ),
            ),
          );
        }
      } else {
        trailing = const SizedBox.shrink(key: Key('NoCall'));
      }

      return ChatTile(
        chat: rxChat,
        title: [
          const SizedBox(height: 10),
          if (chat.ongoingCall == null &&
              chat.lastDelivery.microsecondsSinceEpoch != 0)
            Text(
              chat.lastDelivery.val.toLocal().toDateOrWeekdayOrTime(),
              style: textStyle,
            ),
          if (chat.ongoingCall != null && startCall != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PeriodicBuilder(
                period: const Duration(seconds: 1),
                builder: (_) {
                  return Text(
                    DateTime.now().difference(startCall).hhMmSs(),
                    style: textStyle,
                  );
                },
              ),
            ),
        ],
        subtitle: [
          const SizedBox(height: 7),
          SizedBox(
            height: 23,
            child: Row(
              children: [
                const SizedBox(height: 3),
                Expanded(
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.subtitle2!,
                    overflow: TextOverflow.ellipsis,
                    child: _subtitle(context, c, rxChat, style.subtitleColor),
                  ),
                ),
                ..._messsageStatus(c, chat, style),
                if (chat.unreadCount != 0) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 23,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${chat.unreadCount > 99 ? '99+' : chat.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        trailing: [
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child:
                AnimatedSwitcher(duration: 300.milliseconds, child: trailing),
          )
        ],
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
        style: style,
        selected: selected,
        onTap: () => router.chat(chat.id),
      );
    });
  }

  /// Gets message status widget.
  List<Widget> _messsageStatus(ChatsTabController c, Chat chat, Style style) {
    ChatItem? item = chat.lastItem;

    if (item?.authorId == c.me) {
      final bool isSent = item?.status.value == SendingStatus.sent;

      final bool isRead = chat.lastReads.firstWhereOrNull((LastChatRead l) =>
                  l.memberId != c.me && !l.at.isBefore(item!.at)) !=
              null &&
          isSent;

      final bool isDelivered = isSent && !chat.lastDelivery.isBefore(item!.at);

      final bool isError = item?.status.value == SendingStatus.error;

      final bool isSending = item?.status.value == SendingStatus.sending;

      if (isSent || isDelivered || isRead || isSending || isError) {
        return [
          const SizedBox(width: 10),
          Icon(
            (isRead || isDelivered)
                ? Icons.done_all
                : isSending
                    ? Icons.access_alarm
                    : isError
                        ? Icons.error_outline
                        : Icons.done,
            color: isRead
                ? style.statusMessageRead
                : isError
                    ? style.statusMessageError
                    : style.statusMessageNotRead,
            size: 16,
          ),
        ];
      }
    }

    return [];
  }

  /// Creates additional content displayed below the title.
  Widget _subtitle(
    BuildContext context,
    ChatsTabController c,
    RxChat rxChat,
    Color subtitleColor,
  ) {
    final Iterable<String> typings = rxChat.typingUsers
        .where((User user) => user.id != c.me)
        .map((User user) => user.name?.val ?? user.num.val);

    final Chat chat = rxChat.chat.value;

    final ChatItem? item;
    if (rxChat.messages.isNotEmpty) {
      item = rxChat.messages.last.value;
    } else {
      item = chat.lastItem;
    }

    List<Widget> subtitle = [];

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
        ];
      } else if (item is ChatMemberInfo) {
        Widget content = Text('${item.action}');

        switch (item.action) {
          case ChatMemberInfoAction.created:
            content = Text('label_chat_created'.l10n);
            break;

          case ChatMemberInfoAction.added:
            content = Text('label_chat_was_added'
                .l10nfmt({'who': item.user.name ?? item.user.num}));
            break;

          case ChatMemberInfoAction.removed:
            content = Text('label_chat_was_removed'
                .l10nfmt({'who': item.user.name ?? item.user.num}));
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

    return Row(children: subtitle);
  }
}

/// Extension adding conversion to formatted date from a [DateTime].
extension _AdditionalFormatting on DateTime {
  /// Converts [DateTime] to a date string or day of the week or time.
  ///
  /// If the date is today, then output the time, if less than a week, then output
  /// the day of the week, otherwise the date is in the format yyyy-mm-dd.
  String toDateOrWeekdayOrTime() {
    final int differenceInDays = DateTime.now().difference(this).inDays;

    if (differenceInDays > 7) {
      final String day = this.day.toString().padLeft(2, '0');
      final String month = this.month.toString().padLeft(2, '0');

      return '$year-$month-$day';
    } else if (differenceInDays < 1) {
      final String hour = this.hour.toString().padLeft(2, '0');
      final String minute = this.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    } else {
      return 'label_short_weekday'.l10nfmt({'weekday': weekday});
    }
  }
}
