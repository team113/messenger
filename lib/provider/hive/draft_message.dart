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

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model_type_id.dart';
import 'base.dart';

part 'draft_message.g.dart';

/// [Hive] storage for [HiveDraftMessage].
class DraftMessageHiveProvider extends HiveBaseProvider<HiveDraftMessage> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'draftMessage';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(HiveDraftMessageAdapter());
  }

  /// Returns [ChatMessage] finded by [ChatId].
  ChatMessage? get(ChatId chatId) => getSafe(chatId.val)?.chatMessage;

  /// Saves the provided [HiveDraftMessage] to [Hive].
  void set(ChatMessage chatMessage) => putSafe(
        chatMessage.chatId.val,
        HiveDraftMessage(chatMessage),
      );

  /// Deletes the stored [HiveDraftMessage].
  void delete(ChatId chatId) => deleteSafe(chatId.val);
}

/// Persisted in [Hive] storage background's [ChatMessage] value.
@HiveType(typeId: ModelTypeId.draftMessage)
class HiveDraftMessage extends HiveObject {
  HiveDraftMessage(this.chatMessage);

  @HiveField(0)
  final ChatMessage chatMessage;
}
