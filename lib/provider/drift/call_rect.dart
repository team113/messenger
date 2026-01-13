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

import 'package:drift/drift.dart';
import 'package:flutter/rendering.dart' show Rect;

import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/service/disposable_service.dart';
import 'drift.dart';

/// [Rect]s associated with a [ChatId] to be stored in a [Table].
@DataClassName('CallRectangleRow')
class CallRectangles extends Table {
  @override
  Set<Column> get primaryKey => {chatId};

  TextColumn get chatId => text()();
  TextColumn get rect => text()();
}

/// [DriftProviderBase] for manipulating the persisted [Rect]s.
class CallRectDriftProvider extends DriftProviderBaseWithScope
    with IdentityAware {
  CallRectDriftProvider(super.common, super.scoped);

  /// [Rect]s that have started the [upsert]ing, but not yet finished it.
  final Map<ChatId, Rect> _cache = {};

  @override
  int get order => IdentityAware.providerOrder;

  @override
  void onIdentityChanged(UserId me) {
    _cache.clear();
  }

  @override
  void onInit() {
    // Fetch the stored [Rect]s before, so that [OngoingCall] is displayed
    // without any latencies.
    _all().then((items) {
      for (var e in items) {
        _cache[e.$1] = e.$2;
      }
    });

    super.onInit();
  }

  /// Creates or updates the provided [rect] in the database.
  Future<void> upsert(ChatId chatId, Rect rect) async {
    _cache[chatId] = rect;

    await safe((db) async {
      final Rect stored = _RectDb.fromDb(
        await db
            .into(db.callRectangles)
            .insertReturning(
              rect.toDb(chatId),
              mode: InsertMode.insertOrReplace,
            ),
      );

      return stored;
    });
  }

  /// Returns the [Rect] stored in the database by the provided [id], if
  /// any.
  Future<Rect?> read(ChatId id) async {
    final Rect? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<Rect?>((db) async {
      final stmt = db.select(db.callRectangles)
        ..where((u) => u.chatId.equals(id.val));
      final CallRectangleRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _RectDb.fromDb(row);
    });
  }

  /// Deletes the [Rect] identified by the provided [id] from the database.
  Future<void> delete(ChatId id) async {
    _cache.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.callRectangles)
        ..where((e) => e.chatId.equals(id.val));
      await stmt.go();
    });
  }

  /// Deletes all the [Rect]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.callRectangles).go();
    });
  }

  /// Returns all the [Rect] stored in the database.
  Future<List<(ChatId, Rect)>> _all() async {
    final result = await safe<List<(ChatId, Rect)>?>((db) async {
      final result = await db.select(db.callRectangles).get();
      return result
          .map(
            (e) => (ChatId(e.chatId), _RectJson.fromJson(jsonDecode(e.rect))),
          )
          .toList();
    }, exclusive: false);

    return result ?? [];
  }
}

/// Extension adding conversion methods from [CallRectangleRow] to [Rect].
extension _RectDb on Rect {
  /// Constructs a [Rect] from the provided [CallRectangleRow].
  static Rect fromDb(CallRectangleRow e) {
    return _RectJson.fromJson(jsonDecode(e.rect));
  }

  /// Constructs a [CallRectangleRow] from this [Rect].
  CallRectangleRow toDb(ChatId chatId) {
    return CallRectangleRow(chatId: chatId.val, rect: jsonEncode(toJson()));
  }
}

extension _RectJson on Rect {
  static Rect fromJson(Map<String, dynamic> json) {
    return Rect.fromLTRB(
      (json['left'] as num).toDouble(),
      (json['top'] as num).toDouble(),
      (json['right'] as num).toDouble(),
      (json['bottom'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'left': left, 'right': right, 'top': top, 'bottom': bottom};
  }
}
