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

import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/util/log.dart';
import 'base.dart';

/// [Hive] storage for [ChatItemId]s sorted by the [ChatItemKey]s.
class ChatItemSortingHiveProvider extends HiveBaseProvider<ChatItemId> {
  ChatItemSortingHiveProvider(this.id);

  /// ID of a [Chat] this provider is bound to.
  final ChatId id;

  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'messages_sorting_$id';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters($id)', '$runtimeType');

    Hive.maybeRegisterAdapter(ChatItemIdAdapter());
  }

  /// Returns a list of [ChatItemKey] keys stored in the [Hive].
  Iterable<ChatItemKey> get keys =>
      keysSafe.map((e) => ChatItemKey.fromString(e));

  /// Returns a list of [ChatItemId]s from [Hive].
  Iterable<ChatItemId> get values => valuesSafe;

  /// Puts the provided [key] to [Hive].
  Future<void> put(ChatItemKey key) async {
    Log.trace('put($key))', '$runtimeType');
    await putSafe(key.toString(), key.id);
  }

  /// Removes the provided [ChatItemKey] from [Hive].
  Future<void> remove(ChatItemKey key) async {
    Log.trace('remove($key)', '$runtimeType');
    await deleteSafe(key.toString());
  }
}
