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
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/user.dart';
import '/ui/widget/text_field.dart';

/// Controller of the [MessageInfo] popup.
class MessageInfoController extends GetxController {
  MessageInfoController(this._userService, {this.reads = const []});

  /// [LastChatRead]s who read the [ChatItem] this [MessageInfo] is about.
  final Iterable<LastChatRead> reads;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [TextFieldState] of the search field.
  final TextFieldState search = TextFieldState();

  /// Reactive value of the [search] field.
  final RxString query = RxString('');

  /// [RxUser]s of the [reads].
  final RxList<RxUser> users = RxList();

  /// [UserService] fetching the [users].
  final UserService _userService;

  @override
  void onInit() {
    _fetchUsers();
    super.onInit();
  }

  /// Fetches the [users] from the [UserService].
  Future<void> _fetchUsers() async {
    final List<Future> futures = reads
        .map((e) => _userService.get(e.memberId)
          ..then((u) {
            if (u != null) {
              users.add(u);
            }
          }))
        .whereNotNull()
        .toList();

    await Future.wait(futures);
  }
}
