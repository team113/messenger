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

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/user.dart';
import '/util/log.dart';
import 'base.dart';

/// [Hive] storage for blocked [UserId]s of the authenticated [MyUser].
class BlocklistHiveProvider extends HiveLazyProvider<bool> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'blocklist';

  @override
  void registerAdapters() {}

  /// Returns a list of [UserId]s from [Hive].
  Iterable<UserId> get blocked => box.keys.map((e) => UserId(e));

  /// Puts the provided [UserId] to [Hive].
  Future<void> put(UserId id) async {
    Log.debug('put($id)', '$runtimeType');
    await putSafe(id.val, true);
  }

  /// Indicates whether the provided [id] is stored in [Hive].
  Future<bool> get(UserId id) async {
    Log.debug('get($id)', '$runtimeType');
    return (await getSafe(id.val)) ?? false;
  }

  /// Removes the provided [UserId] from [Hive].
  Future<void> remove(UserId id) async {
    Log.debug('remove($id)', '$runtimeType');
    await deleteSafe(id.val);
  }
}
