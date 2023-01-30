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

import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/modal_popup.dart';
import '/util/scroll_controller.dart';

/// View displaying the provided [reads] along with corresponding [User]s.
///
/// Intended to be displayed with the [show] method.
class ChatItemReads extends StatefulWidget {
  const ChatItemReads({
    super.key,
    this.reads = const [],
    this.getUser,
  });

  /// [LastChatRead]s themselves.
  final Iterable<LastChatRead> reads;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId userId)? getUser;

  /// Displays a [ChatItemReads] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    Iterable<LastChatRead> reads = const [],
    Future<RxUser?> Function(UserId userId)? getUser,
  }) {
    return ModalPopup.show(
      context: context,
      child: ChatItemReads(reads: reads, getUser: getUser),
    );
  }

  @override
  State<ChatItemReads> createState() => _ChatItemReadsState();
}

/// State of a [ChatItemReads] maintaining the [_scrollController].
class _ChatItemReadsState extends State<ChatItemReads> {
  /// [CustomScrollController] to pass to a [ListView].
  final CustomScrollController _scrollController = CustomScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black);

    return ListView(
      shrinkWrap: true,
      controller: _scrollController,
      children: [
        const SizedBox(height: 4),
        ModalPopupHeader(
          header: Center(
            child: Text(
              'label_read_by'.l10n,
              style: thin?.copyWith(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 13),
        ...widget.reads.map((e) {
          return Padding(
            padding: ModalPopup.padding(context),
            child: FutureBuilder<RxUser?>(
              future: widget.getUser?.call(e.memberId),
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
