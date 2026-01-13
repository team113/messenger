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
import 'dart:convert';

import 'package:async/async.dart';
import 'package:drift/drift.dart';

import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/service/disposable_service.dart';
import 'drift.dart';

/// [ChatMessage]s being [Chat] drafts to be stored in a [Table].
@DataClassName('DraftRow')
class Drafts extends Table {
  @override
  Set<Column> get primaryKey => {chatId};

  TextColumn get chatId => text()();
  TextColumn get data => text()();
}

/// [DriftProviderBase] for manipulating the persisted [ChatMessage] drafts.
class DraftDriftProvider extends DriftProviderBaseWithScope with IdentityAware {
  DraftDriftProvider(super.common, super.scoped);

  /// [StreamController] emitting [ChatMessage]s in [watch].
  final Map<ChatId, StreamController<ChatMessage?>> _controllers = {};

  /// [ChatMessage] that have started the [upsert]ing, but not yet finished it.
  final Map<ChatId, ChatMessage> _cache = {};

  @override
  int get order => IdentityAware.providerOrder;

  @override
  void onIdentityChanged(UserId me) {
    _cache.clear();
  }

  /// Creates or updates the provided [message] in the database.
  Future<void> upsert(ChatId id, ChatMessage message) async {
    _cache[id] = message;
    _controllers[id]?.add(message);

    await safe((db) async {
      await db
          .into(db.drafts)
          .insertReturning(message.toDb(), mode: InsertMode.insertOrReplace);
    }, tag: 'draft.upsert($id, message)');

    _cache.remove(id);
  }

  /// Returns the [ChatMessage] stored in the database by the provided [id], if
  /// any.
  Future<ChatMessage?> read(ChatId id) async {
    final ChatMessage? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<ChatMessage?>(
      (db) async {
        final stmt = db.select(db.drafts)
          ..where((u) => u.chatId.equals(id.val));
        final DraftRow? row = await stmt.getSingleOrNull();

        if (row == null) {
          return null;
        }

        return _DraftDb.fromDb(row);
      },
      tag: 'draft.read($id)',
      exclusive: false,
    );
  }

  /// Deletes the [ChatMessage] identified by the provided [id] from the
  /// database.
  Future<void> delete(ChatId id) async {
    _cache.remove(id);
    _controllers[id]?.add(null);

    await safe((db) async {
      final stmt = db.delete(db.drafts)..where((e) => e.chatId.equals(id.val));
      await stmt.go();
    }, tag: 'draft.delete($id)');
  }

  /// Deletes all the [ChatMessage]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.drafts).go();
    }, tag: 'draft.clear()');
  }

  /// Moves the [ChatId] of [ChatMessage] from [from] to [to].
  Future<void> move(ChatId from, ChatId to) async {
    _cache.remove(from);

    _controllers[to]?.close();
    final StreamController<ChatMessage?>? controller = _controllers.remove(
      from,
    );

    if (controller != null) {
      _controllers[to] = controller;
    }

    await safe((db) async {
      final stmt = db.select(db.drafts)
        ..where((e) => e.chatId.equals(from.val));
      final row = await stmt.getSingleOrNull();

      if (row != null) {
        await db
            .update(db.drafts)
            .replace(DraftRow(chatId: to.val, data: row.data));
      }
    });
  }

  /// Returns the [Stream] of real-time changes happening with the draft in the
  /// [Chat] identified by the provided [id].
  Stream<ChatMessage?> watch(ChatId id) {
    return stream((db) {
      final stmt = db.select(db.drafts)..where((u) => u.chatId.equals(id.val));

      StreamController<ChatMessage?>? controller = _controllers[id];
      if (controller == null) {
        controller = StreamController<ChatMessage?>.broadcast(sync: true);
        _controllers[id] = controller;
      }

      ChatMessage? last;

      return StreamGroup.merge([
        controller.stream,
        stmt.watch().map((e) => e.isEmpty ? null : _DraftDb.fromDb(e.first)),
      ]).asyncExpand((e) async* {
        if (e != last) {
          last = e;
          yield e;
        }
      });
    });
  }
}

/// Extension adding conversion methods from [DraftRow] to [ChatMessage].
extension _DraftDb on ChatMessage {
  /// Constructs a [ChatMessage] from the provided [DraftRow].
  static ChatMessage fromDb(DraftRow e) {
    return ChatMessage.fromJson(jsonDecode(e.data));
  }

  /// Constructs a [DraftRow] from this [ChatMessage].
  DraftRow toDb() {
    return DraftRow(chatId: chatId.val, data: jsonEncode(toJson()));
  }
}
