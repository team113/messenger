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

/// [ChatItem] to be stored in a [Table].
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

/// [Table] for [RxChat.messages] history retrieving.
@DataClassName('ChatItemViewRow')
class ChatItemViews extends Table {
  @override
  Set<Column> get primaryKey => {chatId, chatItemId};

  TextColumn get chatId => text()();
  TextColumn get chatItemId => text()();
}

/// [DriftProviderBase] for manipulating the persisted [ChatItem]s.
class ChatItemDriftProvider extends DriftProviderBaseWithScope {
  ChatItemDriftProvider(super.common, super.scoped);

  /// [DtoChatItem]s that have started the [upsert]ing, but not yet finished it.
  final Map<ChatItemId, DtoChatItem> _cache = {};

  /// Creates or updates the a view for the provided [chatItemId] in [chatId].
  Future<void> upsertView(ChatId chatId, ChatItemId chatItemId) async {
    Log.debug('upsertView($chatId, $chatItemId)');

    await safe((db) async {
      final view =
          ChatItemViewRow(chatId: chatId.val, chatItemId: chatItemId.val);
      await db
          .into(db.chatItemViews)
          .insert(view, onConflict: DoUpdate((_) => view));
    });
  }

  /// Creates or updates the provided [item] in the database.
  ///
  /// If [toView] is `true`, then also adds a view to the [ChatItemViews].
  Future<DtoChatItem> upsert(DtoChatItem item, {bool toView = false}) async {
    Log.debug('upsert($item) toView($toView)');

    _cache[item.value.id] = item;

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
      }

      return stored;
    });

    _cache.remove(item.value.id);

    return result ?? item;
  }

  /// Creates or updates the provided [items] in the database.
  ///
  /// If [toView] is `true`, then also adds the views to the [ChatItemViews].
  Future<Iterable<DtoChatItem>> upsertBulk(
    Iterable<DtoChatItem> items, {
    bool toView = false,
  }) async {
    for (var e in items) {
      _cache[e.value.id] = e;
    }

    final result = await safe((db) async {
      Log.debug('upsertBulk(${items.length} items) toView($toView)');

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
        }
      });

      return items.toList();
    });

    for (var e in items) {
      _cache.remove(e.value.id);
    }

    return result ?? items;
  }

  /// Returns the [DtoChatItem] stored in the database by the provided [id], if
  /// any.
  Future<DtoChatItem?> read(ChatItemId id) async {
    final DtoChatItem? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<DtoChatItem?>((db) async {
      final stmt = db.select(db.chatItems)..where((u) => u.id.equals(id.val));
      final ChatItemRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _ChatItemDb.fromDb(row);
    });
  }

  /// Deletes the [DtoChatItem] identified by the provided [id] from the
  /// database.
  Future<void> delete(ChatItemId id) async {
    _cache.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.chatItems)..where((e) => e.id.equals(id.val));
      await stmt.goAndReturn();
    });
  }

  /// Deletes all the [DtoChatItem]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.chatItems).go();
      await db.delete(db.chatItemViews).go();
    });
  }

  /// Returns the [DtoChatItem]s being in a historical view order of the
  /// provided [chatId].
  Future<List<DtoChatItem>> view(
    ChatId chatId, {
    int? before,
    int? after,
    PreciseDateTime? around,
  }) async {
    final result = await safe((db) async {
      if (around != null) {
        final stmt = db.chatItemsAround(
          chatId.val,
          around,
          (before ?? 50).toDouble(),
          after ?? 50,
        );

        return (await stmt.get())
            .map(
              (r) => ChatItemRow(
                id: r.id,
                chatId: r.chatId,
                authorId: r.authorId,
                at: r.at,
                status: r.status,
                data: r.data,
                cursor: r.cursor,
                ver: r.ver,
              ),
            )
            .map(_ChatItemDb.fromDb)
            .toList();
      }

      final stmt = db.select(db.chatItemViews).join([
        innerJoin(
          db.chatItems,
          db.chatItems.id.equalsExp(db.chatItemViews.chatItemId),
        ),
      ]);

      stmt.where(db.chatItemViews.chatId.equals(chatId.val));
      stmt.orderBy([OrderingTerm.desc(db.chatItems.at)]);

      if (after != null || before != null) {
        stmt.limit((after ?? 0) + (before ?? 0));
      }

      return (await stmt.get())
          .map((rows) => rows.readTable(db.chatItems))
          .map(_ChatItemDb.fromDb)
          .toList();
    });

    return result ?? [];
  }

  /// Returns the [DtoChatItem]s containing any [Attachment]s, in a historical
  /// view order of the provided [chatId].
  Future<List<DtoChatItem>> attachments(
    ChatId chatId, {
    int? before,
    int? after,
    PreciseDateTime? around,
  }) async {
    final result = await safe((db) async {
      if (around != null) {
        final stmt = db.attachmentsAround(
          chatId.val,
          around,
          (before ?? 50).toDouble(),
          after ?? 50,
        );

        return (await stmt.get())
            .map(
              (r) => ChatItemRow(
                id: r.id,
                chatId: r.chatId,
                authorId: r.authorId,
                at: r.at,
                status: r.status,
                data: r.data,
                cursor: r.cursor,
                ver: r.ver,
              ),
            )
            .map(_ChatItemDb.fromDb)
            .toList();
      }

      final stmt = db.select(db.chatItemViews).join([
        innerJoin(
          db.chatItems,
          db.chatItems.id.equalsExp(db.chatItemViews.chatItemId),
        ),
      ]);

      stmt.where(
        db.chatItemViews.chatId.equals(chatId.val) &
            db.chatItems.data.like('%"attachments":[{'),
      );
      stmt.orderBy([OrderingTerm.desc(db.chatItems.at)]);

      if (after != null || before != null) {
        stmt.limit((after ?? 0) + (before ?? 0));
      }

      return (await stmt.get())
          .map((rows) => rows.readTable(db.chatItems))
          .map(_ChatItemDb.fromDb)
          .toList();
    });

    return result ?? [];
  }

  /// Returns the [Stream] of [DtoChatItem]s being in a historical view order of
  /// the provided [chatId].
  Stream<List<MapChangeNotification<ChatItemId, DtoChatItem>>> watch(
    ChatId chatId, {
    int? before,
    int? after,
    PreciseDateTime? around,
  }) {
    return stream((db) {
      // if (around != null) {
      //   final stmt = db.chatItemsAround(
      //     chatId.val,
      //     around,
      //     (before ?? 50).toDouble(),
      //     after ?? 50,
      //   );

      //   return stmt
      //       .watch()
      //       .map(
      //         (items) => {
      //           for (var e in items
      //               .map(
      //                 (r) => ChatItemRow(
      //                   id: r.id,
      //                   chatId: r.chatId,
      //                   authorId: r.authorId,
      //                   at: r.at,
      //                   status: r.status,
      //                   data: r.data,
      //                   cursor: r.cursor,
      //                   ver: r.ver,
      //                 ),
      //               )
      //               .map(_ChatItemDb.fromDb))
      //             e.value.id: e
      //         },
      //       )
      //       .changes();
      // }

      final stmt = db.select(db.chatItemViews).join([
        innerJoin(
          db.chatItems,
          db.chatItems.id.equalsExp(db.chatItemViews.chatItemId),
        ),
      ]);

      stmt.where(db.chatItemViews.chatId.equals(chatId.val));
      stmt.orderBy([OrderingTerm.desc(db.chatItems.at)]);

      if (after != null || before != null) {
        stmt.limit((after ?? 0) + (before ?? 0));
      }

      return stmt
          .watch()
          .map((rows) => rows.map((e) => e.readTable(db.chatItems)))
          .map(
            (m) => {for (var e in m.map(_ChatItemDb.fromDb)) e.value.id: e},
          )
          .changes();
    });
  }

  /// Returns the [Stream] of the last [DtoChatItem] added to a historical view
  /// order of the provided [chatId].
  Stream<List<MapChangeNotification<ChatItemId, DtoChatItem>>> after(
    ChatId chatId,
    PreciseDateTime at,
  ) {
    Log.info('after($at)', '$runtimeType');

    return stream((db) {
      final stmt = db.select(db.chatItemViews).join([
        innerJoin(
          db.chatItems,
          db.chatItems.id.equalsExp(db.chatItemViews.chatItemId),
        ),
      ]);

      stmt.where(
        db.chatItemViews.chatId.equals(chatId.val) &
            db.chatItems.at.isBiggerOrEqualValue(at.microsecondsSinceEpoch),
      );

      stmt.orderBy([OrderingTerm.asc(db.chatItems.at)]);

      Log.info(
        'after($at) -> stmt -> ${stmt.constructQuery().buffer.toString()}',
        '$runtimeType',
      );

      return stmt
          .watch()
          .map((rows) => rows.map((e) => e.readTable(db.chatItems)))
          .map(
            (m) => {for (var e in m.map(_ChatItemDb.fromDb)) e.value.id: e},
          )
          .changes(tag: 'after');
    });
  }

  /// Returns the [Stream] of the last [DtoChatItem] added to a historical view
  /// order of the provided [chatId].
  Stream<List<MapChangeNotification<ChatItemId, DtoChatItem>>> before(
    ChatId chatId,
    PreciseDateTime at,
  ) {
    Log.info('before($at)', '$runtimeType');

    return stream((db) {
      final stmt = db.select(db.chatItemViews).join([
        innerJoin(
          db.chatItems,
          db.chatItems.id.equalsExp(db.chatItemViews.chatItemId),
        ),
      ]);

      stmt.where(
        db.chatItemViews.chatId.equals(chatId.val) &
            db.chatItems.at.isSmallerOrEqualValue(at.microsecondsSinceEpoch),
      );

      stmt.orderBy([OrderingTerm.asc(db.chatItems.at)]);

      return stmt
          .watch()
          .map((rows) => rows.map((e) => e.readTable(db.chatItems)))
          .map(
            (m) => {for (var e in m.map(_ChatItemDb.fromDb)) e.value.id: e},
          )
          .changes();
    });
  }

  /// Returns the [Stream] of the last [DtoChatItem] added to a historical view
  /// order of the provided [chatId].
  Stream<DtoChatItem?> watchSingle(ChatItemId id) {
    return stream((db) {
      final stmt = db.select(db.chatItems);
      stmt.where((u) => u.id.equals(id.val));

      return stmt
          .watchSingleOrNull()
          .map((e) => e == null ? null : _ChatItemDb.fromDb(e));
    });
  }
}

/// Extension adding conversion methods from [ChatItemRow] to [DtoChatItem].
extension _ChatItemDb on DtoChatItem {
  /// Returns the [DtoChatItem] from the provided [ChatItemRow].
  static DtoChatItem fromDb(ChatItemRow e) {
    return DtoChatItem.fromJson(jsonDecode(e.data));
  }

  /// Constructs a [ChatItemRow] from this [DtoChatItem].
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

  /// Constructs a [ChatItemViewRow] from this [DtoChatItem].
  ChatItemViewRow toView() {
    return ChatItemViewRow(chatItemId: value.id.val, chatId: value.chatId.val);
  }
}
