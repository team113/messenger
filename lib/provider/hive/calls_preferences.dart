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

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model_type_id.dart';
import '/domain/model/chat.dart';
import 'base.dart';

/// [Hive] storage for [Rect] preferences of the [OngoingCall]s.
class CallsPreferencesHiveProvider extends HiveBaseProvider<Rect> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'calls_preferences';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(_RectAdapter());
  }

  /// Puts the provided [Rect] preferences to [Hive].
  Future<void> put(ChatId chatId, Rect prefs) => putSafe(chatId.val, prefs);

  /// Returns the [Rect] preferences from [Hive] by its [id].
  Rect? get(ChatId id) => getSafe(id.val);
}

/// [Hive] adapter for a [Rect].
class _RectAdapter extends TypeAdapter<Rect> {
  @override
  final int typeId = ModelTypeId.rect;

  @override
  Rect read(BinaryReader reader) {
    return Rect.fromLTWH(
      reader.read(),
      reader.read(),
      reader.read(),
      reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, Rect obj) {
    writer
      ..write(obj.left)
      ..write(obj.top)
      ..write(obj.width)
      ..write(obj.height);
  }
}
