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

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/provider/hive/preferences.dart';
import '/util/platform_utils.dart';
import 'disposable_service.dart';

/// Service responsible for listening window's size and position.
class WindowService extends DisposableService {
  /// Subscription to the [PlatformUtils.onResized] updating the local data.
  late final StreamSubscription? _onResized;

  /// Subscription to the [PlatformUtils.onMoved] updating the local data.
  late final StreamSubscription? _onMoved;

  /// [PreferencesHiveProvider] used to store window's position and size.
  late final PreferencesHiveProvider _preferencesProvider;

  @override
  void onInit() {
    _preferencesProvider = Get.find();
    _onResized = PlatformUtils.onResized.listen((v) => _storeData(size: v));
    _onMoved = PlatformUtils.onMoved.listen((v) => _storeData(position: v));
    super.onInit();
  }

  @override
  void onClose() {
    _onResized?.cancel();
    _onMoved?.cancel();
  }

  /// Stores window's size and position to [PreferencesHiveProvider].
  void _storeData({Size? size, Offset? position}) async =>
      _preferencesProvider.setWindowPreferences(
        size: size,
        position: position,
      );
}
