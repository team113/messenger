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

import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import 'action.dart';

/// [Widget] which returns the action buttons to do with this [User].
class ActionsWidget extends StatelessWidget {
  const ActionsWidget({
    super.key,
    required this.inContacts,
    required this.inFavorites,
    required this.status,
    required this.blacklistStatus,
    required this.removeFromContacts,
    required this.hideChat,
    required this.clearChat,
    required this.blacklistUser,
    required this.user,
    required this.isBlacklisted,
    required this.addToContacts,
    required this.unfavoriteContact,
    required this.favoriteContact,
    required this.unmuteChat,
    required this.muteChat,
    required this.unblacklist,
  });

  /// Indicator whether this [user] is already in the contacts list of the
  /// authenticated [MyUser].
  final bool inContacts;

  /// Indicator whether the [user] is favorite.
  final bool inFavorites;

  /// Status of the [user] fetching.
  final RxStatus status;

  /// Status of a [blacklist] progression.
  final RxStatus blacklistStatus;

  /// Reactive [User] itself.
  final RxUser? user;

  /// Indicator whether this [user] is blacklisted.
  final BlacklistRecord? isBlacklisted;

  /// Adds the [user] to the contacts list of the authenticated [MyUser].
  final void Function()? addToContacts;

  /// Removes the [user] from the favorites.
  final void Function()? unfavoriteContact;

  /// Marks the [user] as favorited.
  final void Function()? favoriteContact;

  /// Unmutes a [Chat]-dialog with the [user].
  final void Function()? unmuteChat;

  /// Mutes a [Chat]-dialog with the [user].
  final void Function()? muteChat;

  /// Removes the [user] from the blacklist of the authenticated [MyUser].
  final void Function()? unblacklist;

  /// Opens a confirmation popup deleting the [User] from address book.
  final void Function()? removeFromContacts;

  /// Opens a confirmation popup hiding the [Chat]-dialog with the [User].
  final void Function()? hideChat;

  /// Opens a confirmation popup clearing the [Chat]-dialog with the [User].
  final void Function()? clearChat;

  /// Opens a confirmation popup blacklisting the [User].
  final void Function()? blacklistUser;

  @override
  Widget build(BuildContext context) {
    /// ???
    final chat = user!.dialog.value!.chat.value;
    final bool isMuted = chat.muted != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActionWidget(
          key: Key(
            inContacts ? 'DeleteFromContactsButton' : 'AddToContactsButton',
          ),
          text: inContacts
              ? 'btn_delete_from_contacts'.l10n
              : 'btn_add_to_contacts'.l10n,
          onPressed: status.isLoadingMore
              ? null
              : inContacts
                  ? () => removeFromContacts
                  : addToContacts,
        ),
        ActionWidget(
          text: inFavorites
              ? 'btn_delete_from_favorites'.l10n
              : 'btn_add_to_favorites'.l10n,
          onPressed: inFavorites ? unfavoriteContact : favoriteContact,
        ),
        if (user?.user.value.dialog.isLocal == false &&
            user?.dialog.value != null) ...[
          ActionWidget(
            text: isMuted ? 'btn_unmute_chat'.l10n : 'btn_mute_chat'.l10n,
            trailing: isMuted
                ? SvgImage.asset(
                    'assets/icons/btn_mute.svg',
                    width: 18.68,
                    height: 15,
                  )
                : SvgImage.asset(
                    'assets/icons/btn_unmute.svg',
                    width: 17.86,
                    height: 15,
                  ),
            onPressed: isMuted ? unmuteChat : muteChat,
          ),
          ActionWidget(
            text: 'btn_hide_chat'.l10n,
            trailing: SvgImage.asset('assets/icons/delete.svg', height: 14),
            onPressed: hideChat,
          ),
          ActionWidget(
            key: const Key('ClearHistoryButton'),
            text: 'btn_clear_history'.l10n,
            trailing: SvgImage.asset('assets/icons/delete.svg', height: 14),
            onPressed: clearChat,
          ),
        ],
        ActionWidget(
          key: Key(isBlacklisted != null ? 'Unblock' : 'Block'),
          text: isBlacklisted != null ? 'btn_unblock'.l10n : 'btn_block'.l10n,
          onPressed: isBlacklisted != null ? unblacklist : () => blacklistUser,
          trailing: AnimatedOpacity(
            duration: 200.milliseconds,
            opacity: blacklistStatus.isEmpty ? 0 : 1,
            child: const CustomProgressIndicator(),
          ),
        ),
        ActionWidget(text: 'btn_report'.l10n, onPressed: () {}),
      ],
    );
  }
}
