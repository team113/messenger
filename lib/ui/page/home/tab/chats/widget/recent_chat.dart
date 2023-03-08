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

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/field_button.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/skeleton_container.dart';
import 'package:messenger/util/message_popup.dart';
// import 'package:shimmer/shimmer.dart';
import 'package:skeletons/skeletons.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
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
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [ChatTile] representing the provided [RxChat] as a recent [Chat].
class RecentChatTile extends StatelessWidget {
  const RecentChatTile(
    this.rxChat, {
    super.key,
    this.me,
    this.myUser,
    this.blocked = false,
    this.getUser,
    this.inCall,
    this.onLeave,
    this.onHide,
    this.onDrop,
    this.onJoin,
    this.onMute,
    this.onUnmute,
    this.onFavorite,
    this.onUnfavorite,
    this.onSelect,
    this.onCreateGroup,
    this.trailing = const [],
    this.onTap,
    this.selected = false,
    Widget Function(Widget)? avatarBuilder,
  }) : avatarBuilder = avatarBuilder ?? _defaultAvatarBuilder;

  /// [RxChat] this [RecentChatTile] is about.
  final RxChat rxChat;

  /// [UserId] of the authenticated [MyUser].
  final UserId? me;

  final MyUser? myUser;

  /// Indicator whether this [RecentChatTile] should display a blocked icon in
  /// its trailing.
  final bool blocked;

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

  /// Callback, called when this [rxChat] add to favorites action is triggered.
  final void Function()? onFavorite;

  /// Callback, called when this [rxChat] remove from favorites action is
  /// triggered.
  final void Function()? onUnfavorite;

  final void Function()? onSelect;
  final void Function()? onCreateGroup;

  final List<Widget> trailing;
  final bool selected;
  final void Function()? onTap;

  /// Builder for building an [AvatarWidget] the [ChatTile] displays.
  ///
  /// Intended to be used to allow custom [Badge]s, [InkWell]s, etc over the
  /// [AvatarWidget].
  final Widget Function(Widget child) avatarBuilder;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Chat chat = rxChat.chat.value;
      final bool selected = chat.isRoute(router.route, me);

      return ChatTile(
        chat: rxChat,
        avatarBuilder: chat.isMonolog
            ? (_) => avatarBuilder(AvatarWidget.fromMyUser(myUser, radius: 30))
            : avatarBuilder,
        status: [
          _status(context),
          Text(
            chat.updatedAt.val.toLocal().toShort(),
            style: Theme.of(context).textTheme.titleSmall,
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
                if (trailing.isEmpty) ...[
                  if (blocked) ...[
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.block,
                      color: Color(0xFFC0C0C0),
                      size: 20,
                    ),
                    if (chat.muted == null) const SizedBox(width: 5),
                  ],
                  if (chat.muted != null) ...[
                    const SizedBox(width: 5),
                    SvgLoader.asset(
                      'assets/icons/muted.svg',
                      key: Key('MuteIndicator_${chat.id}'),
                      width: 19.99,
                      height: 15,
                    ),
                    const SizedBox(width: 5),
                  ],
                  _counter(),
                ] else
                  ...trailing,
              ],
            ),
          ),
        ],
        actions: [
          if (chat.favoritePosition != null && onUnfavorite != null)
            ContextMenuButton(
              key: const Key('UnfavoriteChatButton'),
              label: 'btn_delete_from_favorites'.l10n,
              onPressed: onUnfavorite,
              trailing: const Icon(Icons.star_border),
            ),
          if (chat.favoritePosition == null && onFavorite != null)
            ContextMenuButton(
              key: const Key('FavoriteChatButton'),
              label: 'btn_add_to_favorites'.l10n,
              onPressed: onFavorite,
              trailing: const Icon(Icons.star),
            ),
          if (chat.muted == null && onMute != null)
            ContextMenuButton(
              key: const Key('MuteChatButton'),
              label: PlatformUtils.isMobile
                  ? 'btn_mute'.l10n
                  : 'btn_mute_chat'.l10n,
              onPressed: onMute,
              trailing: const Icon(Icons.notifications_off),
            ),
          if (chat.muted != null && onUnmute != null)
            ContextMenuButton(
              key: const Key('UnmuteChatButton'),
              label: PlatformUtils.isMobile
                  ? 'btn_unmute'.l10n
                  : 'btn_unmute_chat'.l10n,
              onPressed: onUnmute,
              trailing: const Icon(Icons.notifications),
            ),
          if (onHide != null)
            ContextMenuButton(
              key: const Key('ButtonHideChat'),
              label: PlatformUtils.isMobile
                  ? 'btn_delete'.l10n
                  : 'btn_delete_chat'.l10n,
              onPressed: () => _hideChat(context),
              trailing: const Icon(Icons.delete),
            ),
          const ContextMenuDivider(),
          ContextMenuButton(
            label: 'btn_create_group'.l10n,
            onPressed: onCreateGroup,
            trailing: const Icon(Icons.group_outlined),
          ),
          const ContextMenuDivider(),
          ContextMenuButton(
            label: 'btn_select'.l10n,
            onPressed: onSelect,
            trailing: const Icon(Icons.select_all),
          ),
        ],
        selected: selected,
        onTap: () {
          if (!selected) {
            router.chat(chat.id);
          }
        },
      );
    });
  }

  /// Builds a subtitle for the provided [RxChat] containing either its
  /// [Chat.lastItem] or an [AnimatedTyping] indicating an ongoing typing.
  Widget _subtitle(BuildContext context) {
    return Obx(() {
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
                            .titleSmall
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
                            .titleSmall
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
          style: Theme.of(context).textTheme.titleSmall!,
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

      if (draft != null && !selected) {
        final StringBuffer desc = StringBuffer();

        if (draft.text != null) {
          desc.write(draft.text!.val);
        }

        if (draft.repliesTo.isNotEmpty) {
          if (desc.isNotEmpty) desc.write('space'.l10n);
          desc.write(
              'label_replies'.l10nfmt({'count': draft.repliesTo.length}));
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
                      onError: () => rxChat.updateAttachments(item!),
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
                    onError: () => rxChat.updateAttachments(item!),
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
        } else if (item is ChatInfo) {
          Widget content = Text('${item.action}');

          // Builds a [FutureBuilder] returning a [User] fetched by the provided
          // [id].
          Widget userBuilder(
            UserId id,
            Widget Function(BuildContext context, User? user) builder,
          ) {
            return FutureBuilder(
              future: getUser?.call(id),
              builder: (context, snapshot) {
                if (snapshot.data != null) {
                  return Obx(() => builder(context, snapshot.data!.user.value));
                }

                return builder(context, null);
              },
            );
          }

          switch (item.action.kind) {
            case ChatInfoActionKind.created:
              if (chat.isGroup) {
                content = userBuilder(item.authorId, (context, user) {
                  user ??= (item as ChatInfo).author;
                  final Map<String, dynamic> args = {
                    'author': user.name?.val ?? user.num.val,
                  };

                  return Text('label_group_created_by'.l10nfmt(args));
                });
              } else {
                content = Text('label_dialog_created'.l10n);
              }
              break;

            case ChatInfoActionKind.memberAdded:
              final action = item.action as ChatInfoActionMemberAdded;

              if (item.authorId != action.user.id) {
                content = userBuilder(action.user.id, (context, user) {
                  final User author = (item as ChatInfo).author;
                  user ??= action.user;

                  final Map<String, dynamic> args = {
                    'author': author.name?.val ?? author.num.val,
                    'user': user.name?.val ?? user.num.val,
                  };

                  return Text('label_user_added_user'.l10nfmt(args));
                });
              } else {
                content = Text(
                  'label_was_added'.l10nfmt(
                    {'author': '${action.user.name ?? action.user.num}'},
                  ),
                );
              }
              break;

            case ChatInfoActionKind.memberRemoved:
              final action = item.action as ChatInfoActionMemberRemoved;

              if (item.authorId != action.user.id) {
                content = userBuilder(action.user.id, (context, user) {
                  final User author = (item as ChatInfo).author;
                  user ??= action.user;

                  final Map<String, dynamic> args = {
                    'author': author.name?.val ?? author.num.val,
                    'user': user.name?.val ?? user.num.val,
                  };

                  return Text('label_user_removed_user'.l10nfmt(args));
                });
              } else {
                content = Text(
                  'label_was_removed'.l10nfmt(
                    {'author': '${action.user.name ?? action.user.num}'},
                  ),
                );
              }
              break;

            case ChatInfoActionKind.avatarUpdated:
              final action = item.action as ChatInfoActionAvatarUpdated;

              final Map<String, dynamic> args = {
                'author': item.author.name?.val ?? item.author.num.val,
              };

              if (action.avatar == null) {
                content = Text('label_avatar_removed'.l10nfmt(args));
              } else {
                content = Text('label_avatar_updated'.l10nfmt(args));
              }
              break;

            case ChatInfoActionKind.nameUpdated:
              final action = item.action as ChatInfoActionNameUpdated;

              final Map<String, dynamic> args = {
                'author': item.author.name?.val ?? item.author.num.val,
                if (action.name != null) 'name': action.name?.val
              };

              if (action.name == null) {
                content = Text('label_name_removed'.l10nfmt(args));
              } else {
                content = Text('label_name_updated'.l10nfmt(args));
              }
              break;
          }

          subtitle = [Flexible(child: content)];
        } else {
          subtitle = [Flexible(child: Text('label_empty_message'.l10n))];
        }
      }

      return DefaultTextStyle(
        style: Theme.of(context).textTheme.titleSmall!,
        overflow: TextOverflow.ellipsis,
        child: Row(children: subtitle),
      );
    });
  }

  /// Builds an [Attachment] visual representation.
  Widget _attachment(Attachment e, {Future<void> Function()? onError}) {
    Widget? content;

    if (e is LocalAttachment) {
      if (e.file.isImage && e.file.bytes.value != null) {
        content = Image.memory(e.file.bytes.value!, fit: BoxFit.cover);
      } else if (e.file.isVideo) {
        // TODO: `video_player` being used doesn't support desktop platforms.
        if ((PlatformUtils.isMobile || PlatformUtils.isWeb) &&
            e.file.bytes.value != null) {
          content = FittedBox(
            fit: BoxFit.cover,
            child: VideoThumbnail.bytes(
              bytes: e.file.bytes.value!,
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
      content = Container(
        color: const Color(0xFFF7FBFF),
        child: RetryImage(
          e.medium.url,
          checksum: e.medium.checksum,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          onForbidden: onError,
          displayProgress: false,
        ),
      );
    }

    if (e is FileAttachment) {
      if (e.isVideo) {
        if (PlatformUtils.isMobile || PlatformUtils.isWeb) {
          content = FittedBox(
            fit: BoxFit.cover,
            child: VideoThumbnail.url(
              url: e.original.url,
              checksum: e.original.checksum,
              key: key,
              height: 300,
              onError: onError,
            ),
          );
        } else {
          content = Container(
            color: const Color(0xFFDFDFDF),
            child: const Icon(
              Icons.video_file,
              size: 18,
              color: Colors.white,
            ),
          );
        }
      } else {
        content = Container(
          color: const Color(0xFFDFDFDF),
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

      if (item != null && item.authorId == me && chat.isMonolog == false) {
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

      if (rxChat.unreadCount.value > 0) {
        return Container(
          key: const Key('UnreadMessages'),
          margin: const EdgeInsets.only(left: 4),
          width: 23,
          height: 23,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: chat.muted == null ? Colors.red : const Color(0xFFC0C0C0),
          ),
          alignment: Alignment.center,
          child: Text(
            // TODO: Implement and test notations like `4k`, `54m`, etc.
            rxChat.unreadCount.value > 99
                ? '99${'plus'.l10n}'
                : '${rxChat.unreadCount.value}',
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

  /// Hides the [rxChat].
  Future<void> _hideChat(BuildContext context) async {
    final Style style = Theme.of(context).extension<Style>()!;
    bool clear = false;

    Widget dot(bool selected) {
      return SizedBox(
        width: 30,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: selected
              ? CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  radius: 11,
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD7D7D7),
                      width: 1,
                    ),
                  ),
                  width: 22,
                  height: 22,
                ),
        ),
      );
    }

    final bool? result = await MessagePopup.alert(
      'label_delete_chat'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_deleted1'.l10n),
        TextSpan(
          text: rxChat.title.value,
          style: const TextStyle(color: Colors.black),
        ),
        TextSpan(text: 'alert_chat_will_be_deleted2'.l10n),
      ],
      additional: [
        const SizedBox(height: 21),
        StatefulBuilder(builder: (context, setState) {
          return FieldButton(
            text: 'btn_clear_history'.l10n,
            onPressed: () => setState(() => clear = !clear),
            trailing: dot(clear),
          );
        })
      ],
    );

    if (result == true) {
      onHide?.call();
    }
  }

  /// Returns the [child].
  static Widget _defaultAvatarBuilder(Widget child) => child;
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
