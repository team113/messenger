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

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import 'base.dart';

/// [Hive] storage for [ChatId]s sorted by the [PreciseDateTime]s.
class RecentChatHiveProvider extends HiveBaseProvider<ChatId>
    implements IterableHiveProvider<ChatId, PreciseDateTime> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'recent_chat';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(ChatIdAdapter());
  }

  @override
  Iterable<PreciseDateTime> get keys =>
      keysSafe.map((e) => PreciseDateTime.parse(e));

  @override
  Iterable<ChatId> get values => valuesSafe;

  @override
  Future<void> put(ChatId item, [PreciseDateTime? key]) => putSafe(
        (key?.toString() ?? PreciseDateTime(DateTime.now())).toString(),
        item,
      );

  @override
  ChatId? get(PreciseDateTime key) => getSafe(key.toString());

  @override
  Future<void> remove(PreciseDateTime key) => deleteSafe(key.toString());

  /// Removes a [ChatId] item from [Hive] by the provided [index].
  Future<void> removeAt(int index) => deleteAtSafe(index);
}
