import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller.dart';
import '/api/backend/schema.dart' show ChatMemberInfoAction;
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/tab/chats/widget/periodic_builder.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/chat_tile.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// [ChatTile] filled with [RxChat]'s information.
class RecentChatTile extends StatelessWidget {
  const RecentChatTile(this.c, this.rxChat, {Key? key}) : super(key: key);

  /// [RxChat] this [RecentChatTile] is about.
  final RxChat rxChat;

  /// [ChatsTabController] of a [ChatsTabView] displaying this [RecentChatTile].
  final ChatsTabController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Chat chat = rxChat.chat.value;

      final TextStyle? text = Theme.of(context).textTheme.subtitle2?.copyWith(
            color: chat.ongoingCall == null
                ? null
                : Theme.of(context).colorScheme.secondary,
          );

      final bool selected = router.routes
              .lastWhereOrNull((e) => e.startsWith(Routes.chat))
              ?.startsWith('${Routes.chat}/${chat.id}') ==
          true;

      return ChatTile(
        chat: rxChat,
        title: [
          const SizedBox(height: 10),
          if (chat.ongoingCall == null &&
              chat.lastDelivery.microsecondsSinceEpoch != 0)
            Text(chat.lastDelivery.val.toLocal().toShortAgo(), style: text),
          if (chat.ongoingCall != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PeriodicBuilder(
                period: const Duration(seconds: 1),
                builder: (_) {
                  return Text(
                    DateTime.now()
                        .difference(chat.ongoingCall!.at.val)
                        .hhMmSs(),
                    style: text,
                  );
                },
              ),
            ),
        ],
        subtitle: [
          const SizedBox(height: 5),
          SizedBox(
            height: 23,
            child: Row(
              children: [
                const SizedBox(height: 3),
                Expanded(child: _subtitle(context)),
                _status(context),
                _counter(),
              ],
            ),
          ),
        ],
        trailing: [_callButtons(context)],
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
        selected: selected,
        onTap: () => router.chat(chat.id),
      );
    });
  }

  /// Builds a subtitle for the provided [RxChat] containing either its
  /// [Chat.lastItem] or an [AnimatedTyping] indicating an ongoing typing.
  Widget _subtitle(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;
    final Chat chat = rxChat.chat.value;

    final ChatItem? item;
    if (rxChat.messages.isNotEmpty) {
      item = rxChat.messages.last.value;
    } else {
      item = chat.lastItem;
    }

    List<Widget> subtitle = [];

    final Iterable<String> typings = rxChat.typingUsers
        .where((User user) => user.id != c.me)
        .map((User user) => user.name?.val ?? user.num.val);

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
                    typings.join('comma_space'.l10n),
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
          child: Icon(Icons.call, size: 16, color: style.subtitleColor),
        );

        if (item.finishedAt == null && item.finishReason == null) {
          subtitle = [
            widget,
            Flexible(child: Text('label_call_active'.l10n)),
          ];
        } else {
          final String description =
              item.finishReason?.localizedString(item.authorId == c.me) ??
                  'label_chat_call_ended'.l10n;
          subtitle = [widget, Flexible(child: Text(description))];
        }
      } else if (item is ChatMessage) {
        final desc = StringBuffer();

        if (!chat.isGroup && item.authorId == c.me) {
          desc.write('${'label_you'.l10n}${'colon_space'.l10n}');
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
                    ? AvatarWidget.fromRxUser(snapshot.data, radius: 10)
                    : AvatarWidget.fromUser(
                        chat.getUser(item!.authorId),
                        radius: 10,
                      ),
              ),
            ),
          Flexible(child: Text(desc.toString())),
        ];
      } else if (item is ChatForward) {
        subtitle = [
          if (chat.isGroup)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: FutureBuilder<RxUser?>(
                future: c.getUser(item.authorId),
                builder: (_, snapshot) => snapshot.data != null
                    ? AvatarWidget.fromRxUser(snapshot.data, radius: 10)
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
            content = Text(
              'label_chat_was_added'
                  .l10nfmt({'who': '${item.user.name ?? item.user.num}'}),
            );
            break;

          case ChatMemberInfoAction.removed:
            content = Text(
              'label_chat_was_removed'
                  .l10nfmt({'who': '${item.user.name ?? item.user.num}'}),
            );
            break;

          case ChatMemberInfoAction.artemisUnknown:
            // No-op.
            break;
        }

        subtitle = [Flexible(child: content)];
      } else {
        subtitle = [Flexible(child: Text('label_empty_message'.l10n))];
      }
    }

    return DefaultTextStyle(
      style: Theme.of(context).textTheme.subtitle2!,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      child: Row(children: subtitle),
    );
  }

  /// Builds a [ChatItem.status] visual representation.
  Widget _status(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Obx(() {
      final Chat chat = rxChat.chat.value;

      final ChatItem? item;
      if (rxChat.messages.isNotEmpty) {
        item = rxChat.messages.last.value;
      } else {
        item = chat.lastItem;
      }

      if (item?.authorId == c.me) {
        final bool isSent = item?.status.value == SendingStatus.sent;
        final bool isRead = chat.lastReads.firstWhereOrNull((LastChatRead l) =>
                    l.memberId != c.me && !l.at.isBefore(item!.at)) !=
                null &&
            isSent;
        final bool isDelivered =
            isSent && !chat.lastDelivery.isBefore(item!.at);
        final bool isError = item?.status.value == SendingStatus.error;
        final bool isSending = item?.status.value == SendingStatus.sending;

        return Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Icon(
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
        );
      }

      return const SizedBox();
    });
  }

  /// Returns a visual representation of the [Chat.unreadCount].
  Widget _counter() {
    return Obx(() {
      final Chat chat = rxChat.chat.value;

      if (chat.unreadCount > 0) {
        return Container(
          key: const Key('UnreadMessages'),
          margin: const EdgeInsets.only(left: 10),
          width: 23,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
          alignment: Alignment.center,
          child: Text(
            '${chat.unreadCount > 99 ? '99${'plus'.l10n}' : chat.unreadCount}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.center,
          ),
        );
      }

      return const SizedBox(key: Key('NoUnreadMessages'));
    });
  }

  /// Returns a drop or join call button, if any [OngoingCall] is happening in
  /// this [Chat].
  Widget _callButtons(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Obx(() {
        final Chat chat = rxChat.chat.value;
        final Widget trailing;

        if (chat.ongoingCall != null) {
          if (c.hasCall(chat.id)) {
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
                  color: Theme.of(context).colorScheme.secondary,
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

        return AnimatedSwitcher(
          duration: 300.milliseconds,
          child: trailing,
        );
      }),
    );
  }
}

/// Extension adding conversion from [DateTime] to its short text [difference]
/// relative to the [DateTime.now].
extension _DateTimeToShortAgo on DateTime {
  /// Returns short text representation of a [difference] with [DateTime.now]
  /// indicating how long ago this [DateTime] happened compared to
  /// [DateTime.now].
  String toShortAgo() {
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
