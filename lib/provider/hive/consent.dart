// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:hive_flutter/adapters.dart';

import '/util/log.dart';
import 'base.dart';

/// [Hive] storage for a consent boolean storage.
class ConsentHiveProvider extends HiveBaseProvider<bool> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch(key: 0);

  @override
  String get boxName => 'consent';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');
  }

  /// Returns the stored consent value from [Hive].
  bool? get() {
    Log.trace('get()', '$runtimeType');
    return getSafe(0);
  }

  /// Stores new consent [value] to [Hive].
  Future<void> set(bool value) async {
    Log.trace('set($value)', '$runtimeType');
    await putSafe(0, value);
  }
}
