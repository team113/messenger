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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart' show ChatCallFinishReason;
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/ui/page/home/page/chat/get_paid/controller.dart';
import 'package:messenger/ui/page/home/page/chat/get_paid/view.dart';
import 'package:messenger/ui/page/home/widget/rectangle_button.dart';

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
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/widget/video_thumbnail/video_thumbnail.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/chat_tile.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/svg/svg.dart';
import '/util/message_popup.dart';
import '/util/fixed_digits.dart';
import '/util/platform_utils.dart';
import 'periodic_builder.dart';
import 'slidable.dart';
import 'unread_counter.dart';

/// [ChatTile] representing the provided [RxChat] as a recent [Chat].
class RecentChatTile extends StatelessWidget {
  const RecentChatTile(
    this.rxChat, {
    super.key,
    this.me,
    this.myUser,
    this.price = true,
    this.blocked = false,
    this.selected = false,
    this.active = false,
    this.trailing,
    this.getUser,
    this.inCall,
    this.inContacts,
    this.onCall,
    this.onLeave,
    this.onHide,
    this.onDismiss,
    this.onDrop,
    this.onJoin,
    this.onMute,
    this.onUnmute,
    this.onFavorite,
    this.onUnfavorite,
    this.onSelect,
    this.onCreateGroup,
    this.onContact,
    this.onTap,
    Widget Function(Widget)? avatarBuilder,
    this.enableContextMenu = true,
  }) : avatarBuilder = avatarBuilder ?? _defaultAvatarBuilder;

  /// [RxChat] this [RecentChatTile] is about.
  final RxChat rxChat;

  /// [UserId] of the authenticated [MyUser].
  final UserId? me;

  final MyUser? myUser;

  /// Indicator whether this [RecentChatTile] should display a blocked icon in
  /// its trailing.
  final bool blocked;

  /// Indicator whether this [RecentChatTile] is selected.
  final bool selected;

  /// Indicator whether this [RecentChatTile] is active.
  final bool active;

  /// [Widget]s to display in the trailing instead of the defaults.
  final List<Widget>? trailing;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId id)? getUser;

  /// Callback, called to check whether this device of the currently
  /// authenticated [MyUser] takes part in the [Chat.ongoingCall], if any.
  final bool Function()? inCall;
  final bool Function()? inContacts;

  final void Function(bool)? onCall;

  /// Callback, called when this [rxChat] leave action is triggered.
  final void Function()? onLeave;

  /// Callback, called when this [rxChat] hide action is triggered.
  final void Function()? onHide;

  final void Function()? onDismiss;

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

  final void Function()? onCreateGroup;

  final void Function(bool)? onContact;

  /// Callback, called when this [RecentChatTile] is tapped.
  final void Function()? onTap;

  final bool price;

  /// Builder for building an [AvatarWidget] the [ChatTile] displays.
  ///
  /// Intended to be used to allow custom [Badge]s, [InkWell]s, etc over the
  /// [AvatarWidget].
  final Widget Function(Widget child) avatarBuilder;

  /// Indicator whether context menu should be enabled over this
  /// [RecentChatTile].
  final bool enableContextMenu;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final style = Theme.of(context).style;

      final Chat chat = rxChat.chat.value;
      final bool isRoute = chat.isRoute(router.route, me);
      final bool inverted = selected || active || isRoute;

      final bool paid = rxChat.members.values.any(
        (e) =>
            e.user.value.id != myUser?.id &&
            (e.user.value.name?.val.toLowerCase() == 'kirey' ||
                e.user.value.name?.val.toLowerCase() == 'alex2'),
      );

      final bool payee = price &&
          rxChat.chat.value.isDialog &&
          (myUser?.name?.val.toLowerCase() == 'alex2' ||
              myUser?.name?.val.toLowerCase() == 'kirey');

      return CustomSlidable(
        enabled: onHide != null,
        slidableKey: Key(rxChat.id.val),
        groupTag: 'chat',
        actions: [
          CustomAction(
            onPressed: _hideChat,
            icon: const Icon(Icons.delete),
            text: 'btn_delete'.l10n,
          ),
        ],
        onDismissed: onDismiss,
        child: ChatTile(
          chat: rxChat,
          avatarBuilder: avatarBuilder,
          dimmed: blocked,
          titleBuilder: (t) {
            return Row(
              children: [
                Flexible(child: t),
                // if (chat.muted != null) ...[
                //   const SizedBox(width: 5),
                //   SvgIcon(
                //     inverted ? SvgIcons.mutedWhite : SvgIcons.muted,
                //     key: Key('MuteIndicator_${chat.id}'),
                //   ),
                //   const SizedBox(width: 5),
                // ],
              ],
            );
          },

          // onBasementPressed: () async {
          //   await GetPaidView.show(
          //     context,
          //     mode: GetPaidMode.user,
          //     user: rxChat.members.values.firstWhere((e) => e.id != me),
          //   );
          // },
          basement: payee
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 6),
                    const Text('Total: \$123'),
                    const Spacer(),
                    SvgIcon(
                      inverted ? SvgIcons.callsTinyWhite : SvgIcons.callsTiny,
                    ),
                    const SizedBox(width: 2),
                    const Text('123\$'),
                    const SizedBox(width: 8),
                    SvgIcon(
                      inverted ? SvgIcons.chatsTinyWhite : SvgIcons.chatsTiny,
                    ),
                    const SizedBox(width: 2),
                    const Text('123\$'),
                    // const SizedBox(width: 5),
                  ],
                )
              : null,
          status: [
            const SizedBox(height: 28),
            if (trailing == null) ...[
              _ongoingCall(context),
              if (blocked) ...[
                const SizedBox(width: 8),
                SvgIcon(inverted ? SvgIcons.blockedWhite : SvgIcons.blocked),
              ] else if (paid) ...[
                const SizedBox(width: 8),
                const SvgIcon(SvgIcons.cent),
                // SvgIcon(
                //   inverted ? SvgIcons.dollarStatusWhite : SvgIcons.dollarStatus,
                // ),
                // Text(
                //   '\$',
                //   style: inverted
                //       ? style.fonts.small.regular.onPrimary
                //       : style.fonts.small.regular.secondary.copyWith(
                //           color: style.colors.acceptPrimary,
                //         ),
                //   maxLines: 1,
                //   overflow: TextOverflow.clip,
                //   textAlign: TextAlign.center,
                // ),
              ],
              if (rxChat.unreadCount.value > 0) ...[
                const SizedBox(width: 10),
                UnreadCounter(
                  key: const Key('UnreadMessages'),
                  rxChat.unreadCount.value > 99
                      ? '99${'plus'.l10n}'
                      : '${rxChat.unreadCount.value}',
                  inverted: inverted,
                  dimmed: chat.muted != null,
                ),
              ] else ...[
                if (chat.muted != null) ...[
                  const SizedBox(width: 10),
                  SvgIcon(inverted ? SvgIcons.mutedWhite : SvgIcons.muted),
                  // UnreadCounter(
                  //   null,
                  //   dimmed: true,
                  //   inverted: inverted,
                  //   icon: inverted ? SvgIcons.muted : SvgIcons.mutedWhite,
                  //   key: Key('MuteIndicator_${chat.id}'),
                  // ),
                ],
                const SizedBox(key: Key('NoUnreadMessages')),
              ],
            ] else
              ...trailing!,
          ],
          subtitle: [
            const SizedBox(height: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 38),
              child: Row(
                children: [
                  const SizedBox(height: 3),
                  Expanded(child: _subtitle(context, selected, inverted)),
                  const SizedBox(width: 3),
                  _status(context, inverted),
                  if (!chat.id.isLocalWith(me))
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
            if (chat.isDialog) ...[
              ContextMenuButton(
                label: 'btn_set_price'.l10n,
                onPressed: () => GetPaidView.show(
                  context,
                  mode: GetPaidMode.user,
                  user: rxChat.members.values.firstWhere((e) => e.id != me),
                ),
                trailing: const SvgIcon(SvgIcons.coin),
                inverted: const SvgIcon(SvgIcons.coinWhite),
              ),
              if (inContacts != null) ...[
                if (inContacts?.call() == true)
                  ContextMenuButton(
                    label: 'btn_delete_from_contacts'.l10n,
                    onPressed: () => onContact?.call(false),
                    trailing: const SvgIcon(SvgIcons.deleteContact),
                    inverted: const SvgIcon(SvgIcons.deleteContactWhite),
                  )
                else
                  ContextMenuButton(
                    label: 'btn_add_to_contacts'.l10n,
                    onPressed: () => onContact?.call(true),
                    trailing: const SvgIcon(SvgIcons.addContact),
                    inverted: const SvgIcon(SvgIcons.addContactWhite),
                  ),
              ],
            ],
            if (chat.favoritePosition != null && onUnfavorite != null)
              ContextMenuButton(
                key: const Key('UnfavoriteChatButton'),
                label: 'btn_delete_from_favorites'.l10n,
                onPressed: onUnfavorite,
                trailing: const SvgIcon(SvgIcons.favoriteSmall),
                inverted: const SvgIcon(SvgIcons.favoriteSmallWhite),
              ),
            if (chat.favoritePosition == null && onFavorite != null)
              ContextMenuButton(
                key: const Key('FavoriteChatButton'),
                label: 'btn_add_to_favorites'.l10n,
                onPressed: onFavorite,
                trailing: const SvgIcon(SvgIcons.unfavoriteSmall),
                inverted: const SvgIcon(SvgIcons.unfavoriteSmallWhite),
              ),
            if (chat.muted == null && onMute != null)
              ContextMenuButton(
                key: const Key('MuteChatButton'),
                label: PlatformUtils.isMobile
                    ? 'btn_mute'.l10n
                    : 'btn_mute_chat'.l10n,
                onPressed: onMute,
                trailing: const SvgIcon(SvgIcons.unmuteSmall),
                inverted: const SvgIcon(SvgIcons.unmuteSmallWhite),
              ),
            if (chat.muted != null && onUnmute != null)
              ContextMenuButton(
                key: const Key('UnmuteChatButton'),
                label: PlatformUtils.isMobile
                    ? 'btn_unmute'.l10n
                    : 'btn_unmute_chat'.l10n,
                onPressed: onUnmute,
                trailing: const SvgIcon(SvgIcons.muteSmall),
                inverted: const SvgIcon(SvgIcons.muteSmallWhite),
              ),
            if (onHide != null)
              ContextMenuButton(
                key: const Key('ButtonHideChat'),
                label: PlatformUtils.isMobile
                    ? 'btn_delete'.l10n
                    : 'btn_delete_chat'.l10n,
                onPressed: () => _hideChat(context),
                trailing: const SvgIcon(SvgIcons.delete19),
                inverted: const SvgIcon(SvgIcons.delete19White),
              ),
          ],
          active: active || isRoute,
          selected: selected || inverted,
          // paid: paid,
          enableContextMenu: enableContextMenu,
          onTap: onTap ?? () => router.chat(chat.id),
        ),
      );
    });
  }

  /// Builds a subtitle for the provided [RxChat] containing either its
  /// [Chat.lastItem] or an [AnimatedTyping] indicating an ongoing typing.
  Widget _subtitle(BuildContext context, bool selected, bool inverted) {
    final style = Theme.of(context).style;

    if (blocked) {
      return Text(
        'Blocked',
        style: inverted
            ? style.fonts.normal.regular.onPrimary
            : style.fonts.normal.regular.secondary,
      );
    }

    return Obx(() {
      final List<Widget> subtitle;

      final Chat chat = rxChat.chat.value;
      final ChatItem? item = rxChat.lastItem;
      final ChatMessage? draft = rxChat.draft.value;

      final Iterable<String> typings = rxChat.typingUsers
          .where((User user) => user.id != me)
          .map((User user) => user.name?.val ?? user.num.toString());

      if (typings.isNotEmpty) {
        if (!rxChat.chat.value.isGroup) {
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
          final bool isMissed =
              item.finishReason == ChatCallFinishReason.dropped ||
                  item.finishReason == ChatCallFinishReason.unanswered;

          Widget widget = Padding(
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
              // Icons.call,
              // size: 16,
              // color: inverted
              //     ? style.colors.onPrimary
              //     : style.colors.secondaryBackgroundLightest,
            ),
          );

          if (item.finishedAt == null && item.finishReason == null) {
            subtitle = [
              widget,
              Flexible(child: Text('label_call_active'.l10n)),
            ];
          } else {
            final String description =
                item.finishReason?.localizedString(item.author.id == me) ??
                    'label_chat_call_ended'.l10n;
            subtitle = [widget, Flexible(child: Text(description))];
          }
        } else if (item is ChatMessage) {
          final desc = StringBuffer();

          final int? donate = item.donate;

          if (donate != null) {
            desc.write('label_donate_count'.l10nfmt({'donate': donate}));
          } else if (item.text != null) {
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
                      onError: () => rxChat.updateAttachments(item),
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
                    onError: () => rxChat.updateAttachments(item),
                  ),
                ),
              );
            }
          }

          subtitle = [
            if (item.author.id == me)
              Text('${'label_you'.l10n}${'colon_space'.l10n}')
            else if (chat.isGroup)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: FutureBuilder<RxUser?>(
                  future: getUser?.call(item.author.id),
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
                  future: getUser?.call(item.author.id),
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
                content = userBuilder(item.author.id, (context, user) {
                  user ??= item.author;
                  final Map<String, dynamic> args = {
                    'author': user.name?.val ?? user.num.toString(),
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
                final User author = item.author;
                user ??= action.user;

                if (item.author.id != action.user.id) {
                  final Map<String, dynamic> args = {
                    'author': author.name?.val ?? author.num.toString(),
                    'user': user.name?.val ?? user.num.toString(),
                  };

                  return Text('label_user_added_user'.l10nfmt(args));
                } else {
                  return Text(
                    'label_was_added'.l10nfmt(
                      {'author': user.name?.val ?? user.num.toString()},
                    ),
                  );
                }
              });
              break;

            case ChatInfoActionKind.memberRemoved:
              final action = item.action as ChatInfoActionMemberRemoved;

              if (item.author.id != action.user.id) {
                content = userBuilder(action.user.id, (context, user) {
                  final User author = item.author;
                  user ??= action.user;

                  final Map<String, dynamic> args = {
                    'author': author.name?.val ?? author.num.toString(),
                    'user': user.name?.val ?? user.num.toString(),
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
                'author': item.author.name?.val ?? item.author.num.toString(),
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
                'author': item.author.name?.val ?? item.author.num.toString(),
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
                key: key,
                height: 300,
              ),
            );
          }
        } else {
          content = FittedBox(
            fit: BoxFit.cover,
            child: VideoThumbnail.file(
              e.file.path!,
              key: key,
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
        e.medium.url,
        checksum: e.medium.checksum,
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
            key: key,
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
  Widget _status(BuildContext context, bool inverted) {
    return Obx(() {
      final Chat chat = rxChat.chat.value;

      final ChatItem? item = rxChat.lastItem;

      if (item != null && item.author.id == me && !chat.isMonolog) {
        final bool isSent = item.status.value == SendingStatus.sent;
        final bool isRead =
            chat.members.length <= 1 ? isSent : chat.isRead(item, me) && isSent;
        final bool isHalfRead = isSent &&
            chat.members.any((e) {
              if (e.user.id == me) {
                return false;
              }

              final LastChatRead? read = chat.lastReads
                  .firstWhereOrNull((m) => m.memberId == e.user.id);
              return read == null || read.at.isBefore(item.at);
            });
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
                    : isSending
                        ? isError
                            ? SvgIcons.error
                            : inverted
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
  Widget _ongoingCall(BuildContext context, {bool paid = false}) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Chat chat = rxChat.chat.value;

      if (chat.ongoingCall == null) {
        return const SizedBox();
      }

      // const Color paidColor = Color(0xFFe0f0ff);
      const Color paidColor = Color.fromRGBO(213, 232, 253, 1);

      // Returns a rounded rectangular button representing an [OngoingCall]
      // associated action.
      Widget button(bool displayed) {
        return DecoratedBox(
          key: displayed
              ? const Key('JoinCallButton')
              : const Key('DropCallButton'),
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(
              color: paid ? paidColor : style.colors.onPrimary,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Material(
            elevation: 0,
            type: MaterialType.button,
            borderRadius: BorderRadius.circular(6),
            color: displayed ? style.colors.danger : style.colors.primary,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: displayed ? onDrop : onJoin,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon(
                    //   displayed ? Icons.call_end : Icons.call,
                    //   size: 16,
                    //   color: style.colors.onPrimary,
                    // ),

                    PeriodicBuilder(
                      period: const Duration(seconds: 1),
                      builder: (_) {
                        final Duration duration =
                            DateTime.now().difference(chat.ongoingCall!.at.val);
                        final String text = duration.hhMmSs();

                        return Text(
                          text,
                          style: style.fonts.smaller.regular.onPrimary,
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
          child: AnimatedSwitcher(
            duration: 300.milliseconds,
            child: button(inCall?.call() == true),
          ),
        ),
      );
    });
  }

  /// Hides the [rxChat].
  Future<void> _hideChat(BuildContext context) async {
    bool clear = false;

    final bool? result = await MessagePopup.alert(
      'label_delete_chat'.l10n,
      // description: [
      //   TextSpan(text: 'alert_chat_will_be_hidden1'.l10n),
      //   TextSpan(text: rxChat.title.value, style: style.fonts.normal.regular.onBackground),
      //   TextSpan(text: 'alert_chat_will_be_hidden2'.l10n),
      // ],
      description: [
        TextSpan(text: 'label_to_restore_chat_use_search'.l10n),
        // TextSpan(text: rxChat.title.value, style: style.fonts.normal.regular.onBackground),
        // TextSpan(text: 'alert_chat_will_be_hidden2'.l10n),
      ],
      additional: [
        const SizedBox(height: 21),
        StatefulBuilder(builder: (context, setState) {
          return RectangleButton(
            label: 'btn_clear_history'.l10n,
            selected: clear,
            tappable: true,
            radio: true,
            onPressed: () => setState(() => clear = !clear),
          );
        })
      ],
    );

    if (result == true) {
      onHide?.call();
    }
  }

  /// Returns the [child].
  ///
  /// Uses [GestureDetector] with a dummy [GestureDetector.onLongPress] callback
  /// for discarding long presses on its [child].
  static Widget _defaultAvatarBuilder(Widget child) => GestureDetector(
        onLongPress: () {},
        child: child,
      );
}
