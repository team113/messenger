// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
    Log.debug('upsertView($chatId, $chatItemId)', '$runtimeType');

    await safe((db) async {
      final view = ChatItemViewRow(
        chatId: chatId.val,
        chatItemId: chatItemId.val,
      );
      await db
          .into(db.chatItemViews)
          .insert(view, onConflict: DoUpdate((_) => view));
    }, tag: 'chat_item.upsertView($chatId, $chatItemId)');
  }

  /// Creates or updates the provided [item] in the database.
  ///
  /// If [toView] is `true`, then also adds a view to the [ChatItemViews].
  Future<DtoChatItem> upsert(DtoChatItem item, {bool toView = false}) async {
    Log.debug('upsert($item) toView($toView)', '$runtimeType');

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
    }, tag: 'chat_item.upsert(item, toView: $toView)');

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
      Log.debug(
        'upsertBulk(${items.length} items) toView($toView)',
        '$runtimeType',
      );

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
    }, tag: 'chat_item.upsertBulk(${items.length} items, toView: $toView)');

    return result ?? items;
  }

  /// Returns the [DtoChatItem] stored in the database by the provided [id], if
  /// any.
  FutureOr<DtoChatItem?> read(ChatItemId id) {
    final DtoChatItem? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return safe<DtoChatItem?>(
      (db) async {
        final stmt = db.select(db.chatItems)..where((u) => u.id.equals(id.val));
        final ChatItemRow? row = await stmt.getSingleOrNull();

        if (row == null) {
          return null;
        }

        return _ChatItemDb.fromDb(row);
      },
      tag: 'chat_item.read($id)',
      exclusive: false,
    );
  }

  /// Returns the [DtoChatItem] stored in the database by the provided [at], if
  /// any.
  Future<DtoChatItem?> readAt(PreciseDateTime at) {
    return safe<DtoChatItem?>(
      (db) async {
        final stmt = db.select(db.chatItems)
          ..where(
            (u) => u.at.isSmallerOrEqual(Variable(at.microsecondsSinceEpoch)),
          )
          ..orderBy([(u) => OrderingTerm.desc(u.at)])
          ..limit(1);
        final ChatItemRow? row = await stmt.getSingleOrNull();

        if (row == null) {
          return null;
        }

        return _ChatItemDb.fromDb(row);
      },
      tag: 'chat_item.readAt($at)',
      exclusive: false,
    );
  }

  /// Deletes the [DtoChatItem] identified by the provided [id] from the
  /// database.
  Future<void> delete(ChatItemId id) async {
    _cache.remove(id);

    await safe((db) async {
      final deleteItems = db.delete(db.chatItems);
      deleteItems.where((e) => e.id.equals(id.val));
      await deleteItems.goAndReturn();

      final deleteViews = db.delete(db.chatItemViews);
      deleteViews.where((e) => e.chatItemId.equals(id.val));
      await deleteViews.goAndReturn();
    }, tag: 'chat_item.delete($id)');
  }

  /// Deletes all the [DtoChatItem]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.chatItems).go();
      await db.delete(db.chatItemViews).go();
    }, tag: 'chat_item.clear()');
  }

  /// Returns the [DtoChatItem]s being in a historical view order of the
  /// provided [chatId].
  Future<List<DtoChatItem>> view(
    ChatId chatId, {
    int? before,
    int? after,
    PreciseDateTime? around,
    ChatMessageText? withText,
  }) async {
    final result = await safe(
      (db) async {
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
        if (withText != null) {
          stmt.where(db.chatItems.data.like('%"text":"%$withText%"%'));
        }

        stmt.orderBy([OrderingTerm.desc(db.chatItems.at)]);

        if (after != null || before != null) {
          stmt.limit((after ?? 0) + (before ?? 0));
        }

        return (await stmt.get())
            .map((rows) => rows.readTable(db.chatItems))
            .map(_ChatItemDb.fromDb)
            .toList();
      },
      tag: 'chat_item.view($chatId, $before, $after, $around)',
      exclusive: false,
    );

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
    final result = await safe(
      (db) async {
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
      },
      tag: 'chat_item.attachments($chatId, $before, $after, $around)',
      exclusive: false,
    );

    return result ?? [];
  }

  /// Returns the [Stream] of [DtoChatItem]s being in a historical view order of
  /// the provided [chatId].
  Stream<List<DtoChatItem>> watch(
    ChatId chatId, {
    int? before,
    int? after,
    PreciseDateTime? around,
  }) {
    return stream((db) {
      if (before == null && after == null) {
        final stmt = db.select(db.chatItemViews).join([
          innerJoin(
            db.chatItems,
            db.chatItems.id.equalsExp(db.chatItemViews.chatItemId),
          ),
        ]);

        stmt.where(db.chatItemViews.chatId.equals(chatId.val));
        stmt.orderBy([OrderingTerm.desc(db.chatItems.at)]);

        return stmt.watch().map(
          (rows) => rows
              .map((e) => _ChatItemDb.fromDb(e.readTable(db.chatItems)))
              .toList(),
        );
      } else if (before != null && after != null) {
        final stmt = db.chatItemsAround(
          chatId.val,
          around ?? PreciseDateTime.now(),
          before.toDouble(),
          after,
        );

        return stmt.watch().map(
          (items) => items
              .map(
                (r) => _ChatItemDb.fromDb(
                  ChatItemRow(
                    id: r.id,
                    chatId: r.chatId,
                    authorId: r.authorId,
                    at: r.at,
                    status: r.status,
                    data: r.data,
                    cursor: r.cursor,
                    ver: r.ver,
                  ),
                ),
              )
              .toList(),
        );
      } else if (before == null && after != null) {
        final stmt = db.chatItemsAroundTopless(
          chatId.val,
          around ?? PreciseDateTime.now(),
          after,
        );

        return stmt.watch().map(
          (items) => items
              .map(
                (r) => _ChatItemDb.fromDb(
                  ChatItemRow(
                    id: r.id,
                    chatId: r.chatId,
                    authorId: r.authorId,
                    at: r.at,
                    status: r.status,
                    data: r.data,
                    cursor: r.cursor,
                    ver: r.ver,
                  ),
                ),
              )
              .toList(),
        );
      } else if (before != null && after == null) {
        final stmt = db.chatItemsAroundBottomless(
          chatId.val,
          around ?? PreciseDateTime.now(),
          before.toDouble(),
        );

        return stmt.watch().map(
          (items) => items
              .map(
                (r) => _ChatItemDb.fromDb(
                  ChatItemRow(
                    id: r.id,
                    chatId: r.chatId,
                    authorId: r.authorId,
                    at: r.at,
                    status: r.status,
                    data: r.data,
                    cursor: r.cursor,
                    ver: r.ver,
                  ),
                ),
              )
              .toList(),
        );
      }

      throw Exception('Unreachable');
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
