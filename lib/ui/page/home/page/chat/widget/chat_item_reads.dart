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

import 'package:flutter/material.dart';

import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/modal_popup.dart';

/// List of [User]s for whom [ChatItem] is the last read.
///
/// Intended to be displayed with the [show] method.
class ChatItemReads extends StatelessWidget {
  const ChatItemReads({
    super.key,
    required this.lastReads,
    this.getUser,
  });

  /// List [LastChatRead]'s of this [ChatItem].
  final Iterable<LastChatRead> lastReads;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId userId)? getUser;

  /// Displays a [ChatItemReads] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required Iterable<LastChatRead> lastReads,
    Future<RxUser?> Function(UserId userId)? getUser,
  }) {
    return ModalPopup.show(
      context: context,
      child: ChatItemReads(
        lastReads: lastReads,
        getUser: getUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return ListView(
      shrinkWrap: true,
      children: [
        const SizedBox(height: 16 - 12),
        ModalPopupHeader(
          header: Center(
            child: Text(
              'label_read_by'.l10n,
              style: thin?.copyWith(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 25 - 12),
        ...lastReads.map((e) {
          return Padding(
            padding: ModalPopup.padding(context),
            child: FutureBuilder<RxUser?>(
              future: getUser?.call(e.memberId),
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: ContactTile(
                    user: snapshot.data,
                    darken: 0.05,
                    onTap: () {
                      Navigator.of(context).pop();
                      router.user(e.memberId, push: true);
                    },
                  ),
                );
              },
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
