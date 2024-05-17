import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';

import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
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
  Set<Column> get primaryKey => {chatId, chatItemId, at};

  TextColumn get chatId => text()();
  TextColumn get chatItemId => text().references(ChatItems, #id)();
  IntColumn get at => integer().map(const PreciseDateTimeConverter())();
}

class ChatItemDriftProvider extends DriftProviderBase {
  ChatItemDriftProvider(super.database);

  /// [StreamController] emitting [DtoChatItem]s in [watch].
  final Map<ChatId,
          StreamController<MapChangeNotification<ChatItemId, DtoChatItem>>>
      _controllers = {};

  /// Creates or updates the provided [item] in the database.
  Future<DtoChatItem> upsert(DtoChatItem item, {bool toView = false}) async {
    final result = await safe((db) async {
      final DtoChatItem stored = _ChatItemDb.fromDb(
        await db
            .into(db.chatItems)
            .insertReturning(item.toDb(), mode: InsertMode.replace),
      );

      if (toView) {
        await db
            .into(db.chatItemViews)
            .insertReturning(item.toView(), mode: InsertMode.replace);
      }

      _controllers[stored.value.chatId]
          ?.add(MapChangeNotification.added(stored.value.id, stored));

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
      await db.batch((batch) {
        batch.insertAll(
          db.chatItems,
          items.map((e) => e.toDb()),
          mode: InsertMode.replace,
        );

        if (toView) {
          batch.insertAll(
            db.chatItemViews,
            items.map((e) => e.toView()),
            mode: InsertMode.replace,
          );
        }

        for (var e in items) {
          _controllers[e.value.chatId]?.add(
            MapChangeNotification.added(e.value.id, e),
          );
        }
      });

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

  Stream<List<MapChangeNotification<ChatItemId, DtoChatItem>>> watch(
    ChatId chatId, {
    int? before,
    int? after,
    PreciseDateTime? around,
  }) {
    if (db == null) {
      return const Stream.empty();
    }

    if (around != null) {
      final stmt = db!.chatItemsAround(
        chatId.val,
        around,
        (before ?? 50).toDouble(),
        after ?? 50,
      );

      return stmt
          .watch()
          .map((i) => {for (var e in i.map(_ChatItemDb.fromDb)) e.value.id: e})
          .changes();
    }

    final stmt = db!.select(db!.chatItems);
    stmt.where((u) => u.chatId.equals(chatId.val));

    stmt.orderBy([(u) => OrderingTerm.desc(u.at)]);

    if (after != null || before != null) {
      stmt.limit((after ?? 0) + (before ?? 0));
    }

    return stmt
        .watch()
        .map((i) => {for (var e in i.map(_ChatItemDb.fromDb)) e.value.id: e})
        .changes();
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
    return ChatItemViewRow(
      chatItemId: value.id.val,
      chatId: value.chatId.val,
      at: value.at,
    );
  }
}
