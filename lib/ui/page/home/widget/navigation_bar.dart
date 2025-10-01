// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import '/api/backend/schema.dart' show Presence;
import '/domain/model/my_user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/context_menu/tile.dart';
import '/ui/widget/safe_area/safe_area.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import 'avatar.dart';
import 'partner_icon.dart';
import 'wallet_icon.dart';

/// Styled bottom navigation bar consisting of [items].
class CustomNavigationBar extends StatefulWidget {
  const CustomNavigationBar({
    super.key,
    this.currentIndex = 0,
    this.items = const [],
    this.onTap,
  });

  /// Currently selected index of an item in the [items] list.
  final int currentIndex;

  /// [Widget]s this [CustomNavigationBar] consists of.
  final List<Widget> items;

  /// Callback, called when an item in [items] list is pressed.
  final Function(int)? onTap;

  /// Height of the [CustomNavigationBar].
  static double get height {
    double padding = 0;
    if (router.context != null) {
      padding = MediaQuery.of(router.context!).padding.bottom;
      padding += CustomSafeArea.isPwa ? 25 : 0;
    }

    return 56 + padding;
  }

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

/// State of a [CustomNavigationBar] maintaining the [_keys].
class _CustomNavigationBarState extends State<CustomNavigationBar> {
  /// [GlobalKey] of the [Widget]s of the [CustomNavigationBar].
  ///
  /// Used to prevent rebuilding the same item when the list of items changes.
  final List<GlobalKey> _keys = [];

  @override
  void initState() {
    _keys.addAll(List.generate(widget.items.length, (_) => GlobalKey()));
    super.initState();
  }

  @override
  void didUpdateWidget(CustomNavigationBar oldWidget) {
    final List<GlobalKey> keys = [];

    if (oldWidget.items.length != widget.items.length) {
      for (var e in widget.items) {
        final int index = oldWidget.items.indexOf(e);
        keys.add(index == -1 ? GlobalKey() : _keys[index]);
      }

      _keys.clear();
      _keys.addAll(keys);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          CustomBoxShadow(
            blurRadius: 8,
            color: style.colors.onBackgroundOpacity13,
            blurStyle: BlurStyle.outer.workaround,
          ),
        ],
        border: style.cardBorder,
      ),
      child: Container(
        decoration: BoxDecoration(color: style.cardColor),
        height: CustomNavigationBar.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 56 - 18,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: widget.items.mapIndexed((i, b) {
                    final bool selected = widget.currentIndex == i;

                    return AnimatedScale(
                      key: _keys[i],
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.bounceInOut,
                      scale: selected ? 1.1 : 1,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: selected ? 1 : 0.7,
                        child: AnimatedButton(
                          onPressed: () => widget.onTap?.call(i),
                          child: b,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single item of [CustomNavigationBar].
class CustomNavigationBarItem extends StatelessWidget {
  const CustomNavigationBarItem._({
    super.key,
    required this.tab,
    this.badge,
    this.danger = true,
    required this.child,
  });

  /// Constructs a [CustomNavigationBarItem] for a `HomeTab.contacts`.
  const CustomNavigationBarItem.contacts({Key? key})
    : this._(
        key: key,
        tab: HomeTab.chats,
        child: const SvgIcon(SvgIcons.contacts, key: Key('ContactsButton')),
      );

  /// Constructs a [CustomNavigationBarItem] for a `HomeTab.wallet`.
  CustomNavigationBarItem.wallet({Key? key, double balance = 0})
    : this._(
        key: key,
        tab: HomeTab.wallet,
        child: WalletIcon(key: Key('WalletButton'), balance: balance),
      );

  /// Constructs a [CustomNavigationBarItem] for a `HomeTab.partner`.
  CustomNavigationBarItem.partner({Key? key, double balance = 0})
    : this._(
        key: key,
        tab: HomeTab.partner,
        child: PartnerIcon(key: Key('PartnerButton'), balance: balance),
      );

  /// Constructs a [CustomNavigationBarItem] for a [HomeTab.chats].
  CustomNavigationBarItem.chats({
    Key? key,
    String unread = '0',
    bool danger = true,
    GlobalKey? selector,
    void Function(bool)? onMute,
  }) : this._(
         key: key,
         tab: HomeTab.chats,
         badge: unread == '' || unread == '0' ? null : unread,
         danger: danger,
         child: ContextMenuRegion(
           key: const Key('ChatsButton'),
           selector: selector,
           alignment: Alignment.bottomCenter,
           margin: const EdgeInsets.only(bottom: 16),
           actions: [
             if (danger)
               ContextMenuTile(
                 key: const Key('MuteChatsButton'),
                 asset: SvgIcons.unmuted22,
                 label: 'btn_mute_chats'.l10n,
                 onPressed: (_) => onMute?.call(false),
               )
             else
               ContextMenuTile(
                 key: const Key('UnmuteChatsButton'),
                 asset: SvgIcons.muted22,
                 label: 'btn_unmute_chats'.l10n,
                 onPressed: (_) => onMute?.call(true),
               ),
           ],
           child: SafeAnimatedSwitcher(
             key: selector,
             duration: const Duration(milliseconds: 200),
             child: danger
                 ? const SvgIcon(SvgIcons.chats, key: Key('Unmuted'))
                 : const SvgIcon(SvgIcons.chatsMuted, key: Key('Muted')),
           ),
         ),
       );

  /// Constructs a [CustomNavigationBarItem] for a [HomeTab.menu].
  CustomNavigationBarItem.menu({
    Key? key,
    Color? acceptAuxiliary,
    Color? warning,
    GlobalKey? selector,
    MyUser? myUser,
    List<ContextMenuItem> actions = const [],
    void Function(Presence)? onPresence,
    void Function()? onAvatar,
  }) : this._(
         key: key,
         tab: HomeTab.menu,
         child: ContextMenuRegion(
           selector: selector,
           selectorClosable: false,
           key: const Key('MenuButton'),
           alignment: Alignment.bottomRight,
           margin: const EdgeInsets.only(bottom: 8, left: 8),
           actions: [
             ...actions,
             ContextMenuTile(
               label: 'label_presence_present'.l10n,
               onPressed: (context) {
                 onPresence?.call(Presence.present);
                 Navigator.of(context).pop();
               },
               trailing: Container(
                 width: 16,
                 height: 16,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   color: acceptAuxiliary,
                 ),
               ),
             ),
             ContextMenuTile(
               label: 'label_presence_away'.l10n,
               onPressed: (context) {
                 onPresence?.call(Presence.away);
                 Navigator.of(context).pop();
               },
               trailing: Container(
                 width: 16,
                 height: 16,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   color: warning,
                 ),
               ),
             ),
           ],
           child: Padding(
             padding: const EdgeInsets.only(bottom: 2),
             child: AvatarWidget.fromMyUser(
               myUser,
               radius: AvatarRadius.normal,
               onForbidden: onAvatar,
             ),
           ),
         ),
       );

  /// Optional text to put into a [Badge] over this item.
  final String? badge;

  /// Indicator whether the provided [badge] should have its danger [Color].
  final bool danger;

  /// [Widget] to display.
  final Widget child;

  /// [HomeTab] that this [CustomNavigationBarItem] represents.
  final HomeTab tab;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      color: style.colors.transparent,
      child: Center(
        child: Badge(
          largeSize: 15,
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4.4),
          offset: const Offset(2, -2),
          label: badge == null
              ? null
              : Transform.translate(
                  offset: PlatformUtils.isWeb
                      ? Offset(0, PlatformUtils.isIOS ? 0 : 0.25)
                      : PlatformUtils.isDesktop
                      ? const Offset(-0.1, -0.2)
                      : Offset.zero,
                  child: Text(badge!, textAlign: TextAlign.center),
                ),
          textStyle: style.fonts.smallest.regular.onPrimary,
          backgroundColor: danger
              ? style.colors.danger
              : style.colors.secondaryHighlightDarkest,
          isLabelVisible: badge != null,
          child: child,
        ),
      ),
    );
  }
}
