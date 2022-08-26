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

import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/service/disposable_service.dart';
import '/domain/service/my_user.dart';
import '/routes.dart';

/// Worker responsible for updating the [RouterState.prefix] with the
/// [MyUser.unreadChatsCount].
class MyUserWorker extends DisposableService {
  MyUserWorker(this._myUser);

  /// [MyUserService], used to listen to the [MyUser] changes.
  final MyUserService _myUser;

  /// [Worker] reacting on the [MyUser] changes.
  Worker? _worker;

  /// [MyUser.unreadChatsCount] latest value, used to exclude the unnecessary
  /// [_updateBadge] invokes.
  int? _lastUnreadChatsCount;

  @override
  void onInit() {
    _updateBadge(_myUser.myUser.value?.unreadChatsCount ?? 0);
    router.prefix.value = _myUser.myUser.value == null ||
            _myUser.myUser.value?.unreadChatsCount == 0
        ? null
        : '(${_myUser.myUser.value!.unreadChatsCount})';

    _worker = ever(_myUser.myUser, (MyUser? u) {
      _updateBadge(u?.unreadChatsCount ?? 0);
      router.prefix.value = u == null || u.unreadChatsCount == 0
          ? null
          : '(${u.unreadChatsCount})';
    });

    super.onInit();
  }

  @override
  void onClose() {
    _worker?.dispose();
    router.prefix.value = null;
    super.onClose();
  }

  /// Updates the application's badge with the provided [count].
  void _updateBadge(int count) async {
    if (_lastUnreadChatsCount != count) {
      _lastUnreadChatsCount = count;
      if (await FlutterAppBadger.isAppBadgeSupported()) {
        if (count == 0) {
          FlutterAppBadger.removeBadge();
        } else {
          FlutterAppBadger.updateBadgeCount(count);
        }
      }
    }
  }
}
