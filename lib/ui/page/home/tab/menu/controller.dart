// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/api/backend/schema.dart' show UserPresence;
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/routes.dart';
import '/util/obs/rxmap.dart';

export 'view.dart';

/// Controller of the [HomeTab.menu] tab.
class MenuTabController extends GetxController {
  MenuTabController(this._myUserService);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [GlobalKey] of an [AvatarWidget] in the tab title.
  final GlobalKey profileKey = GlobalKey();

  /// Service managing [MyUser].
  final MyUserService _myUserService;

  /// Returns the current [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns the known [MyUser] profiles.
  RxObsMap<UserId, Rx<MyUser>> get profiles => _myUserService.profiles;

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Sets the [MyUser.presence] to the provided value.
  Future<void> setPresence(UserPresence presence) =>
      _myUserService.updateUserPresence(presence);
}
