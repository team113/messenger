// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '/api/backend/schema.dart';
import '/config.dart';
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
import '/themes.dart';
import '/ui/page/call/widget/animated_dots.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/custom_drop_target.dart';
import '/ui/page/home/page/chat/widget/video_thumbnail/video_thumbnail.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/chat_tile.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/svg/svg.dart';
import '/util/fixed_digits.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'periodic_builder.dart';
import 'slidable_action.dart';
import 'unread_counter.dart';

/// [ChatTile] representing the provided [RxChat] as a recent [Chat].
class RecentChatTile extends StatefulWidget {
  const RecentChatTile(
    this.rxChat, {
    super.key,
    this.me,
    this.blocked = false,
    this.selected = false,
    this.invertible = true,
    this.trailing,
    this.getUser,
    this.inContacts,
    this.onLeave,
    this.onHide,
    this.onDrop,
    this.onJoin,
    this.onMute,
    this.onUnmute,
    this.onFavorite,
    this.onUnfavorite,
    this.onSelect,
    this.onContact,
    this.onTap,
    this.onDismissed,
    Widget Function(Widget)? avatarBuilder,
    this.enableContextMenu = true,
    this.hasCall,
    this.onPerformDrop,
  }) : avatarBuilder = avatarBuilder ?? _defaultAvatarBuilder;

  /// [RxChat] this [RecentChatTile] is about.
  final RxChat rxChat;

  /// [UserId] of the authenticated [MyUser].
  final UserId? me;

  /// Indicator whether this [RecentChatTile] should display a blocked icon in
  /// its trailing.
  final bool blocked;

  /// Indicator whether this [RecentChatTile] is selected.
  ///
  /// If `null`, then uses the [ChatIsRoute.isRoute].
  final bool? selected;

  /// Indicator whether [ChatIsRoute.isRoute] should be treated as [selected].
  final bool invertible;

  /// [Widget]s to display in the trailing instead of the defaults.
  final List<Widget>? trailing;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final FutureOr<RxUser?> Function(UserId id)? getUser;

  /// Callback, called to check whether the [rxChat] is considered to be in
  /// contacts list of the authenticated [MyUser].
  final bool Function()? inContacts;

  /// Callback, called when this [rxChat] leave action is triggered.
  final void Function()? onLeave;

  /// Callback, called when this [rxChat] hide action is triggered.
  final void Function(bool)? onHide;

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

  /// Callback, called when this [rxChat] select action is triggered.
  final void Function()? onSelect;

  /// Callback, called when this [rxChat] add or remove contact action is
  /// triggered.
  final void Function(bool)? onContact;

  /// Callback, called when this [RecentChatTile] is tapped.
  final void Function()? onTap;

  /// Callback, called when this [RecentChatTile] is dismissed.
  final void Function()? onDismissed;

  /// Builder for building an [AvatarWidget] the [ChatTile] displays.
  ///
  /// Intended to be used to allow custom [Badge]s, [InkWell]s, etc over the
  /// [AvatarWidget].
  final Widget Function(Widget child) avatarBuilder;

  /// Indicator whether context menu should be enabled over this
  /// [RecentChatTile].
  final bool enableContextMenu;

  /// Indicator whether the [RxChat] has an [OngoingCall] happening in it.
  ///
  /// If none specified, then [RxChat.inCall] is used.
  final bool? hasCall;

  /// Callback, called when a file is dropped on this [RecentChatTile]
  final void Function(PerformDropEvent)? onPerformDrop;

  @override
  State<RecentChatTile> createState() => _RecentChatTileState();

  /// Returns the [child].
  ///
  /// Uses [GestureDetector] with a dummy [GestureDetector.onLongPress] callback
  /// for discarding long presses on its [child].
  static Widget _defaultAvatarBuilder(Widget child) => GestureDetector(
        onLongPress: () {},
        child: child,
      );
}

/// State class for the [RecentChatTile].
class _RecentChatTileState extends State<RecentChatTile> {
  /// Indicator whether there is an ongoing drag-n-drop at the moment.
  final RxBool _isDraggingFiles = RxBool(false);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final style = Theme.of(context).style;

      final Chat chat = widget.rxChat.chat.value;
      final String? lastRoute =
          router.routes.lastWhereOrNull((e) => e.startsWith(Routes.chats));
      final bool isRoute = chat.isRoute(lastRoute ?? '', widget.me);
      final bool inverted = widget.selected ?? (widget.invertible && isRoute);

      return Slidable(
        key: Key(widget.rxChat.id.val),
        groupTag: 'chat',
        enabled: widget.onHide != null,
        endActionPane: ActionPane(
          extentRatio: 0.33,
          motion: const StretchMotion(),
          dismissible: widget.onDismissed == null
              ? null
              : DismissiblePane(onDismissed: widget.onDismissed!),
          children: [
            FadingSlidableAction(
              onPressed: _hideChat,
              icon: const Icon(Icons.delete),
              text: 'btn_delete'.l10n,
            ),
          ],
        ),
        child: CustomDropTarget(
          onPerformDrop: widget.onPerformDrop ?? (_) {},
          onDropEnter: (_) {
            _isDraggingFiles.value = true;
          },
          onDropLeave: (_) {
            _isDraggingFiles.value = false;
          },
          child: ChatTile(
            chat: widget.rxChat,
            dimmed: widget.blocked || _isDraggingFiles.value,
            status: [
              const SizedBox(height: 28),
              if (widget.trailing == null) ...[
                _ongoingCall(context, inverted: inverted),
                if (widget.blocked) ...[
                  const SizedBox(width: 8),
                  SvgIcon(inverted ? SvgIcons.blockedWhite : SvgIcons.blocked),
                ],
                if (widget.rxChat.unreadCount.value > 0) ...[
                  const SizedBox(width: 10),
                  UnreadCounter(
                    key: const Key('UnreadMessages'),
                    widget.rxChat.unreadCount.value,
                    inverted: inverted,
                    dimmed: chat.muted != null,
                  ),
                ] else ...[
                  if (chat.muted != null) ...[
                    const SizedBox(width: 10),
                    SvgIcon(
                      inverted ? SvgIcons.mutedWhite : SvgIcons.muted,
                      key: Key('MuteIndicator_${chat.id}'),
                    ),
                  ],
                  const SizedBox(key: Key('NoUnreadMessages')),
                ],
              ] else
                ...widget.trailing!,
            ],
            subtitle: [
              const SizedBox(height: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 38),
                child: Row(
                  children: [
                    const SizedBox(height: 3),
                    Expanded(
                      child: _subtitle(
                          context, widget.selected ?? false, inverted),
                    ),
                    const SizedBox(width: 3),
                    _status(context, inverted),
                    if (!chat.id.isLocal)
                      Text(
                        chat.updatedAt.val.toLocal().short,
                        style: inverted
                            ? style.fonts.normal.regular.onPrimary
                            : style.fonts.normal.regular.secondary,
                      ),
                  ],
                ),
              ),
            ],
            actions: [
              if (chat.isDialog &&
                  widget.inContacts != null &&
                  widget.onContact != null) ...[
                if (widget.inContacts!.call() == true)
                  ContextMenuButton(
                    label: 'btn_delete_from_contacts'.l10n,
                    onPressed: () => widget.onContact?.call(false),
                    trailing: const SvgIcon(SvgIcons.deleteContact),
                    inverted: const SvgIcon(SvgIcons.deleteContactWhite),
                  )
                else
                  ContextMenuButton(
                    label: 'btn_add_to_contacts'.l10n,
                    onPressed: () => widget.onContact?.call(true),
                    trailing: const SvgIcon(SvgIcons.addContact),
                    inverted: const SvgIcon(SvgIcons.addContactWhite),
                  ),
              ],
              if (chat.favoritePosition != null && widget.onUnfavorite != null)
                ContextMenuButton(
                  key: const Key('UnfavoriteChatButton'),
                  label: 'btn_delete_from_favorites'.l10n,
                  onPressed: widget.onUnfavorite,
                  trailing: const SvgIcon(SvgIcons.favoriteSmall),
                  inverted: const SvgIcon(SvgIcons.favoriteSmallWhite),
                ),
              if (chat.favoritePosition == null && widget.onFavorite != null)
                ContextMenuButton(
                  key: const Key('FavoriteChatButton'),
                  label: 'btn_add_to_favorites'.l10n,
                  onPressed: widget.onFavorite,
                  trailing: const SvgIcon(SvgIcons.unfavoriteSmall),
                  inverted: const SvgIcon(SvgIcons.unfavoriteSmallWhite),
                ),
              if (chat.muted == null && widget.onMute != null)
                ContextMenuButton(
                  key: const Key('MuteChatButton'),
                  label: PlatformUtils.isMobile
                      ? 'btn_mute'.l10n
                      : 'btn_mute_chat'.l10n,
                  onPressed: widget.onMute,
                  trailing: const SvgIcon(SvgIcons.unmuteSmall),
                  inverted: const SvgIcon(SvgIcons.unmuteSmallWhite),
                ),
              if (chat.muted != null && widget.onUnmute != null)
                ContextMenuButton(
                  key: const Key('UnmuteChatButton'),
                  label: PlatformUtils.isMobile
                      ? 'btn_unmute'.l10n
                      : 'btn_unmute_chat'.l10n,
                  onPressed: widget.onUnmute,
                  trailing: const SvgIcon(SvgIcons.muteSmall),
                  inverted: const SvgIcon(SvgIcons.muteSmallWhite),
                ),
              if (widget.onHide != null)
                ContextMenuButton(
                  key: const Key('HideChatButton'),
                  label: PlatformUtils.isMobile
                      ? 'btn_delete'.l10n
                      : 'btn_delete_chat'.l10n,
                  onPressed: () => _hideChat(context),
                  trailing: const SvgIcon(SvgIcons.delete19),
                  inverted: const SvgIcon(SvgIcons.delete19White),
                ),
            ],
            selected: inverted,
            avatarBuilder: widget.avatarBuilder,
            enableContextMenu: widget.enableContextMenu,
            onTap: widget.onTap ?? () => router.chat(chat.id),
            onForbidden: widget.rxChat.updateAvatar,
          ),
        ),
      );
    });
  }

  /// Builds a subtitle for the provided [RxChat] containing either its
  /// [Chat.lastItem] or an [AnimatedTyping] indicating an ongoing typing.
  Widget _subtitle(BuildContext context, bool selected, bool inverted) {
    final style = Theme.of(context).style;

    if (widget.blocked) {
      return Text(
        'label_blocked'.l10n,
        style: inverted
            ? style.fonts.normal.regular.onPrimary
            : style.fonts.normal.regular.secondary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Obx(() {
      final List<Widget> subtitle;

      final Chat chat = widget.rxChat.chat.value;
      final ChatItem? item = widget.rxChat.lastItem;
      final ChatMessage? draft = widget.rxChat.draft.value;

      final Iterable<String> typings = widget.rxChat.typingUsers
          .where((User user) => user.id != widget.me)
          .map((User user) => user.title);

      if (typings.isNotEmpty) {
        if (!widget.rxChat.chat.value.isGroup) {
          subtitle = [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'label_typing'.l10n,
                  style: inverted
                      ? style.fonts.small.regular.onPrimary
                      : style.fonts.small.regular.primary,
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: AnimatedTyping(inverted: inverted),
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
                      style: inverted
                          ? style.fonts.small.regular.onPrimary
                          : style.fonts.small.regular.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: AnimatedTyping(inverted: inverted),
                  ),
                ],
              ),
            )
          ];
        }
      } else if (draft != null && !selected) {
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
            // TODO: Backend should support single attachment updating.
            images.addAll(
              draft.attachments.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: _attachment(e, inverted: inverted),
                );
              }),
            );
          } else {
            // TODO: Backend should support single attachment updating.
            images.add(
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _attachment(draft.attachments.first, inverted: inverted),
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
      } else if (item != null) {
        if (item is ChatCall) {
          final bool isOngoing = widget.hasCall != false &&
              item.finishReason == null &&
              (item.conversationStartedAt != null || !chat.isDialog);

          final bool isMissed =
              item.finishReason == ChatCallFinishReason.dropped ||
                  item.finishReason == ChatCallFinishReason.unanswered;

          final Widget subtitleWidget = Padding(
            padding: const EdgeInsets.fromLTRB(0, 2, 6, 2),
            child: SvgIcon(
              item.withVideo
                  ? inverted
                      ? SvgIcons.callVideoWhite
                      : isMissed
                          ? SvgIcons.callVideoMissed
                          : SvgIcons.callVideoDisabled
                  : inverted
                      ? SvgIcons.callAudioWhite
                      : isMissed
                          ? SvgIcons.callAudioMissed
                          : SvgIcons.callAudioDisabled,
            ),
          );

          if (isOngoing) {
            subtitle = [
              subtitleWidget,
              Flexible(child: Text('label_call_active'.l10n)),
            ];
          } else if (item.finishReason != null) {
            final String description = item.finishReason
                    ?.localizedString(item.author.id == widget.me) ??
                'label_chat_call_ended'.l10n;
            subtitle = [subtitleWidget, Flexible(child: Text(description))];
          } else {
            subtitle = [
              subtitleWidget,
              Flexible(
                child: Text(
                  item.author.id == widget.me
                      ? 'label_outgoing_call'.l10n
                      : 'label_incoming_call'.l10n,
                ),
              ),
              if (item.author.id == widget.me) const AnimatedDots(),
            ];
          }
        } else if (item is ChatMessage) {
          final desc = StringBuffer();

          final FutureOr<RxUser?> userOrFuture =
              widget.getUser?.call(item.author.id);

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
                      inverted: inverted,
                      onError: () => widget.rxChat.updateAttachments(item),
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
                    inverted: inverted,
                    onError: () => widget.rxChat.updateAttachments(item),
                  ),
                ),
              );
            }
          }

          subtitle = [
            if (item.author.id == widget.me)
              Text('${'label_you'.l10n}${'colon_space'.l10n}')
            else if (chat.isGroup)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: FutureBuilder<RxUser?>(
                  future: userOrFuture is RxUser? ? null : userOrFuture,
                  initialData: userOrFuture is RxUser? ? userOrFuture : null,
                  builder: (_, snapshot) {
                    final FutureOr<RxUser?> rxUser = snapshot.data ??
                        userOrFuture ??
                        widget.rxChat.members.values
                            .firstWhereOrNull(
                              (e) => e.user.id == item.author.id,
                            )
                            ?.user;

                    if (rxUser is RxUser?) {
                      return AvatarWidget.fromRxUser(
                        rxUser,
                        radius: AvatarRadius.smaller,
                      );
                    }

                    return AvatarWidget.fromUser(
                      chat.getUser(item.author.id),
                      radius: AvatarRadius.smaller,
                    );
                  },
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
          final FutureOr<RxUser?> userOrFuture =
              widget.getUser?.call(item.author.id);

          subtitle = [
            if (chat.isGroup)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: FutureBuilder<RxUser?>(
                  future: userOrFuture is RxUser? ? null : userOrFuture,
                  initialData: userOrFuture is RxUser? ? userOrFuture : null,
                  builder: (_, snapshot) => snapshot.data != null
                      ? AvatarWidget.fromRxUser(
                          snapshot.data,
                          radius: AvatarRadius.smaller,
                        )
                      : AvatarWidget.fromUser(
                          chat.getUser(item.author.id),
                          radius: AvatarRadius.smaller,
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
            Widget Function(BuildContext context, RxUser? user) builder,
          ) {
            final FutureOr<RxUser?> userOrFuture = widget.getUser?.call(id);

            return FutureBuilder(
              key: Key('UserBuilder_$id'),
              future: userOrFuture is RxUser? ? null : userOrFuture,
              initialData: userOrFuture is RxUser? ? userOrFuture : null,
              builder: (context, snapshot) {
                if (snapshot.data != null) {
                  return Obx(() => builder(context, snapshot.data!));
                }

                return builder(context, null);
              },
            );
          }

          switch (item.action.kind) {
            case ChatInfoActionKind.created:
              if (chat.isGroup) {
                content = userBuilder(item.author.id, (context, user) {
                  final Map<String, dynamic> args = {
                    'author': user?.title ?? item.author.title,
                  };

                  return Text('label_group_created_by'.l10nfmt(args));
                });
              } else if (chat.isMonolog) {
                content = Text('label_monolog_created'.l10n);
              } else {
                content = Text('label_dialog_created'.l10n);
              }
              break;

            case ChatInfoActionKind.memberAdded:
              final action = item.action as ChatInfoActionMemberAdded;

              content = userBuilder(action.user.id, (context, user) {
                final String userName = user?.title ?? action.user.title;

                if (item.author.id != action.user.id) {
                  return userBuilder(item.author.id, (context, author) {
                    final Map<String, dynamic> args = {
                      'author': author?.title ?? item.author.title,
                      'user': userName,
                    };

                    return Text('label_user_added_user'.l10nfmt(args));
                  });
                } else {
                  return Text(
                    'label_was_added'.l10nfmt({'author': userName}),
                  );
                }
              });
              break;

            case ChatInfoActionKind.memberRemoved:
              final action = item.action as ChatInfoActionMemberRemoved;

              if (item.author.id != action.user.id) {
                content = userBuilder(item.author.id, (context, author) {
                  return userBuilder(action.user.id, (context, user) {
                    final Map<String, dynamic> args = {
                      'author': author?.title ?? item.author.title,
                      'user': user?.title ?? action.user.title,
                    };

                    return Text('label_user_removed_user'.l10nfmt(args));
                  });
                });
              } else {
                content = userBuilder(action.user.id, (context, rxUser) {
                  return Text(
                    'label_was_removed'.l10nfmt(
                      {'author': rxUser?.title ?? action.user.title},
                    ),
                  );
                });
              }
              break;

            case ChatInfoActionKind.avatarUpdated:
              final action = item.action as ChatInfoActionAvatarUpdated;

              content = userBuilder(item.author.id, (context, user) {
                final Map<String, dynamic> args = {
                  'author': user?.title ?? item.author.title,
                };

                if (action.avatar == null) {
                  return Text('label_avatar_removed'.l10nfmt(args));
                } else {
                  return Text('label_avatar_updated'.l10nfmt(args));
                }
              });
              break;

            case ChatInfoActionKind.nameUpdated:
              final action = item.action as ChatInfoActionNameUpdated;

              content = userBuilder(item.author.id, (context, user) {
                final Map<String, dynamic> args = {
                  'author': user?.title ?? item.author.title,
                  'name': action.name?.val,
                };

                if (action.name == null) {
                  return Text('label_name_removed'.l10nfmt(args));
                } else {
                  return Text('label_name_updated'.l10nfmt(args));
                }
              });
              break;
          }

          subtitle = [Flexible(child: content)];
        } else {
          subtitle = [Flexible(child: Text('label_empty_message'.l10n))];
        }
      } else {
        subtitle = [Flexible(child: Text('label_no_messages'.l10n))];
      }

      return DefaultTextStyle(
        style: inverted
            ? style.fonts.normal.regular.onPrimary
            : style.fonts.normal.regular.secondary,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        child: Row(children: subtitle),
      );
    });
  }

  /// Builds an [Attachment] visual representation.
  Widget _attachment(
    Attachment e, {
    bool inverted = false,
    Future<void> Function()? onError,
  }) {
    Widget? content;

    final style = Theme.of(router.context!).style;

    if (e is LocalAttachment) {
      if (e.file.isImage && e.file.bytes.value != null) {
        content = Image.memory(e.file.bytes.value!, fit: BoxFit.cover);
      } else if (e.file.isVideo) {
        if (e.file.path == null) {
          if (e.file.bytes.value == null) {
            content = Container(
              color: inverted ? style.colors.onPrimary : style.colors.secondary,
              child: Icon(
                Icons.video_file,
                size: 18,
                color:
                    inverted ? style.colors.secondary : style.colors.onPrimary,
              ),
            );
          } else {
            content = FittedBox(
              fit: BoxFit.cover,
              child: VideoThumbnail.bytes(
                e.file.bytes.value!,
                key: widget.key,
                height: 300,
              ),
            );
          }
        } else {
          content = FittedBox(
            fit: BoxFit.cover,
            child: VideoThumbnail.file(
              e.file.path!,
              key: widget.key,
              height: 300,
            ),
          );
        }
      } else {
        content = Container(
          color: inverted ? style.colors.onPrimary : style.colors.secondary,
          child: Center(
            child: SvgIcon(
              inverted ? SvgIcons.fileSmall : SvgIcons.fileSmallWhite,
            ),
          ),
        );
      }
    }

    if (e is ImageAttachment) {
      content = RetryImage(
        e.small.url,
        checksum: e.small.checksum,
        thumbhash: e.small.thumbhash,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        onForbidden: onError,
        displayProgress: false,
      );
    }

    if (e is FileAttachment) {
      if (e.isVideo) {
        content = FittedBox(
          fit: BoxFit.cover,
          child: VideoThumbnail.url(
            e.original.url,
            checksum: e.original.checksum,
            key: widget.key,
            height: 300,
            onError: onError,
          ),
        );
      } else {
        content = Container(
          color: inverted ? style.colors.onPrimary : style.colors.secondary,
          child: Center(
            child: SvgIcon(
              inverted ? SvgIcons.fileSmall : SvgIcons.fileSmallWhite,
            ),
          ),
        );
      }
    }

    if (content != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(width: 30, height: 30, child: content),
      );
    }

    return const SizedBox();
  }

  /// Builds a [ChatItem.status] visual representation.
  Widget _status(BuildContext context, bool inverted) {
    return Obx(() {
      final Chat chat = widget.rxChat.chat.value;

      final ChatItem? item = widget.rxChat.lastItem;

      if (item != null && item.author.id == widget.me && !chat.isMonolog) {
        final bool isSent = item.status.value == SendingStatus.sent;
        final bool isRead = chat.members.length <= 1
            ? isSent
            : chat.isRead(item, widget.me) && isSent;
        final bool isHalfRead = isSent && chat.isHalfRead(item, widget.me);
        final bool isDelivered = isSent && !chat.lastDelivery.isBefore(item.at);
        final bool isError = item.status.value == SendingStatus.error;
        final bool isSending = item.status.value == SendingStatus.sending;

        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: SvgIcon(
            isRead
                ? isHalfRead
                    ? inverted
                        ? SvgIcons.halfReadWhite
                        : SvgIcons.halfRead
                    : inverted
                        ? SvgIcons.readWhite
                        : SvgIcons.read
                : isDelivered
                    ? inverted
                        ? SvgIcons.deliveredWhite
                        : SvgIcons.delivered
                    : isError
                        ? SvgIcons.error
                        : isSending
                            ? inverted
                                ? SvgIcons.sendingWhite
                                : SvgIcons.sending
                            : inverted
                                ? SvgIcons.sentWhite
                                : SvgIcons.sent,
          ),
        );
      }

      return const SizedBox();
    });
  }

  /// Returns a visual representation of the [Chat.ongoingCall], if any.
  Widget _ongoingCall(BuildContext context, {bool inverted = false}) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Chat chat = widget.rxChat.chat.value;

      if (chat.ongoingCall == null || widget.hasCall == false) {
        return const SizedBox();
      }

      // Returns a rounded rectangular button representing an [OngoingCall]
      // associated action.
      Widget button(bool displayed) {
        return DecoratedBox(
          key: displayed
              ? const Key('JoinCallButton')
              : const Key('DropCallButton'),
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
          child: Material(
            elevation: 0,
            type: MaterialType.button,
            borderRadius: BorderRadius.circular(6),
            color: displayed
                ? style.colors.danger
                : inverted
                    ? style.colors.onPrimary
                    : style.colors.primary,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: displayed ? widget.onDrop : widget.onJoin,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    PeriodicBuilder(
                      period: Config.disableInfiniteAnimations
                          ? const Duration(minutes: 1)
                          : const Duration(seconds: 1),
                      builder: (_) {
                        if (chat.ongoingCall == null) {
                          return const SizedBox();
                        }

                        final Duration duration =
                            DateTime.now().difference(chat.ongoingCall!.at.val);
                        final String text = duration.hhMmSs();

                        return Text(
                          text,
                          style: !displayed && inverted
                              ? style.fonts.smaller.regular.primary
                              : style.fonts.smaller.regular.onPrimary,
                        ).fixedDigits();
                      },
                    ),
                    const SizedBox(width: 6),
                    Transform.translate(
                      offset: PlatformUtils.isWeb
                          ? const Offset(0, -0.5)
                          : Offset.zero,
                      child: SvgIcon(
                        displayed
                            ? SvgIcons.activeCallEnd
                            : inverted
                                ? SvgIcons.activeCallStartBlue
                                : SvgIcons.activeCallStart,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(left: 5),
        child: Transform.translate(
          offset: const Offset(1, 0),
          child: SafeAnimatedSwitcher(
            duration: 300.milliseconds,
            child: button(widget.rxChat.inCall.value),
          ),
        ),
      );
    });
  }

  /// Hides the [widget.rxChat].
  Future<void> _hideChat(BuildContext context) async {
    bool clear = false;

    final bool? result = await MessagePopup.alert(
      'label_delete_chat'.l10n,
      description: [TextSpan(text: 'label_to_restore_chat_use_search'.l10n)],
      additional: [
        const SizedBox(height: 21),
        StatefulBuilder(
          builder: (context, setState) {
            return RectangleButton(
              label: 'btn_clear_history'.l10n,
              selected: clear,
              toggleable: true,
              radio: true,
              onPressed: () => setState(() => clear = !clear),
            );
          },
        )
      ],
    );

    if (result == true) {
      widget.onHide?.call(clear);
    }
  }
}
