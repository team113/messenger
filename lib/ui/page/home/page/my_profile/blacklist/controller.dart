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

import 'dart:async';

import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/domain/service/my_user.dart';
import '/domain/service/user.dart';
import '/util/obs/obs.dart';
import 'view.dart';

export 'view.dart';

/// Controller of a [BlacklistView].
class BlacklistController extends GetxController {
  BlacklistController(this._myUserService, this._userService);

  /// [MyUserService] maintaining the blacklisted [User]s.
  final MyUserService _myUserService;

  /// [UserService] using in the [unblacklist] and the [_getUser] methods.
  final UserService _userService;

  /// Subscription to the [blacklist] changes.
  StreamSubscription? blacklistSubscription;

  /// [Map] of the [RxUser]s fetched from the [_userService].
  final RxMap<UserId, RxUser> users = RxMap<UserId, RxUser>();

  /// Returns IDs of the [User]s blacklisted by the authenticated [MyUser].
  RxObsList<UserId> get blacklist => _myUserService.blacklist;

  @override
  void onInit() {
    for (var e in blacklist) {
      _getUser(e).then((value) {
        if (value != null) {
          users[e] = value;
        }
      });
    }

    blacklistSubscription = blacklist.changes.listen((event) {
      switch (event.op) {
        case OperationKind.added:
          _getUser(event.element).then((value) {
            if (value != null) {
              users[event.element] = value;
            }
          });
          break;
        case OperationKind.removed:
          users.remove(event.element);
          break;
        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    super.onInit();
  }

  @override
  void onClose() {
    blacklistSubscription?.cancel();
    super.onClose();
  }

  /// Removes the [user] from the blacklist of the authenticated [MyUser].
  Future<void> unblacklist(RxUser user) =>
      _userService.unblacklistUser(user.id);

  /// Returns an [User] by the provided [id].
  Future<RxUser?> _getUser(UserId id) => _userService.get(id);
}
