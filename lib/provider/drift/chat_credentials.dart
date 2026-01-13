// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'dart:async';

import 'package:drift/drift.dart';

import '/domain/model/chat_call.dart';
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/service/disposable_service.dart';
import 'drift.dart';

/// [ChatCallCredentials] to be stored in a [Table].
@DataClassName('ChatCredentialsRow')
class ChatCredentials extends Table {
  @override
  Set<Column> get primaryKey => {chatId};

  TextColumn get chatId => text()();
  TextColumn get credentials => text()();
}

/// [DriftProviderBase] for manipulating the persisted [ChatCallCredentials].
class ChatCredentialsDriftProvider extends DriftProviderBaseWithScope
    with IdentityAware {
  ChatCredentialsDriftProvider(super.common, super.scoped);

  /// [ChatCallCredentials] that have started the [upsert]ing, but not yet
  /// finished it.
  final Map<ChatId, ChatCallCredentials> _cache = {};

  @override
  int get order => IdentityAware.providerOrder;

  @override
  void onIdentityChanged(UserId me) {
    _cache.clear();
  }

  /// Creates or updates the provided [credentials] in the database.
  Future<void> upsert(ChatId id, ChatCallCredentials credentials) async {
    _cache[id] = credentials;

    await safe((db) async {
      await db
          .into(db.chatCredentials)
          .insertReturning(
            credentials.toDb(id),
            mode: InsertMode.insertOrReplace,
          );
    });

    _cache.remove(id);
  }

  /// Returns the [ChatCallCredentials] stored in the database by the provided
  /// [id], if any.
  Future<ChatCallCredentials?> read(ChatId id) async {
    final ChatCallCredentials? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<ChatCallCredentials?>((db) async {
      final stmt = db.select(db.chatCredentials)
        ..where((u) => u.chatId.equals(id.val));
      final ChatCredentialsRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _CallCredentialsDb.fromDb(row);
    }, exclusive: false);
  }

  /// Deletes the [ChatCallCredentials] identified by the provided [id] from the database.
  Future<void> delete(ChatId id) async {
    _cache.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.chatCredentials)
        ..where((e) => e.chatId.equals(id.val));
      await stmt.go();
    });
  }

  /// Deletes all the [ChatCallCredentials]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.chatCredentials).go();
    });
  }
}

/// Extension adding conversion methods from [ChatCredentialsRow] to
/// [ChatCallCredentials].
extension _CallCredentialsDb on ChatCallCredentials {
  /// Constructs a [ChatCallCredentials] from the provided [ChatCredentialsRow].
  static ChatCallCredentials fromDb(ChatCredentialsRow e) {
    return ChatCallCredentials(e.credentials);
  }

  /// Constructs a [ChatCredentialsRow] from this [ChatCallCredentials].
  ChatCredentialsRow toDb(ChatId id) {
    return ChatCredentialsRow(chatId: id.val, credentials: val);
  }
}
