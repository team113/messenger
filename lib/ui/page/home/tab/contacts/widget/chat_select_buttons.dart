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

import '/domain/model/contact.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/util/platform_utils.dart';

/// [Widget] which returns the animated [OutlinedRoundedButton]s for multiple
/// selected chat contacts manipulation.
class ChatSelectButtons extends StatelessWidget {
  const ChatSelectButtons(
    this.selectedContacts, {
    super.key,
    required this.deleteCount,
    required this.removeContacts,
    required this.toggleSelecting,
  });

  /// [List] of [ChatContactId]s of the selected [ChatContact]s.
  final List<ChatContactId> selectedContacts;

  /// Count of selected [ChatContact]s to be deleted.
  final String deleteCount;

  /// Toggles the [ChatContact]s selection.
  final void Function() toggleSelecting;

  /// Opens a confirmation popup deleting the selected contacts.
  final void Function() removeContacts;

  @override
  Widget build(BuildContext context) {
    const List<CustomBoxShadow> shadows = [
      CustomBoxShadow(
        blurRadius: 8,
        color: Color(0x22000000),
        blurStyle: BlurStyle.outer,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        7,
        8,
        PlatformUtils.isMobile && !PlatformUtils.isWeb
            ? router.context!.mediaQuery.padding.bottom + 7
            : 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedRoundedButton(
              title: Text(
                'btn_close'.l10n,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(color: Colors.black),
              ),
              onPressed: toggleSelecting,
              color: Colors.white,
              shadows: shadows,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedRoundedButton(
              key: const Key('DeleteContacts'),
              title: Text(
                'btn_delete_count'.l10nfmt({'count': deleteCount}),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: selectedContacts.isEmpty ? Colors.black : Colors.white,
                ),
              ),
              onPressed: selectedContacts.isEmpty ? null : removeContacts,
              color: Theme.of(context).colorScheme.secondary,
              shadows: shadows,
            ),
          ),
        ],
      ),
    );
  }
}
