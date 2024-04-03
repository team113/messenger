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

import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/util/log.dart';
import 'base.dart';

/// [Hive] storage for [UserId]s sorted by the [PreciseDateTime]s and secondary
/// by [UserId].
class ChatMemberSortingHiveProvider extends HiveBaseProvider<UserId> {
  ChatMemberSortingHiveProvider(this.id);

  /// ID of a [Chat] this provider is bound to.
  final ChatId id;

  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'members_sorting_$id';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters($id)', '$runtimeType');
    Hive.maybeRegisterAdapter(UserIdAdapter());
  }

  /// Returns the list of [UserId]s from [Hive].
  Iterable<UserId> get values => valuesSafe;

  /// Puts the provided [UserId] by the provided [time] to [Hive].
  Future<void> put(PreciseDateTime time, UserId id) async {
    Log.trace('put($time, $id)', '$runtimeType');
    await putSafe('${time.toUtc().toString()}_$id', id);
  }

  /// Removes the provided [UserId] from [Hive].
  Future<void> remove(UserId id) async {
    Log.trace('remove($id)', '$runtimeType');

    final int index = valuesSafe.toList().indexOf(id);
    if (index != -1) {
      await deleteAtSafe(index);
    }
  }
}
