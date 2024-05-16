import 'dart:convert';

import 'package:drift/drift.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/sending_status.dart';
import 'common.dart';
import 'drift.dart';

@DataClassName('ChatItemRow')
@TableIndex(name: 'chat_id', columns: {#chatId})
class ChatItems extends Table {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();
  TextColumn get chatId => text()();
  TextColumn get authorId => text()();
  IntColumn get at => integer().map(const PreciseDateTimeConverter())();
  IntColumn get status => intEnum<SendingStatus>()();
  TextColumn get data => text()();
}

@DataClassName('ChatItemViewRow')
@TableIndex(name: 'chat_id', columns: {#chatId})
class ChatItemViews extends Table {
  @override
  Set<Column> get primaryKey => {chatId, chatItemId, at};

  TextColumn get chatId => text()();
  TextColumn get chatItemId => text().references(ChatItems, #id)();
  IntColumn get at => integer().map(const PreciseDateTimeConverter())();
}

class ChatItemDriftProvider {
  ChatItemDriftProvider(this._database);

  final DriftProvider _database;

  Future<List<ChatItem>> items(
    ChatId chatId, {
    int? limit,
    int? offset,
  }) async {
    final stmt = _database.select(_database.chatItems);
    stmt.where((u) => u.chatId.equals(chatId.val));

    stmt.orderBy([(u) => OrderingTerm.desc(u.at)]);

    if (limit != null) {
      stmt.limit(limit, offset: offset);
    }

    final response = await stmt.get();
    return response.map(_ChatItemDb.fromDb).toList();
  }

  Future<void> create(ChatItem item) async {
    await _database.into(_database.chatItems).insert(item.toDb());
  }

  Future<void> update(ChatItem item) async {
    final stmt = _database.update(_database.chatItems);
    await stmt.replace(item.toDb());
  }

  Future<void> delete(ChatItemId id) async {
    final stmt = _database.delete(_database.chatItems)
      ..where((e) => e.id.equals(id.val));

    await stmt.go();
  }

  Future<void> clear() async {
    await _database.delete(_database.chatItems).go();
  }

  Stream<List<MapChangeNotification<ChatItemId, ChatItem>>> watch(
    ChatId chatId, {
    int? limit,
    int? offset,
  }) {
    final stmt = _database.select(_database.chatItems);
    stmt.where((u) => u.chatId.equals(chatId.val));

    stmt.orderBy([(u) => OrderingTerm.desc(u.at)]);

    if (limit != null) {
      stmt.limit(limit, offset: offset);
    }

    print('[built] ${stmt.constructQuery().buffer.toString()}');

    return stmt
        .watch()
        .map((items) => {for (var e in items.map(_ChatItemDb.fromDb)) e.id: e})
        .changes();
  }

  Future<void> txn<T>(Future<T> Function() action) async {
    await _database.transaction(action);
  }
}

extension _ChatItemDb on ChatItem {
  static ChatItem fromDb(ChatItemRow e) {
    return ChatItem.fromJson(jsonDecode(e.data));
  }

  ChatItemRow toDb() {
    return ChatItemRow(
      id: id.val,
      chatId: chatId.val,
      authorId: authorId.val,
      at: at,
      status: status.value,
      data: jsonEncode(toJson()),
    );
  }
}
