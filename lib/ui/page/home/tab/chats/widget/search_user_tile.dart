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
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/contact_tile.dart';

/// [ContactTile] intended to be used as a search result representing the
/// provided [User] or [ChatContact].
class SearchUserTile extends StatelessWidget {
  const SearchUserTile({
    super.key,
    this.user,
    this.contact,
    this.onTap,
  }) : assert(user != null || contact != null);

  /// [RxUser] this [SearchUserTile] is about.
  final RxUser? user;

  /// [RxChatContact] this [SearchUserTile] is about.
  final RxChatContact? contact;

  /// Callback, called when this [SearchUserTile] is pressed.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      final ChatId? chatId =
          user?.user.value.dialog ?? contact?.user.value?.user.value.dialog;

      final UserId? userId = user?.id ?? contact?.user.value?.id;

      final bool selected = router.routes.lastWhereOrNull((e) =>
              e.startsWith('${Routes.chats}/$chatId') ||
              e.startsWith('${Routes.user}/$userId')) !=
          null;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ContactTile(
          contact: contact,
          user: user,
          darken: 0,
          onTap: onTap,
          selected: selected,
          subtitle: [
            const SizedBox(height: 5),
            Text(
              '${'label_num'.l10n}${'colon_space'.l10n}${(contact?.user.value?.user.value.num ?? user?.user.value.num)}',
              style: selected
                  ? style.fonts.small.regular.onPrimary
                  : style.fonts.small.regular.secondary,
            ),
          ],
          trailing: [
            if (user?.user.value.isBlocked != null ||
                contact?.user.value?.user.value.isBlocked != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.block,
                  color: selected
                      ? style.colors.onPrimary
                      : style.colors.secondaryHighlightDarkest,
                  size: 20,
                ),
              )
          ],
        ),
      );
    });
  }
}
