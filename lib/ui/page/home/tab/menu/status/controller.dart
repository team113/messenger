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

import 'package:get/get.dart';
import 'package:messenger/domain/model/my_user.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/service/my_user.dart';

class MoreController extends GetxController {
  MoreController(this._myUserService);

  final Rx<Presence?> presence = Rx(null);

  final MyUserService _myUserService;

  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Sets the [MyUser.presence] to the provided value.
  Future<void> setPresence(Presence presence) =>
      _myUserService.updateUserPresence(presence);

  onInit() {
    presence.value = myUser.value?.presence;
  }

  onClose() {
    if (myUser.value?.presence != presence.value && presence.value != null) {
      setPresence(presence.value!);
    }
  }
}
