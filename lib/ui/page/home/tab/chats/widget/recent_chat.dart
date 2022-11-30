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
import 'package:get/get.dart';

import '/api/backend/schema.dart' show ChatMemberInfoAction;
import '/config.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/page/chat/widget/video_thumbnail/video_thumbnail.dart';
import '/ui/page/home/tab/chats/widget/periodic_builder.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/chat_tile.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';

/// [ChatTile] representing the provided [RxChat] as a recent [Chat].
class RecentChatTile extends StatelessWidget {
  const RecentChatTile(
    this.rxChat, {
    Key? key,
    this.me,
    this.getUser,
    this.inCall,
    this.onLeave,
    this.onHide,
    this.onDrop,
    this.onJoin,
    this.onMute,
    this.onUnmute,
  }) : super(key: key);

  /// [RxChat] this [RecentChatTile] is about.
  final RxChat rxChat;

  /// [UserId] of the authenticated [MyUser].
  final UserId? me;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId id)? getUser;

  /// Callback, called to check whether this device of the currently
  /// authenticated [MyUser] takes part in the [Chat.ongoingCall], if any.
  final bool Function()? inCall;

  /// Callback, called when this [rxChat] leave action is triggered.
  final void Function()? onLeave;

  /// Callback, called when this [rxChat] hide action is triggered.
  final void Function()? onHide;

  /// Callback, called when a drop [Chat.ongoingCall] in this [rxChat] action is
  /// triggered.
  final void Function()? onDrop;

  /// Callback, called when a join [Chat.ongoingCall] in this [rxChat] action is
  /// triggered.
  final void Function()? onJoin;

  /// Callback, called when this [rxChat] mute action is triggered.
  final void Function()? onMute;

  /// Callback, called when this [rxChat] unmute action is triggered.
  final void Function()? onUnmute;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Chat chat = rxChat.chat.value;

      final bool selected = router.routes
              .lastWhereOrNull((e) => e.startsWith(Routes.chat))
              ?.startsWith('${Routes.chat}/${chat.id}') ==
          true;

      return ChatTile(
        chat: rxChat,
        title: [
          if (chat.muted != null) ...[
            const SizedBox(width: 5),
            Icon(
              Icons.volume_off,
              size: 17,
              color: Theme.of(context).primaryIconTheme.color,
              key: Key('MuteIndicator_${chat.id}'),
            ),
            const SizedBox(width: 5),
          ],
        ],
        status: [
          _status(context),
          Text(
            chat.updatedAt.val.toLocal().toShort(),
            style: Theme.of(context).textTheme.subtitle2,
          ),
        ],
        subtitle: [
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 38),
            child: Row(
              children: [
                const SizedBox(height: 3),
                Expanded(child: _subtitle(context)),
                _counter(),
              ],
            ),
          ),
        ],
        actions: [
          ContextMenuButton(
            key: const Key('ButtonHideChat'),
            label: 'btn_hide_chat'.l10n,
            onPressed: onHide,
          ),
          if (chat.isGroup)
            ContextMenuButton(
              key: const Key('ButtonLeaveChat'),
              label: 'btn_leave_chat'.l10n,
              onPressed: onLeave,
            ),
          chat.muted == null
              ? ContextMenuButton(
                  key: const Key('MuteChatButton'),
                  label: 'btn_mute_chat'.l10n,
                  onPressed: onMute,
                )
              : ContextMenuButton(
                  key: const Key('UnmuteChatButton'),
                  label: 'btn_unmute_chat'.l10n,
                  onPressed: onUnmute,
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
    final Chat chat = rxChat.chat.value;

    if (chat.ongoingCall != null) {
      final Widget trailing = WidgetButton(
        key: inCall?.call() == true
            ? const Key('JoinCallButton')
            : const Key('DropCallButton'),
        onPressed: inCall?.call() == true ? onDrop : onJoin,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: inCall?.call() == true
                ? Colors.red
                : Theme.of(context).colorScheme.secondary,
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
                Icon(
                  inCall?.call() == true ? Icons.call_end : Icons.call,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                if (constraints.maxWidth > 110)
                  Expanded(
                    child: Text(
                      inCall?.call() == true
                          ? 'btn_call_end'.l10n
                          : 'btn_join_call'.l10n,
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2
                          ?.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(width: 8),
                PeriodicBuilder(
                  period: const Duration(seconds: 1),
                  builder: (_) {
                    return Text(
                      DateTime.now()
                          .difference(chat.ongoingCall!.at.val)
                          .hhMmSs(),
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2
                          ?.copyWith(color: Colors.white),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            );
          }),
        ),
      );

      return DefaultTextStyle(
        style: Theme.of(context).textTheme.subtitle2!,
        overflow: TextOverflow.ellipsis,
        child: AnimatedSwitcher(duration: 300.milliseconds, child: trailing),
      );
    }

    final ChatItem? item;
    if (rxChat.messages.isNotEmpty) {
      item = rxChat.messages.last.value;
    } else {
      item = chat.lastItem;
    }

    List<Widget> subtitle = [];

    final Iterable<String> typings = rxChat.typingUsers
        .where((User user) => user.id != me)
        .map((User user) => user.name?.val ?? user.num.val);

    ChatMessage? draft = rxChat.draft.value;

    if (draft != null && router.routes.last != '${Routes.chat}/${chat.id}') {
      final StringBuffer desc = StringBuffer();

      if (draft.text != null) {
        desc.write(draft.text!.val);
      }

      if (draft.repliesTo.isNotEmpty) {
        if (desc.isNotEmpty) desc.write('space'.l10n);
        desc.write('label_replies'.l10nfmt({'count': draft.repliesTo.length}));
      }

      final List<Widget> images = [];

      if (draft.attachments.isNotEmpty) {
        if (draft.text == null) {
          images.addAll(
            draft.attachments.map((e) {
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: _attachment(e),
              );
            }),
          );
        } else {
          images.add(
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _attachment(draft.attachments.first),
            ),
          );
        }
      }

      subtitle = [
        Text('${'label_draft'.l10n}${'colon_space'.l10n}'),
        if (desc.isEmpty)
          Flexible(
            child: LayoutBuilder(builder: (_, constraints) {
              return Row(
                children: images
                    .take((constraints.maxWidth / (30 + 4)).floor())
                    .toList(),
              );
            }),
          )
        else
          ...images,
        if (desc.isNotEmpty)
          Flexible(
            child: Text(
              desc.toString(),
              key: const Key('Draft'),
            ),
          ),
      ];
    } else if (typings.isNotEmpty) {
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
        const Widget widget = Padding(
          padding: EdgeInsets.fromLTRB(0, 2, 6, 2),
          child: Icon(Icons.call, size: 16, color: Color(0xFF666666)),
        );

        if (item.finishedAt == null && item.finishReason == null) {
          subtitle = [
            widget,
            Flexible(child: Text('label_call_active'.l10n)),
          ];
        } else {
          final String description =
              item.finishReason?.localizedString(item.authorId == me) ??
                  'label_chat_call_ended'.l10n;
          subtitle = [widget, Flexible(child: Text(description))];
        }
      } else if (item is ChatMessage) {
        final desc = StringBuffer();

        if (item.text != null) {
          desc.write(item.text!.val);
        }

        final List<Widget> images = [];

        if (item.attachments.isNotEmpty) {
          if (item.text == null) {
            images.addAll(
              item.attachments.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: _attachment(
                    e,
                    onError: () async {
                      if (rxChat.chat.value.lastItem != null) {
                        await rxChat
                            .updateAttachments(rxChat.chat.value.lastItem!);
                      }
                    },
                  ),
                );
              }),
            );
          } else {
            images.add(
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _attachment(
                  item.attachments.first,
                  onError: () async {
                    if (rxChat.chat.value.lastItem != null) {
                      await rxChat
                          .updateAttachments(rxChat.chat.value.lastItem!);
                    }
                  },
                ),
              ),
            );
          }
        }

        subtitle = [
          if (item.authorId == me)
            Text('${'label_you'.l10n}${'colon_space'.l10n}')
          else if (chat.isGroup)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: FutureBuilder<RxUser?>(
                future: getUser?.call(item.authorId),
                builder: (_, snapshot) => snapshot.data != null
                    ? AvatarWidget.fromRxUser(snapshot.data, radius: 10)
                    : AvatarWidget.fromUser(
                        chat.getUser(item!.authorId),
                        radius: 10,
                      ),
              ),
            ),
          if (desc.isEmpty)
            Flexible(
              child: LayoutBuilder(builder: (_, constraints) {
                return Row(
                  children: images
                      .take((constraints.maxWidth / (30 + 4)).floor())
                      .toList(),
                );
              }),
            )
          else
            ...images,
          if (desc.isNotEmpty) Flexible(child: Text(desc.toString())),
        ];
      } else if (item is ChatForward) {
        subtitle = [
          if (chat.isGroup)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: FutureBuilder<RxUser?>(
                future: getUser?.call(item.authorId),
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
            if (chat.isGroup) {
              content = Text('label_group_created'.l10n);
            } else {
              content = Text('label_dialog_created'.l10n);
            }
            break;

          case ChatMemberInfoAction.added:
            content = Text(
              'label_was_added'
                  .l10nfmt({'who': '${item.user.name ?? item.user.num}'}),
            );
            break;

          case ChatMemberInfoAction.removed:
            content = Text(
              'label_was_removed'
                  .l10nfmt({'who': '${item.user.name ?? item.user.num}'}),
            );
            break;

          case ChatMemberInfoAction.artemisUnknown:
            content = Text(item.action.toString());
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
      child: Row(children: subtitle),
    );
  }

  /// Builds an [Attachment] visual representation.
  Widget _attachment(Attachment e, {Future<void> Function()? onError}) {
    Widget? content;

    if (e is LocalAttachment) {
      if (e.file.isImage && e.file.bytes != null) {
        content = Image.memory(e.file.bytes!, fit: BoxFit.cover);
      } else if (e.file.isVideo) {
        // TODO: `video_player` being used doesn't support desktop platforms.
        if ((PlatformUtils.isMobile || PlatformUtils.isWeb) &&
            e.file.bytes != null) {
          content = FittedBox(
            fit: BoxFit.cover,
            child: VideoThumbnail.bytes(
              bytes: e.file.bytes!,
              key: key,
              height: 300,
            ),
          );
        } else {
          content = Container(
            color: Colors.grey,
            child: const Icon(
              Icons.video_file,
              size: 18,
              color: Colors.white,
            ),
          );
        }
      } else {
        content = Container(
          color: Colors.grey,
          child: SvgLoader.asset(
            'assets/icons/file.svg',
            width: 30,
            height: 30,
          ),
        );
      }
    }

    if (e is ImageAttachment) {
      content = RetryImage(
        e.medium.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        onForbidden: onError,
      );
    }

    if (e is FileAttachment) {
      if (e.isVideo) {
        if (PlatformUtils.isMobile || PlatformUtils.isWeb) {
          content = FittedBox(
            fit: BoxFit.cover,
            child: VideoThumbnail.url(
              url: e.original.url,
              key: key,
              height: 300,
              onError: onError,
            ),
          );
        } else {
          content = Container(
            color: Colors.grey,
            child: const Icon(
              Icons.video_file,
              size: 18,
              color: Colors.white,
            ),
          );
        }
      } else {
        content = Container(
          color: Colors.grey,
          child: SvgLoader.asset(
            'assets/icons/file.svg',
            width: 30,
            height: 30,
          ),
        );
      }
    }

    if (content != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(
          width: 30,
          height: 30,
          child: content,
        ),
      );
    }

    return const SizedBox();
  }

  /// Builds a [ChatItem.status] visual representation.
  Widget _status(BuildContext context) {
    return Obx(() {
      final Chat chat = rxChat.chat.value;

      final ChatItem? item;
      if (rxChat.messages.isNotEmpty) {
        item = rxChat.messages.last.value;
      } else {
        item = chat.lastItem;
      }

      if (item != null && item.authorId == me) {
        final bool isSent = item.status.value == SendingStatus.sent;
        final bool isRead = chat.isRead(item, me) && isSent;
        final bool isDelivered = isSent && !chat.lastDelivery.isBefore(item.at);
        final bool isError = item.status.value == SendingStatus.error;
        final bool isSending = item.status.value == SendingStatus.sending;

        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            isRead || isDelivered
                ? Icons.done_all
                : isSending
                    ? Icons.access_alarm
                    : isError
                        ? Icons.error_outline
                        : Icons.done,
            color: isRead
                ? Theme.of(context).colorScheme.secondary
                : isError
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
            size: 16,
          ),
        );
      }

      return const SizedBox();
    });
  }

  /// Returns a visual representation of the [Chat.unreadCount] counter.
  Widget _counter() {
    return Obx(() {
      final Chat chat = rxChat.chat.value;

      if (chat.unreadCount > 0) {
        return Container(
          key: const Key('UnreadMessages'),
          margin: const EdgeInsets.only(left: 4),
          width: 23,
          height: 23,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
          alignment: Alignment.center,
          child: Text(
            // TODO: Implement and test notations like `4k`, `54m`, etc.
            chat.unreadCount > 99 ? '99${'plus'.l10n}' : '${chat.unreadCount}',
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
}

/// Extension adding conversion from [DateTime] to its short text relative to
/// the [DateTime.now].
extension DateTimeToShort on DateTime {
  /// Returns short text representing this [DateTime].
  ///
  /// Returns string in format `HH:MM`, if [DateTime] is within today. Returns a
  /// short weekday name, if [difference] between this [DateTime] and
  /// [DateTime.now] is less than 7 days. Otherwise returns a string in format
  /// of `YYYY-MM-DD`.
  String toShort() {
    final DateTime now = DateTime.now();
    final DateTime from = DateTime(now.year, now.month, now.day);
    final DateTime to = DateTime(year, month, day);

    final int differenceInDays = from.difference(to).inDays;

    if (differenceInDays > 6) {
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
