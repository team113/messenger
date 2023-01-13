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
import 'package:messenger/ui/widget/text_field.dart';

import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View displaying the provided [reads] along with corresponding [User]s.
///
/// Intended to be displayed with the [show] method.
class ChatItemReads extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: ChatItemReadsController(reads: reads, getUser: getUser),
      builder: (ChatItemReadsController c) {
        return Obx(() {
          return ListView(
            shrinkWrap: true,
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
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                  child: ReactiveTextField(
                    key: const Key('SearchTextField'),
                    state: c.search,
                    label: 'label_search'.l10n,
                    style: thin,
                    onChanged: () => c.query.value = c.search.text,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ...c.users.where((p) {
                if (c.query.value != null) {
                  return p.user.value.name?.val
                          .toLowerCase()
                          .contains(c.query.value!.toLowerCase()) ==
                      true;
                }

                return true;
              }).map((e) {
                return Padding(
                  padding: ModalPopup.padding(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: ContactTile(
                      user: e,
                      darken: 0.05,
                      onTap: () {
                        Navigator.of(context).pop();
                        router.user(e.id, push: true);
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          );
        });
      },
    );
  }
}
