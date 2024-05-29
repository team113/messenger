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

import '/domain/model/avatar.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/store/model/my_user.dart';
import '/util/obs/obs.dart';
import 'common.dart';
import 'drift.dart';

/// [MyUser] to be stored in a [Table].
@DataClassName('MyUserRow')
class MyUsers extends Table {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();
  TextColumn get num => text().unique()();
  TextColumn get login => text().nullable()();
  TextColumn get name => text().nullable()();
  TextColumn get bio => text().nullable()();
  BoolColumn get hasPassword => boolean().withDefault(const Constant(false))();
  TextColumn get emails => text()();
  TextColumn get phones => text()();
  TextColumn get chatDirectLink => text().nullable()();
  IntColumn get unreadChatsCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().nullable()();
  TextColumn get avatar => text().nullable()();
  TextColumn get callCover => text().nullable()();
  IntColumn get presenceIndex => integer().withDefault(const Constant(0))();
  BoolColumn get online => boolean().withDefault(const Constant(false))();
  TextColumn get muted => text().nullable()();
  IntColumn get blocklistCount => integer().nullable()();
  IntColumn get lastSeenAt =>
      integer().nullable().map(const PreciseDateTimeConverter())();
  TextColumn get ver => text()();
}

/// [DriftProviderBase] for manipulating the persisted [User]s.
class MyUserDriftProvider extends DriftProviderBase {
  MyUserDriftProvider(super.database);

  /// [StreamController] emitting [DtoMyUser]s in [watch].
  final Map<UserId, StreamController<DtoMyUser?>> _controllers = {};

  /// [DtoMyUser]s that have started the [upsert]ing, but not yet finished it.
  final Map<UserId, DtoMyUser> _cache = {};

  /// Creates or updates the provided [user] in the database.
  Future<DtoMyUser> upsert(DtoMyUser user) async {
    _cache[user.id] = user;

    final result = await safe((db) async {
      final DtoMyUser stored = _MyUserDb.fromDb(
        await db
            .into(db.myUsers)
            .insertReturning(user.toDb(), mode: InsertMode.insertOrReplace),
      );

      _controllers[stored.id]?.add(stored);

      return stored;
    });

    return result ?? user;
  }

  /// Returns the [DtoMyUser] stored in the database by the provided [id], if
  /// any.
  Future<DtoMyUser?> read(UserId id) async {
    final DtoMyUser? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<DtoMyUser?>((db) async {
      final stmt = db.select(db.myUsers)..where((u) => u.id.equals(id.val));
      final MyUserRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _MyUserDb.fromDb(row);
    });
  }

  /// Deletes the [DtoMyUser] identified by the provided [id] from the database.
  Future<void> delete(UserId id) async {
    _cache.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.myUsers)..where((e) => e.id.equals(id.val));
      await stmt.go();

      _controllers[id]?.add(null);
    });
  }

  /// Deletes all the [DtoMyUser]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.myUsers).go();
    });
  }

  /// Returns all the [DtoMyUser]s.
  Future<List<DtoMyUser>> accounts({int? limit}) async {
    if (db == null) {
      return [];
    }

    final stmt = db!.select(db!.myUsers);
    stmt.orderBy([(u) => OrderingTerm.desc(db!.myUsers.lastSeenAt)]);

    if (limit != null) {
      stmt.limit(limit);
    }

    return (await stmt.get()).map((row) => _MyUserDb.fromDb(row)).toList();
  }

  /// Returns the [Stream] of real-time changes happening with the [DtoMyUser]s.
  Stream<List<MapChangeNotification<UserId, DtoMyUser>>> watch() {
    if (db == null) {
      return const Stream.empty();
    }

    return db!
        .select(db!.myUsers)
        .watch()
        .map((items) => {for (var e in items.map(_MyUserDb.fromDb)) e.id: e})
        .changes();
  }

  /// Returns the [Stream] of real-time changes happening with the [DtoMyUser]
  /// identified by the provided [id].
  Stream<DtoMyUser?> watchSingle(UserId id) {
    if (db == null) {
      return const Stream.empty();
    }

    final stmt = db!.select(db!.myUsers)..where((u) => u.id.equals(id.val));

    StreamController<DtoMyUser?>? controller = _controllers[id];
    if (controller == null) {
      controller = StreamController<DtoMyUser?>.broadcast(sync: true);
      _controllers[id] = controller;
    }

    return StreamGroup.merge(
      [
        controller.stream,
        stmt.watch().map((e) => e.isEmpty ? null : _MyUserDb.fromDb(e.first)),
      ],
    );
  }
}

/// Extension adding conversion methods from [UserRow] to [DtoMyUser].
extension _MyUserDb on DtoMyUser {
  /// Constructs a [DtoMyUser] from the provided [UserRow].
  static DtoMyUser fromDb(MyUserRow e) {
    return DtoMyUser(
      MyUser(
        id: UserId(e.id),
        num: UserNum(e.num),
        login: e.login == null ? null : UserLogin(e.login!),
        name: e.name == null ? null : UserName(e.name!),
        bio: e.bio == null ? null : UserBio(e.bio!),
        hasPassword: e.hasPassword,
        emails: MyUserEmails.fromJson(jsonDecode(e.emails)),
        phones: MyUserPhones.fromJson(jsonDecode(e.phones)),
        chatDirectLink: e.chatDirectLink == null
            ? null
            : ChatDirectLink.fromJson(jsonDecode(e.chatDirectLink!)),
        unreadChatsCount: e.unreadChatsCount,
        status: e.status == null ? null : UserTextStatus(e.status!),
        avatar: e.avatar == null
            ? null
            : UserAvatar.fromJson(jsonDecode(e.avatar!)),
        callCover: e.callCover == null
            ? null
            : UserCallCover.fromJson(jsonDecode(e.callCover!)),
        presenceIndex: e.presenceIndex,
        online: e.online,
        muted: e.muted == null
            ? null
            : MuteDuration.fromJson(jsonDecode(e.muted!)),
        blocklistCount: e.blocklistCount,
        lastSeenAt: e.lastSeenAt,
      ),
      MyUserVersion(e.ver),
    );
  }

  /// Constructs a [MyUserRow] from this [DtoMyUser].
  MyUserRow toDb() {
    return MyUserRow(
      id: value.id.val,
      num: value.num.val,
      login: value.login?.val,
      name: value.name?.val,
      bio: value.bio?.val,
      hasPassword: value.hasPassword,
      emails: jsonEncode(value.emails.toJson()),
      phones: jsonEncode(value.phones.toJson()),
      chatDirectLink: value.chatDirectLink == null
          ? null
          : jsonEncode(value.chatDirectLink?.toJson()),
      unreadChatsCount: value.unreadChatsCount,
      status: value.status == null ? null : jsonEncode(value.status?.toJson()),
      avatar: value.avatar == null ? null : jsonEncode(value.avatar?.toJson()),
      callCover: value.callCover == null
          ? null
          : jsonEncode(value.callCover?.toJson()),
      presenceIndex: value.presenceIndex,
      online: value.online,
      muted: value.muted == null ? null : jsonEncode(value.muted?.toJson()),
      blocklistCount: value.blocklistCount,
      lastSeenAt: value.lastSeenAt,
      ver: ver.val,
    );
  }
}
