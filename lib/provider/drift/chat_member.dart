// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:drift/drift.dart';
import 'package:log_me/log_me.dart';

import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/store/model/chat_item.dart';
import '/store/model/chat_member.dart';
import '/store/model/chat.dart';
import 'common.dart';
import 'drift.dart';
import 'user.dart';

/// [ChatMember] to be stored in a [Table].
@DataClassName('ChatMemberRow')
class ChatMembers extends Table {
  @override
  Set<Column> get primaryKey => {userId, chatId};

  TextColumn get userId => text()();
  TextColumn get chatId => text()();
  IntColumn get joinedAt => integer().map(const PreciseDateTimeConverter())();
  TextColumn get cursor => text().nullable()();
}

/// [DriftProviderBase] for manipulating the persisted [DtoChatMember]s.
class ChatMemberDriftProvider extends DriftProviderBaseWithScope {
  ChatMemberDriftProvider(super.common, super.scoped);

  /// Creates or updates the provided [members] in the database.
  Future<Iterable<DtoChatMember>> upsertBulk(
    ChatId chatId,
    Iterable<DtoChatMember> members,
  ) async {
    Log.debug('upsertBulk($chatId, $members)');

    await safe((db) async {
      for (var member in members) {
        final ChatMemberRow row = member.toDb(chatId);
        db.into(db.chatMembers).insert(row, onConflict: DoUpdate((_) => row));
      }
    }, tag: 'chat_member.upsertBulk($chatId, ${members.length} items)');

    return members;
  }

  /// Returns the [DtoChatMember] stored in the database by the provided
  /// [chatId] and [userId], if any.
  Future<DtoChatMember?> read(ChatId chatId, UserId userId) async {
    return await safe<DtoChatMember?>(
      (db) async {
        final stmt = db.select(db.chatMembers).join([
          innerJoin(db.users, db.users.id.equalsExp(db.chatMembers.userId)),
        ]);

        stmt.where(
          db.chatMembers.chatId.equals(chatId.val) &
              db.chatMembers.userId.equals(userId.val),
        );

        final row = await stmt.getSingleOrNull();

        if (row == null) {
          return null;
        }

        return _ChatMemberDb.fromDb(
          row.readTable(db.chatMembers),
          row.readTable(db.users),
        );
      },
      tag: 'chat_member.read($chatId, $userId)',
      exclusive: false,
    );
  }

  /// Deletes the [DtoChatItem] identified by the provided [chatId] and [userId]
  /// from the database.
  Future<void> delete(ChatId chatId, UserId userId) async {
    await safe((db) async {
      final stmt = db.delete(db.chatMembers);
      stmt.where(
        (u) => u.chatId.equals(chatId.val) & u.userId.equals(userId.val),
      );
      await stmt.goAndReturn();
    }, tag: 'chat_member.delete($chatId, $userId)');
  }

  /// Deletes all the [DtoChatItem]s stored in the database.
  Future<void> clear() async {
    await safe((db) async {
      await db.delete(db.chatMembers).go();
    }, tag: 'chat_member.clear()');
  }

  /// Returns the [DtoChatMember]s of the provided [chatId].
  Future<List<DtoChatMember>> members(ChatId chatId, {int? limit}) async {
    final result = await safe(
      (db) async {
        final stmt = db.select(db.chatMembers).join([
          innerJoin(db.users, db.users.id.equalsExp(db.chatMembers.userId)),
        ]);

        stmt.where(db.chatMembers.chatId.equals(chatId.val));
        stmt.orderBy([OrderingTerm.desc(db.chatMembers.joinedAt)]);

        if (limit != null) {
          stmt.limit(limit);
        }

        return (await stmt.get())
            .map(
              (rows) => _ChatMemberDb.fromDb(
                rows.readTable(db.chatMembers),
                rows.readTableOrNull(db.users),
              ),
            )
            .toList();
      },
      tag: 'chat_member.members($chatId, limit: $limit)',
      exclusive: false,
    );

    return result ?? [];
  }
}

/// Extension adding conversion methods from [ChatMemberRow] to [DtoChatMember].
extension _ChatMemberDb on DtoChatMember {
  /// Returns the [DtoChatMember] from the provided [ChatMemberRow].
  static DtoChatMember fromDb(ChatMemberRow m, UserRow? u) {
    return DtoChatMember(
      u == null ? null : UserDb.fromDb(u).value,
      m.joinedAt,
      m.cursor == null ? null : ChatMembersCursor(m.cursor!),
      userId: UserId(m.userId),
    );
  }

  /// Constructs a [ChatMemberRow] from this [DtoChatMember].
  ChatMemberRow toDb(ChatId chatId) {
    return ChatMemberRow(
      userId: id.val,
      chatId: chatId.val,
      joinedAt: joinedAt,
      cursor: cursor?.val,
    );
  }
}
