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

import '/domain/service/disposable_service.dart';
import '/provider/hive/window.dart';
import '/util/platform_utils.dart';

/// Worker updating the [WindowPreferences] on the [WindowListener] changes.
class WindowWorker extends DisposableService {
  WindowWorker(this._windowProvider);

  /// [WindowPreferencesHiveProvider] maintaining the [WindowPreferences].
  final WindowPreferencesHiveProvider _windowProvider;

  /// Subscription to the [PlatformUtils.onResized] updating the size.
  late final StreamSubscription? _onResized;

  /// Subscription to the [PlatformUtils.onMoved] updating the position.
  late final StreamSubscription? _onMoved;

  @override
  void onInit() {
    _onResized = PlatformUtils.onResized.listen(
      (v) => _windowProvider.set(
        size: v.size,
        position: v.position,
      ),
    );
    _onMoved =
        PlatformUtils.onMoved.listen((v) => _windowProvider.set(position: v));
    super.onInit();
  }

  @override
  void onClose() {
    _onResized?.cancel();
    _onMoved?.cancel();
    super.onClose();
  }
}
