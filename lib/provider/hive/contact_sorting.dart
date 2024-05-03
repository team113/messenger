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

import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/util/log.dart';
import 'base.dart';

/// [Hive] storage for [ChatContactId]s sorted by the [UserName]s and secondary
/// by [ChatContactId].
class ContactSortingHiveProvider extends HiveBaseProvider<ChatContactId> {
  /// [Mutex] guarding synchronized access to the [put] and [remove].
  final Mutex _mutex = Mutex();

  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'contact_sorting';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');
    Hive.maybeRegisterAdapter(ChatContactIdAdapter());
  }

  /// Returns a list of [ChatContactId]s from [Hive].
  Iterable<ChatContactId> get values => valuesSafe;

  /// Puts the provided [ChatContactId] by the provided [name] to [Hive].
  Future<void> put(UserName name, ChatContactId item) async {
    Log.trace('put($name, $item)', '$runtimeType');

    final String key = '${name}_$item';

    if (getSafe(key) != item) {
      await _mutex.protect(() async {
        final int index = values.toList().indexOf(item);
        if (index != -1) {
          await deleteAtSafe(index);
        }

        await putSafe(key, item);
      });
    }
  }

  /// Removes the provided [ChatContactId] from [Hive].
  Future<void> remove(ChatContactId item) async {
    Log.trace('remove($item)', '$runtimeType');

    await _mutex.protect(() async {
      final int index = values.toList().indexOf(item);
      if (index != -1) {
        await deleteAtSafe(index);
      }
    });
  }
}
