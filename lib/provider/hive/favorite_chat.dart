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
import 'package:mutex/mutex.dart';

import '/domain/model/chat.dart';
import 'base.dart';

/// [Hive] storage for [ChatId]s sorted by the [ChatFavoritePosition]s.
class FavoriteChatHiveProvider extends HiveBaseProvider<ChatId> {
  /// [Mutex] guarding synchronized access to the [put] and [remove].
  final Mutex _mutex = Mutex();

  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'favorite_chat';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(ChatIdAdapter());
  }

  /// Returns a list of [ChatId]s from [Hive].
  Iterable<ChatId> get values => valuesSafe;

  /// Puts the provided [ChatId] by the provided [key] to [Hive].
  Future<void> put(ChatFavoritePosition key, ChatId item) async {
    final String i = key.toString().padLeft(100, '0');

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

  /// Removes the provided [ChatId] from [Hive].
  Future<void> remove(ChatId item) async {
    await _mutex.protect(() async {
      final int index = values.toList().indexOf(item);
      if (index != -1) {
        await deleteAtSafe(index);
      }
    });
  }
}
