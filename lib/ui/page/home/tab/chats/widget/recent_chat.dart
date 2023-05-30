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
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';

import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/chat_status.dart';
import '/ui/page/home/widget/chat_subtitle.dart';
import '/ui/page/home/widget/chat_tile.dart';
import '/ui/page/home/widget/ongoing_call_button.dart';
import '/ui/page/home/widget/unread_counter.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/svg/svg.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [ChatTile] representing the provided [RxChat] as a recent [Chat].
class RecentChatTile extends StatelessWidget {
  const RecentChatTile(
    this.rxChat, {
    super.key,
    this.me,
    this.blocked = false,
    this.selected = false,
    this.trailing,
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
    this.onTap,
    Widget Function(Widget)? avatarBuilder,
    this.enableContextMenu = true,
  }) : avatarBuilder = avatarBuilder ?? _defaultAvatarBuilder;

  /// [RxChat] this [RecentChatTile] is about.
  final RxChat rxChat;

  /// [UserId] of the authenticated [MyUser].
  final UserId? me;

  /// Indicator whether this [RecentChatTile] should display a blocked icon in
  /// its trailing.
  final bool blocked;

  /// Indicator whether this [RecentChatTile] is selected.
  final bool selected;

  /// [Widget]s to display in the trailing instead of the defaults.
  final List<Widget>? trailing;

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

  /// Callback, called when this [rxChat] select action is triggered.
  final void Function()? onSelect;

  /// Callback, called when this [RecentChatTile] is tapped.
  final void Function()? onTap;

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
      final Style style = Theme.of(context).extension<Style>()!;

      final Chat chat = rxChat.chat.value;
      final bool isRoute = chat.isRoute(router.route, me);
      final bool inverted = isRoute || selected;

      return ChatTile(
        chat: rxChat,
        status: [
          ChatStatus(rxChat, me, inverted),
          Text(
            chat.updatedAt.val.toLocal().short,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: inverted ? style.colors.onPrimary : null),
          ),
        ],
        subtitle: [
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 38),
            child: Row(
              children: [
                const SizedBox(height: 3),
                Expanded(
                  child: ChatSubtitle(
                    me,
                    rxChat: rxChat,
                    inverted: inverted,
                    selected: selected,
                    getUser: getUser,
                  ),
                ),
                if (trailing == null) ...[
                  _ongoingCall(context),
                  if (blocked) ...[
                    const SizedBox(width: 5),
                    Icon(
                      Icons.block,
                      color: inverted
                          ? style.colors.onPrimary
                          : style.colors.secondaryHighlightDarkest,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                  ] else if (chat.muted != null) ...[
                    const SizedBox(width: 5),
                    SvgImage.asset(
                      inverted
                          ? 'assets/icons/muted_light.svg'
                          : 'assets/icons/muted.svg',
                      key: Key('MuteIndicator_${chat.id}'),
                      width: 19.99,
                      height: 15,
                    ),
                    const SizedBox(width: 5),
                  ],
                  UnreadCounter(rxChat, inverted),
                ] else
                  ...trailing!,
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
          if (onHide != null)
            ContextMenuButton(
              key: const Key('ButtonHideChat'),
              label: PlatformUtils.isMobile
                  ? 'btn_hide'.l10n
                  : 'btn_hide_chat'.l10n,
              onPressed: () => _hideChat(context),
              trailing: const Icon(Icons.delete),
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
          const ContextMenuDivider(),
          ContextMenuButton(
            key: const Key('SelectChatButton'),
            label: 'btn_select'.l10n,
            onPressed: onSelect,
            trailing: const Icon(Icons.select_all),
          ),
        ],
        selected: inverted,
        avatarBuilder: avatarBuilder,
        enableContextMenu: enableContextMenu,
        onTap: onTap ??
            () {
              if (!isRoute) {
                router.chat(chat.id);
              }
            },
      );
    });
  }

  /// Returns a visual representation of the [Chat.ongoingCall], if any.
  Widget _ongoingCall(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Obx(() {
      final Chat chat = rxChat.chat.value;

      if (chat.ongoingCall == null) {
        return const SizedBox();
      }

      return Padding(
        padding: const EdgeInsets.only(left: 5),
        child: AnimatedSwitcher(
          duration: 300.milliseconds,
          child: OngoingCallButton(
            active: inCall?.call() == true,
            duration: DateTime.now().difference(chat.ongoingCall!.at.val),
            onDrop: onDrop,
            onJoin: onJoin,
            builder: (_) {
              final String text =
                  DateTime.now().difference(chat.ongoingCall!.at.val).hhMmSs();

              return Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: style.colors.onPrimary),
              ).fixedDigits();
            },
          ),
        ),
      );
    });
  }

  /// Hides the [rxChat].
  Future<void> _hideChat(BuildContext context) async {
    final Style style = Theme.of(context).extension<Style>()!;

    final bool? result = await MessagePopup.alert(
      'label_hide_chat'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_hidden1'.l10n),
        TextSpan(
          text: rxChat.title.value,
          style: TextStyle(color: style.colors.onBackground),
        ),
        TextSpan(text: 'alert_chat_will_be_hidden2'.l10n),
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
