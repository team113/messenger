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
import 'package:mutex/mutex.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/util/log.dart';
import 'base.dart';

/// [Hive] storage for [UserId]s sorted by the [PreciseDateTime]s and secondary
/// by [UserId].
class BlocklistSortingHiveProvider extends HiveBaseProvider<UserId> {
  /// [Mutex] guarding synchronized access to the [put] and [remove].
  final Mutex _mutex = Mutex();

  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'blocklist_sorting';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');
    Hive.maybeRegisterAdapter(UserIdAdapter());
  }

  /// Returns a list of [UserId]s from [Hive].
  Iterable<UserId> get values => valuesSafe;

  /// Puts the provided [UserId] by the provided [key] to [Hive].
  Future<void> put(PreciseDateTime key, UserId item) async {
    Log.trace('put($key, $item)', '$runtimeType');

    final String i = '${key.toUtc().toString()}_$item';

    if (getSafe(i) != item) {
      await _mutex.protect(() async {
        final int index = values.toList().indexOf(item);
        if (index != -1) {
          await deleteAtSafe(index);
        }

        await putSafe(i, item);
      });
    }
  }

  /// Removes the provided [UserId] from [Hive].
  Future<void> remove(UserId item) async {
    Log.trace('remove($item)', '$runtimeType');

    await _mutex.protect(() async {
      final int index = values.toList().indexOf(item);
      if (index != -1) {
        await deleteAtSafe(index);
      }
    });
  }
}
