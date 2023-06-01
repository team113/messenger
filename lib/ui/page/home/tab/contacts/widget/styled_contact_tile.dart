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

import '/domain/model/contact.dart';
import '/domain/repository/contact.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/selected_dot.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// [Widget] which returns a [ListTile] with [contact]'s information.
class StyledContactTile extends StatelessWidget {
  const StyledContactTile(
    this.contact, {
    super.key,
    required this.favorites,
    required this.selectedContacts,
    required this.selecting,
    this.unfavoriteContact,
    this.favoriteContact,
    this.removeFromContacts,
    this.toggleSelecting,
    this.avatarBuilder,
    this.onTap,
    required this.inverted,
  });

  /// Reactive favorited [ChatContact].
  final RxChatContact contact;

  /// [List] of favorited [ChatContact]s.
  final List<RxChatContact> favorites;

  /// [List] of [ChatContactId]s of the selected [ChatContact]s.
  final List<ChatContactId> selectedContacts;

  /// Indicator whether multiple [ChatContact]s selection is active.
  final bool selecting;

  /// Indicator whether this [StyledContactTile] should have its colors
  /// inverted.
  final bool inverted;

  /// Callback, called when this [StyledContactTile] is tapped.
  final void Function()? onTap;

  /// Removes the specified [ChatContact] identified by its id from the
  /// favorites.
  final void Function()? unfavoriteContact;

  /// Marks the specified [ChatContact] identified by its id as favorited.
  final void Function()? favoriteContact;

  /// Toggles the [ChatContact]s selection.
  final void Function()? toggleSelecting;

  /// Opens a confirmation popup deleting the provided [contact] from address
  /// book.
  final void Function()? removeFromContacts;

  /// Returns a [ListTile] with [contact]'s information.
  final Widget Function(Widget)? avatarBuilder;

  @override
  Widget build(BuildContext context) {
    // Indicator whether the contact is in the user's favorites list or not.
    final bool favorite = favorites.contains(contact);

    // Status of the user associated with the contact, or null if there is
    // no user.
    final String? subtitle = contact.user.value?.user.value.getStatus();

    // Current dialog associated with the user for the contact, or null if
    // there is no user or dialog.
    final dialog = contact.user.value?.dialog.value;

    return ContactTile(
      key: Key('Contact_${contact.id}'),
      contact: contact,
      folded: favorite,
      selected: inverted,
      enableContextMenu: !selecting,
      avatarBuilder: selecting
          ? (child) => WidgetButton(
                // TODO: Open [Routes.contact] page when it's implemented.
                onPressed: () => router.user(contact.user.value!.id),
                child: avatarBuilder?.call(child) ?? child,
              )
          : avatarBuilder,
      onTap: onTap,
      actions: [
        favorite
            ? ContextMenuButton(
                key: const Key('UnfavoriteContactButton'),
                label: 'btn_delete_from_favorites'.l10n,
                onPressed: unfavoriteContact,
                trailing: const Icon(Icons.star_border),
              )
            : ContextMenuButton(
                key: const Key('FavoriteContactButton'),
                label: 'btn_add_to_favorites'.l10n,
                onPressed: favoriteContact,
                trailing: const Icon(Icons.star),
              ),
        ContextMenuButton(
          label: 'btn_delete'.l10n,
          onPressed: removeFromContacts,
          trailing: const Icon(Icons.delete),
        ),
        const ContextMenuDivider(),
        ContextMenuButton(
          key: const Key('SelectContactButton'),
          label: 'btn_select'.l10n,
          onPressed: toggleSelecting,
          trailing: const Icon(Icons.select_all),
        ),
      ],
      subtitle: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    color: inverted ? Colors.white : Colors.grey,
                  ),
                )
              : const SizedBox(),
        ),
      ],
      trailing: [
        dialog?.chat.value.muted == null ||
                contact.user.value?.user.value.isBlacklisted != null
            ? const SizedBox()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: SvgImage.asset(
                  inverted
                      ? 'assets/icons/muted_light.svg'
                      : 'assets/icons/muted.svg',
                  key: Key('MuteIndicator_${contact.id}'),
                  width: 19.99,
                  height: 15,
                ),
              ),
        contact.user.value?.user.value.isBlacklisted == null
            ? const SizedBox()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.block,
                  color: inverted ? Colors.white : const Color(0xFFDEDEDE),
                  size: 20,
                ),
              ),
        !selecting
            ? const SizedBox()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: SelectedDot(
                  selected: selectedContacts.contains(contact.id),
                  size: 22,
                ),
              ),
      ],
    );
  }
}
