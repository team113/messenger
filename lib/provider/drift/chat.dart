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

import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:log_me/log_me.dart';

import '/domain/model/avatar.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/store/model/chat_item.dart';
import '/store/model/chat.dart';
import 'common.dart';
import 'drift.dart';

/// [Chat] to be stored in a [Table].
@DataClassName('ChatRow')
class Chats extends Table {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();
  TextColumn get avatar => text().nullable()();
  TextColumn get name => text().nullable()();
  TextColumn get members => text().withDefault(const Constant('[]'))();
  IntColumn get kindIndex => integer().withDefault(const Constant(0))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get muted => text().nullable()();
  TextColumn get directLink => text().nullable()();
  IntColumn get createdAt => integer()
      .map(const PreciseDateTimeConverter())
      .clientDefault(
        () => const PreciseDateTimeConverter().toSql(PreciseDateTime.now()),
      )();
  IntColumn get updatedAt => integer()
      .map(const PreciseDateTimeConverter())
      .clientDefault(
        () => const PreciseDateTimeConverter().toSql(PreciseDateTime.now()),
      )();
  TextColumn get lastReads => text().withDefault(const Constant('[]'))();
  IntColumn get lastDelivery =>
      integer().map(const PreciseDateTimeConverter()).nullable()();
  TextColumn get firstItem => text().nullable()();
  TextColumn get lastItem => text().nullable()();
  TextColumn get lastReadItem => text().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  IntColumn get totalCount => integer().withDefault(const Constant(0))();
  TextColumn get ongoingCall => text().nullable()();
  RealColumn get favoritePosition => real().nullable()();
  IntColumn get membersCount => integer().withDefault(const Constant(0))();
  TextColumn get ver => text()();
  TextColumn get lastItemCursor => text().nullable()();
  TextColumn get lastReadItemCursor => text().nullable()();
  TextColumn get recentCursor => text().nullable()();
  TextColumn get favoriteCursor => text().nullable()();
}

/// [DriftProviderBase] for manipulating the persisted [Chat]s.
class ChatDriftProvider extends DriftProviderBaseWithScope {
  ChatDriftProvider(super.common, super.scoped);

  /// [StreamController] emitting [DtoChat]s in [watch].
  final Map<ChatId, StreamController<DtoChat?>> _controllers = {};

  /// [DtoChatItem]s that have started the [upsert]ing, but not yet finished it.
  final Map<ChatId, DtoChat> _cache = {};

  /// Creates or updates the provided [chat] in the database.
  Future<DtoChat> upsert(DtoChat chat, {bool force = false}) async {
    Log.debug('upsert($chat)');

    _cache[chat.id] = chat;
    _controllers[chat.id]?.add(chat);

    final result = await safe(
      (db) async {
        final ChatRow row = chat.toDb();
        final DtoChat stored = _ChatDb.fromDb(
          await db
              .into(db.chats)
              .insertReturning(row, mode: InsertMode.insertOrReplace),
        );

        return stored;
      },
      tag: 'chat.upsert()',
      force: force,
    );

    _cache.remove(chat.id);

    return result ?? chat;
  }

  /// Creates or updates the provided [items] in the database.
  Future<Iterable<DtoChat>> upsertBulk(Iterable<DtoChat> items) async {
    for (var e in items) {
      _cache[e.id] = e;
    }

    for (var e in items) {
      _controllers[e.id]?.add(e);
    }

    final result = await safe((db) async {
      Log.debug('upsertBulk(${items.length} items)');

      await db.batch((batch) {
        for (var item in items) {
          final ChatRow row = item.toDb();
          batch.insert(db.chats, row, mode: InsertMode.insertOrReplace);
        }
      });

      return items.toList();
    }, tag: 'chat.upsertBulk(${items.length} items)');

    for (var e in items) {
      _cache.remove(e.value.id);
    }

    return result ?? items;
  }

  /// Returns the [DtoChat] stored in the database by the provided [id], if any.
  Future<DtoChat?> read(ChatId id, {bool force = false}) async {
    final DtoChat? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<DtoChat?>(
      (db) async {
        final stmt = db.select(db.chats)..where((u) => u.id.equals(id.val));

        final ChatRow? row = await stmt.getSingleOrNull();

        if (row == null) {
          return null;
        }

        return _ChatDb.fromDb(row);
      },
      tag: 'chat.read($id)',
      exclusive: false,
      force: force,
    );
  }

  /// Deletes the [DtoChat] identified by the provided [id] from the database.
  Future<void> delete(ChatId id) async {
    _cache.remove(id);
    _controllers[id]?.add(null);

    await safe((db) async {
      final stmt = db.delete(db.chats)..where((e) => e.id.equals(id.val));
      await stmt.go();
    }, tag: 'delete($id)');
  }

  /// Deletes all the [DtoChat]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.chats).go();
    }, tag: 'chat.clear()');
  }

  /// Returns the recent [DtoChat]s being in a historical view order.
  Future<List<DtoChat>> recent({int? limit}) async {
    final result = await safe(
      (db) async {
        final stmt = db.select(db.chats);

        stmt.where(
          (u) =>
              u.isHidden.equals(false) &
              u.isArchived.equals(false) &
              u.id.like('local__%', escapeChar: '_').not() &
              u.id.like('d__%', escapeChar: '_').not(),
        );
        stmt.orderBy([(u) => OrderingTerm.desc(u.updatedAt)]);

        if (limit != null) {
          stmt.limit(limit);
        }

        return (await stmt.get()).map(_ChatDb.fromDb).toList();
      },
      tag: 'chat.recent(limit: $limit)',
      exclusive: false,
    );

    return result ?? [];
  }

  /// Returns the archived [DtoChat]s being in a historical view order.
  Future<List<DtoChat>> archive({int? limit}) async {
    final result = await safe(
      (db) async {
        final stmt = db.select(db.chats);

        stmt.where(
          (u) =>
              u.isHidden.equals(false) &
              u.isArchived.equals(true) &
              u.id.like('local__%', escapeChar: '_').not() &
              u.id.like('d__%', escapeChar: '_').not(),
        );
        stmt.orderBy([(u) => OrderingTerm.desc(u.updatedAt)]);

        if (limit != null) {
          stmt.limit(limit);
        }

        return (await stmt.get()).map(_ChatDb.fromDb).toList();
      },
      tag: 'chat.archive(limit: $limit)',
      exclusive: false,
    );

    return result ?? [];
  }

  /// Returns the favorite [DtoChat]s being in a historical view order.
  Future<List<DtoChat>> favorite({int? limit}) async {
    final result = await safe(
      (db) async {
        final stmt = db.select(db.chats);

        stmt.where(
          (u) =>
              u.isHidden.equals(false) &
              u.isArchived.equals(false) &
              u.favoritePosition.isNotNull() &
              u.id.like('local__%', escapeChar: '_').not() &
              u.id.like('d__%', escapeChar: '_').not(),
        );
        stmt.orderBy([(u) => OrderingTerm.desc(u.favoritePosition)]);

        if (limit != null) {
          stmt.limit(limit);
        }

        return (await stmt.get()).map(_ChatDb.fromDb).toList();
      },
      tag: 'chat.favorite(limit: $limit)',
      exclusive: false,
    );

    return result ?? [];
  }

  /// Returns the [Stream] of real-time changes happening with the [DtoChat]
  /// identified by the provided [id].
  Stream<DtoChat?> watch(ChatId id) {
    return stream((db) {
      final stmt = db.select(db.chats)..where((u) => u.id.equals(id.val));

      StreamController<DtoChat?>? controller = _controllers[id];
      if (controller == null) {
        controller = StreamController<DtoChat?>.broadcast(sync: true);
        _controllers[id] = controller;
      }

      DtoChat? last;

      return StreamGroup.merge([
        controller.stream,
        stmt.watch().map((e) => e.isEmpty ? null : _ChatDb.fromDb(e.first)),
      ]).asyncExpand((e) async* {
        if (e != last) {
          last = e;
          yield e;
        }
      });
    });
  }

  /// Returns the [Stream] of recent [DtoChat]s being in a historical order.
  Stream<List<DtoChat>> watchRecent({int? limit}) {
    return stream((db) {
      final stmt = db.select(db.chats);

      stmt.where(
        (u) =>
            u.isHidden.equals(false) &
            u.isArchived.equals(false) &
            u.id.like('local__%', escapeChar: '_').not() &
            u.id.like('d__%', escapeChar: '_').not() &
            u.favoritePosition.isNull(),
      );
      stmt.orderBy([(u) => OrderingTerm.desc(u.updatedAt)]);

      if (limit != null) {
        stmt.limit(limit);
      }

      return stmt.watch().map((rows) => rows.map(_ChatDb.fromDb).toList());
    });
  }

  /// Returns the [Stream] of archived [DtoChat]s being in a historical order.
  Stream<List<DtoChat>> watchArchive({int? limit}) {
    return stream((db) {
      final stmt = db.select(db.chats);

      stmt.where(
        (u) =>
            u.isHidden.equals(false) &
            u.isArchived.equals(true) &
            u.id.like('local__%', escapeChar: '_').not() &
            u.id.like('d__%', escapeChar: '_').not(),
      );
      stmt.orderBy([(u) => OrderingTerm.desc(u.updatedAt)]);

      if (limit != null) {
        stmt.limit(limit);
      }

      return stmt.watch().map((rows) {
        return rows.map(_ChatDb.fromDb).toList();
      });
    });
  }

  /// Returns the [Stream] of favorite [DtoChat]s being in a historical order.
  Stream<List<DtoChat>> watchFavorite({int? limit}) {
    return stream((db) {
      final stmt = db.select(db.chats);

      stmt.where(
        (u) =>
            u.isHidden.equals(false) &
            u.isArchived.equals(false) &
            u.id.like('local__%', escapeChar: '_').not() &
            u.id.like('d__%', escapeChar: '_').not() &
            u.favoritePosition.isNotNull(),
      );
      stmt.orderBy([(u) => OrderingTerm.desc(u.favoritePosition)]);

      if (limit != null) {
        stmt.limit(limit);
      }

      return stmt.watch().map((rows) => rows.map(_ChatDb.fromDb).toList());
    });
  }
}

/// Extension adding conversion methods from [ChatRow] to [DtoChat].
extension _ChatDb on DtoChat {
  /// Returns the [DtoChatItem] from the provided [ChatRow].
  static DtoChat fromDb(ChatRow e) {
    return DtoChat(
      Chat(
        ChatId(e.id),
        avatar: e.avatar == null
            ? null
            : ChatAvatar.fromJson(jsonDecode(e.avatar!)),
        name: e.name == null ? null : ChatName(e.name!),
        members: (jsonDecode(e.members) as List)
            .map((e) => ChatMember.fromJson(e))
            .cast<ChatMember>()
            .toList(),
        kindIndex: e.kindIndex,
        isHidden: e.isHidden,
        isArchived: e.isArchived,
        muted: e.muted == null
            ? null
            : MuteDuration.fromJson(jsonDecode(e.muted!)),
        directLink: e.directLink == null
            ? null
            : ChatDirectLink.fromJson(jsonDecode(e.directLink!)),
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        lastReads: (jsonDecode(e.lastReads) as List)
            .map((e) => LastChatRead.fromJson(e))
            .cast<LastChatRead>()
            .toList(),
        lastDelivery: e.lastDelivery,
        firstItem: e.firstItem == null
            ? null
            : ChatItem.fromJson(jsonDecode(e.firstItem!)),
        lastItem: e.lastItem == null
            ? null
            : ChatItem.fromJson(jsonDecode(e.lastItem!)),
        lastReadItem: e.lastReadItem == null
            ? null
            : ChatItemId(e.lastReadItem!),
        unreadCount: e.unreadCount,
        totalCount: e.totalCount,
        ongoingCall: e.ongoingCall == null
            ? null
            : ChatCall.fromJson(jsonDecode(e.ongoingCall!)),
        favoritePosition: e.favoritePosition == null
            ? null
            : ChatFavoritePosition(e.favoritePosition!),
        membersCount: e.membersCount,
      ),
      ChatVersion(e.ver),
      e.lastItemCursor == null ? null : ChatItemsCursor(e.lastItemCursor!),
      e.lastReadItemCursor == null
          ? null
          : ChatItemsCursor(e.lastReadItemCursor!),
      e.recentCursor == null ? null : RecentChatsCursor(e.recentCursor!),
      e.favoriteCursor == null ? null : FavoriteChatsCursor(e.favoriteCursor!),
    );
  }

  /// Constructs a [ChatRow] from this [DtoChat].
  ChatRow toDb() {
    return ChatRow(
      id: value.id.val,
      avatar: value.avatar == null ? null : jsonEncode(value.avatar?.toJson()),
      name: value.name?.val,
      members: jsonEncode(
        value.members.take(3).map((e) => e.toJson()).toList(),
      ),
      kindIndex: value.kindIndex,
      isHidden: value.isHidden,
      isArchived: value.isArchived,
      muted: value.muted == null ? null : jsonEncode(value.muted?.toJson()),
      directLink: value.directLink == null
          ? null
          : jsonEncode(value.directLink?.toJson()),
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
      lastReads: jsonEncode(value.lastReads.map((e) => e.toJson()).toList()),
      lastDelivery: value.lastDelivery,
      firstItem: value.firstItem == null
          ? null
          : jsonEncode(value.firstItem?.toJson()),
      lastItem: value.lastItem == null
          ? null
          : jsonEncode(value.lastItem?.toJson()),
      lastReadItem: value.lastReadItem?.val,
      unreadCount: value.unreadCount,
      totalCount: value.totalCount,
      ongoingCall: value.ongoingCall == null
          ? null
          : jsonEncode(value.ongoingCall?.toJson()),
      favoritePosition: value.favoritePosition?.val,
      membersCount: value.membersCount,
      ver: ver.val,
      lastItemCursor: lastItemCursor?.val,
      lastReadItemCursor: lastReadItemCursor?.val,
      recentCursor: recentCursor?.val,
      favoriteCursor: favoriteCursor?.val,
    );
  }
}
