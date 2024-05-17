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

import 'package:drift/drift.dart';
import 'package:log_me/log_me.dart';

import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/store/model/chat_item.dart';
import '/util/obs/obs.dart';
import 'common.dart';
import 'drift.dart';

@DataClassName('ChatItemRow')
class ChatItems extends Table {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();
  TextColumn get chatId => text()();
  TextColumn get authorId => text()();
  IntColumn get at => integer().map(const PreciseDateTimeConverter())();
  IntColumn get status => intEnum<SendingStatus>()();
  TextColumn get data => text()();
  TextColumn get cursor => text().nullable()();
  TextColumn get ver => text()();
}

@DataClassName('ChatItemViewRow')
class ChatItemViews extends Table {
  @override
  Set<Column> get primaryKey => {chatId, chatItemId};

  TextColumn get chatId => text()();
  TextColumn get chatItemId => text().references(
        ChatItems,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.cascade,
      )();
}

class ChatItemDriftProvider extends DriftProviderBase {
  ChatItemDriftProvider(super.database);

  /// [StreamController] emitting [DtoChatItem]s in [watch].
  final Map<ChatId,
          StreamController<MapChangeNotification<ChatItemId, DtoChatItem>>>
      _controllers = {};

  Future<void> upsertView(ChatId chatId, ChatItemId chatItemId) async {
    Log.info('upsertView($chatId, $chatItemId)');

    await safe((db) async {
      final view =
          ChatItemViewRow(chatId: chatId.val, chatItemId: chatItemId.val);
      await db
          .into(db.chatItemViews)
          .insert(view, onConflict: DoUpdate((_) => view));
    });
  }

  /// Creates or updates the provided [item] in the database.
  Future<DtoChatItem> upsert(DtoChatItem item, {bool toView = false}) async {
    Log.info('upsert($item) toView($toView)');

    final result = await safe((db) async {
      final ChatItemRow row = item.toDb();
      final DtoChatItem stored = _ChatItemDb.fromDb(
        await db
            .into(db.chatItems)
            .insertReturning(row, onConflict: DoUpdate((_) => row)),
      );

      if (toView) {
        final ChatItemViewRow row = item.toView();
        await db
            .into(db.chatItemViews)
            .insertReturning(row, onConflict: DoUpdate((_) => row));

        _controllers[stored.value.chatId]
            ?.add(MapChangeNotification.added(stored.value.id, stored));
      }

      return stored;
    });

    return result ?? item;
  }

  /// Creates or updates the provided [items] in the database.
  Future<Iterable<DtoChatItem>> upsertBulk(
    Iterable<DtoChatItem> items, {
    bool toView = false,
  }) async {
    final result = await safe((db) async {
      Log.info('upsertBulk(${items.length} items) toView($toView)');

      await db.batch((batch) {
        for (var item in items) {
          final ChatItemRow row = item.toDb();
          batch.insert(db.chatItems, row, onConflict: DoUpdate((_) => row));
        }

        if (toView) {
          for (var item in items) {
            final ChatItemViewRow row = item.toView();
            batch.insert(db.chatItemViews, row, onConflict: DoNothing());
          }

          for (var e in items) {
            _controllers[e.value.chatId]?.add(
              MapChangeNotification.added(e.value.id, e),
            );
          }
        }
      });

      // if (toView) {
      //   await db.batch((batch) {
      //     for (var item in items) {
      //       final ChatItemViewRow row = item.toView();
      //       batch.insert(db.chatItemViews, row, onConflict: DoNothing());
      //     }

      //     for (var e in items) {
      //       _controllers[e.value.chatId]?.add(
      //         MapChangeNotification.added(e.value.id, e),
      //       );
      //     }
      //   });
      // }

      return items.toList();
    });

    return result ?? items;
  }

  /// Returns the [DtoChatItem] stored in the database by the provided [id], if
  /// any.
  Future<DtoChatItem?> read(ChatItemId id) async {
    return await safe<DtoChatItem?>((db) async {
      final stmt = db.select(db.chatItems)..where((u) => u.id.equals(id.val));
      final ChatItemRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _ChatItemDb.fromDb(row);
    });
  }

  /// Deletes the [DtoChatItem] identified by the provided [id] from the database.
  Future<void> delete(ChatItemId id) async {
    await safe((db) async {
      final stmt = db.delete(db.chatItems)..where((e) => e.id.equals(id.val));
      final response = await stmt.goAndReturn();

      for (var e in response) {
        final DtoChatItem dto = _ChatItemDb.fromDb(e);
        _controllers[id]?.add(MapChangeNotification.removed(dto.value.id, dto));
      }
    });
  }

  /// Deletes all the [DtoChatItem]s stored in the database.
  Future<void> clear() async {
    await safe((db) async {
      await db.delete(db.chatItems).go();
      await db.delete(db.chatItemViews).go();
    });
  }

  Future<List<DtoChatItem>> view(
    ChatId chatId, {
    int? before,
    int? after,
    PreciseDateTime? around,
  }) async {
    if (db == null) {
      return [];
    }

    if (around != null) {
      final stmt = db!.chatItemsAround(
        chatId.val,
        around,
        (before ?? 50).toDouble(),
        after ?? 50,
      );

      return (await stmt.get()).map(_ChatItemDb.fromDb).toList();
    }

    // SELECT * FROM chat_item_views INNER JOIN chat_items ON chat_items.id = chat_item_views.chat_item_id ORDER BY chat_items.at ASC;
    final stmt = db!.select(db!.chatItemViews).join([
      innerJoin(
        db!.chatItems,
        db!.chatItems.id.equalsExp(db!.chatItemViews.chatItemId),
      ),
    ]);

    stmt.where(db!.chatItemViews.chatId.equals(chatId.val));
    stmt.orderBy([OrderingTerm.desc(db!.chatItems.at)]);

    if (after != null || before != null) {
      stmt.limit((after ?? 0) + (before ?? 0));
    }

    return (await stmt.get())
        .map((rows) => rows.readTable(db!.chatItems))
        .map(_ChatItemDb.fromDb)
        .toList();
  }
}

/// Extension adding conversion methods from [UserRow] to [DtoUser].
extension _ChatItemDb on DtoChatItem {
  /// Returns the [DtoChatItem] from the provided [UserRow].
  static DtoChatItem fromDb(ChatItemRow e) {
    return DtoChatItem.fromJson(jsonDecode(e.data));
  }

  /// Returns the [UserRow] from this [DtoChatItem].
  ChatItemRow toDb() {
    return ChatItemRow(
      id: value.id.val,
      chatId: value.chatId.val,
      authorId: value.author.id.val,
      at: value.at,
      status: value.status.value,
      data: jsonEncode(toJson()),
      cursor: cursor?.val,
      ver: ver.val,
    );
  }

  /// Returns the [ChatItemViewRow] from this [DtoChatItem].
  ChatItemViewRow toView() {
    return ChatItemViewRow(chatItemId: value.id.val, chatId: value.chatId.val);
  }
}
