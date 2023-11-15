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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/domain/service/my_user.dart';
import '/domain/service/user.dart';
import 'view.dart';

export 'view.dart';

/// Controller of a [BlocklistView].
class BlocklistController extends GetxController {
  BlocklistController(this._myUserService, this._userService, {this.pop});

  /// Callback, called when a [BlocklistView] this controller is bound to should
  /// be popped from the [Navigator].
  final void Function()? pop;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [MyUserService] maintaining the blocked [User]s.
  final MyUserService _myUserService;

  /// [UserService] un-blocking the [User]s.
  final UserService _userService;

  /// [Worker] to react on the [blocklist] updates.
  late final Worker _worker;

  /// Returns [User]s blocked by the authenticated [MyUser].
  RxMap<UserId, RxUser> get blocklist => _myUserService.blocklist;

  @override
  void onInit() {
    _worker = ever(
      _myUserService.blocklist,
      (Map<UserId, RxUser> users) {
        if (users.isEmpty) {
          pop?.call();
        }
      },
    );

    super.onInit();
  }

  @override
  void onClose() {
    _worker.dispose();
    super.onClose();
  }

  /// Removes the [user] from the blocklist of the authenticated [MyUser].
  Future<void> unblock(RxUser user) async {
    if (blocklist.length == 1) {
      pop?.call();
    }

    await _userService.unblockUser(user.id);
  }
}
