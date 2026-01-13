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
import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/domain/service/disposable_service.dart';
import 'drift.dart';

/// [ChatCallCredentials] to be stored in a [Table].
@DataClassName('CallCredentialsRow')
class CallCredentials extends Table {
  @override
  Set<Column> get primaryKey => {callId};

  TextColumn get callId => text()();
  TextColumn get credentials => text()();
}

/// [DriftProviderBase] for manipulating the persisted [ChatCallCredentials].
class CallCredentialsDriftProvider extends DriftProviderBaseWithScope
    with IdentityAware {
  CallCredentialsDriftProvider(super.common, super.scoped);

  /// [ChatCallCredentials] that have started the [upsert]ing, but not yet
  /// finished it.
  final Map<ChatItemId, ChatCallCredentials> _cache = {};

  @override
  int get order => IdentityAware.providerOrder;

  @override
  void onIdentityChanged(UserId me) {
    _cache.clear();
  }

  /// Creates or updates the provided [credentials] in the database.
  Future<void> upsert(ChatItemId id, ChatCallCredentials credentials) async {
    _cache[id] = credentials;

    await safe((db) async {
      await db
          .into(db.callCredentials)
          .insertReturning(
            credentials.toDb(id),
            mode: InsertMode.insertOrReplace,
          );
    }, tag: 'call_credentials.upsert($id, credentials)');

    _cache.remove(id);
  }

  /// Returns the [ChatCallCredentials] stored in the database by the provided
  /// [id], if any.
  Future<ChatCallCredentials?> read(ChatItemId id) async {
    final ChatCallCredentials? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<ChatCallCredentials?>(
      (db) async {
        final stmt = db.select(db.callCredentials)
          ..where((u) => u.callId.equals(id.val));
        final CallCredentialsRow? row = await stmt.getSingleOrNull();

        if (row == null) {
          return null;
        }

        return _CallCredentialsDb.fromDb(row);
      },
      tag: 'call_credentials.read($id)',
      exclusive: false,
    );
  }

  /// Deletes the [ChatCallCredentials] identified by the provided [id] from the database.
  Future<void> delete(ChatItemId id) async {
    _cache.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.callCredentials)
        ..where((e) => e.callId.equals(id.val));
      await stmt.go();
    }, tag: 'call_credentials.delete($id)');
  }

  /// Deletes all the [ChatCallCredentials]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.callCredentials).go();
    }, tag: 'call_credentials.clear()');
  }
}

/// Extension adding conversion methods from [CallCredentialsRow] to
/// [ChatCallCredentials].
extension _CallCredentialsDb on ChatCallCredentials {
  /// Constructs a [ChatCallCredentials] from the provided [CallCredentialsRow].
  static ChatCallCredentials fromDb(CallCredentialsRow e) {
    return ChatCallCredentials(e.credentials);
  }

  /// Constructs a [CallCredentialsRow] from this [ChatCallCredentials].
  CallCredentialsRow toDb(ChatItemId id) {
    return CallCredentialsRow(callId: id.val, credentials: val);
  }
}
