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

import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/model/chat.dart';
import '/domain/model_type_id.dart';
import 'base.dart';

part 'typed_in_chats.g.dart';

/// [Hive] storage for [HiveBackground].
class TypedInChatHiveProvider extends HiveBaseProvider<HiveTypedInChat> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'typedInChat';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(HiveTypedInChatAdapter());
  }

  HiveTypedInChat? get(ChatId chatId) => getSafe(chatId.val);

  /// Saves the provided [Uint8List] to [Hive].
  void set(ChatId chatId, String text) => putSafe(
        chatId.val,
        HiveTypedInChat(
          text,
        ),
      );

  /// Deletes the stored [Uint8List].
  Future<void> delete(String chatId) => deleteSafe(chatId);
}

/// Persisted in [Hive] storage background's [Uint8List] value.
@HiveType(typeId: ModelTypeId.typedInChat)
class HiveTypedInChat extends HiveObject {
  HiveTypedInChat(this.text);

  @HiveField(0)
  final String text;
}
