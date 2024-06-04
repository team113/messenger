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

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:drift/drift.dart';

import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/store/model/user.dart';
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
class CallCredentialsDriftProvider extends DriftProviderBaseWithScope {
  CallCredentialsDriftProvider(super.common, super.scoped);

  /// [ChatCallCredentials] that have started the [upsert]ing, but not yet
  /// finished it.
  final Map<ChatItemId, ChatCallCredentials> _cache = {};

  /// Creates or updates the provided [credentials] in the database.
  Future<void> upsert(ChatItemId id, ChatCallCredentials credentials) async {
    _cache[id] = credentials;

    await safe((db) async {
      await db
          .into(db.users)
          .insertReturning(user.toDb(), mode: InsertMode.insertOrReplace);
    });

    _cache.remove(id);
  }

  /// Returns the [DtoUser] stored in the database by the provided [id], if
  /// any.
  Future<DtoUser?> read(UserId id) async {
    final DtoUser? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<DtoUser?>((db) async {
      final stmt = db.select(db.users)..where((u) => u.id.equals(id.val));
      final CallCredentialsRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return UserDb.fromDb(row);
    });
  }

  /// Deletes the [DtoUser] identified by the provided [id] from the database.
  Future<void> delete(UserId id) async {
    _cache.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.users)..where((e) => e.id.equals(id.val));
      await stmt.go();

      _controllers[id]?.add(null);
    });
  }

  /// Deletes all the [DtoUser]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.users).go();
    });
  }

  /// Returns the [Stream] of real-time changes happening with the [DtoUser]
  /// identified by the provided [id].
  Stream<DtoUser?> watch(UserId id) {
    return stream((db) {
      final stmt = db.select(db.users)..where((u) => u.id.equals(id.val));

      StreamController<DtoUser?>? controller = _controllers[id];
      if (controller == null) {
        controller = StreamController<DtoUser?>.broadcast(sync: true);
        _controllers[id] = controller;
      }

      return StreamGroup.merge(
        [
          controller.stream,
          stmt.watch().map((e) => e.isEmpty ? null : UserDb.fromDb(e.first)),
        ],
      );
    });
  }
}

/// Extension adding conversion methods from [CallCredentialsRow] to [DtoUser].
extension _CallCredentialsDb on CallCredentials {
  /// Constructs a [DtoUser] from the provided [CallCredentialsRow].
  static ChatCallCredentials fromDb(CallCredentialsRow e) {
    return ChatCallCredentials(e.credentials);
  }

  /// Constructs a [CallCredentialsRow] from this [DtoUser].
  CallCredentialsRow toDb() {
    return CallCredentialsRow(
      id: value.id.val,
      num: value.num.val,
      name: value.name?.val,
      bio: value.bio?.val,
      avatar: value.avatar == null ? null : jsonEncode(value.avatar?.toJson()),
      callCover: value.callCover == null
          ? null
          : jsonEncode(value.callCover?.toJson()),
      mutualContactsCount: value.mutualContactsCount,
      online: value.online,
      presenceIndex: value.presenceIndex,
      status: value.status?.val,
      isDeleted: value.isDeleted,
      dialog: value.dialog.val,
      isBlocked: value.isBlocked == null
          ? null
          : jsonEncode(value.isBlocked?.toJson()),
      lastSeenAt: value.lastSeenAt,
      contacts: jsonEncode(value.contacts.map((e) => e.toJson()).toList()),
      ver: ver.val,
      blockedVer: blockedVer.val,
    );
  }
}
