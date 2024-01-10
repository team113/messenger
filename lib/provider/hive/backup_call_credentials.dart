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

import '/domain/model/chat_call.dart';
import '/domain/model/chat.dart';
import '/util/log.dart';
import 'base.dart';

/// [Hive] temporary storage for [ChatCallCredentials].
class BackupCallCredentialsHiveProvider
    extends HiveBaseProvider<ChatCallCredentials> {
  BackupCallCredentialsHiveProvider();

  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'backup_call_credentials';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');
    Hive.maybeRegisterAdapter(ChatCallCredentialsAdapter());
  }

  /// Puts the provided [ChatCallCredentials] to [Hive].
  Future<void> put(ChatId chatId, ChatCallCredentials creds) async {
    Log.debug('put($chatId, $creds)', '$runtimeType');
    await putSafe(chatId.val, creds);
  }

  /// Returns the [ChatCallCredentials] from [Hive] by the provided [ChatId].
  ChatCallCredentials? get(ChatId chatId) {
    Log.debug('get($chatId)', '$runtimeType');
    return getSafe(chatId.val);
  }

  /// Removes the [ChatCallCredentials] from [Hive] by the provided [ChatId].
  Future<void> remove(ChatId chatId) async {
    Log.debug('remove($chatId)', '$runtimeType');
    await deleteSafe(chatId.val);
  }
}
