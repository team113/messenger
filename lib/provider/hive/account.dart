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

import 'package:hive/hive.dart';

import '/domain/model/user.dart';
import '/util/log.dart';
import 'base.dart';

/// [Hive] storage for the currently active [MyUser]'s [UserId].
class AccountHiveProvider extends HiveBaseProvider<UserId> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch(key: 0);

  @override
  String get boxName => 'account';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');
    Hive.maybeRegisterAdapter(UserIdAdapter());
  }

  /// Returns the currently active [MyUser]'s [UserId].
  UserId? get userId {
    Log.trace('get', '$runtimeType');
    return getSafe(0);
  }

  /// Saves the currently active [MyUser]'s [UserId].
  Future<void> set(UserId id) async {
    Log.trace('set($id)', '$runtimeType');
    await putSafe(0, id);
  }
}
