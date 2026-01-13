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

import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/domain/model/welcome_message.dart';
import '/domain/service/disposable_service.dart';
import '/store/model/blocklist.dart';
import '/store/model/user.dart';
import 'common.dart';
import 'drift.dart';

/// [User] to be stored in a [Table].
@DataClassName('UserRow')
class Users extends Table {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();
  TextColumn get num => text().unique()();
  TextColumn get name => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get avatar => text().nullable()();
  TextColumn get callCover => text().nullable()();
  IntColumn get mutualContactsCount =>
      integer().withDefault(const Constant(0))();
  BoolColumn get online => boolean().withDefault(const Constant(false))();
  IntColumn get presenceIndex => integer().nullable()();
  TextColumn get status => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get dialog => text().nullable()();
  TextColumn get isBlocked => text().nullable()();
  IntColumn get lastSeenAt =>
      integer().nullable().map(const PreciseDateTimeConverter())();
  TextColumn get contacts => text().withDefault(const Constant('[]'))();
  TextColumn get ver => text()();
  TextColumn get blockedVer => text()();
  TextColumn get welcomeMessage => text().nullable()();
}

/// [DriftProviderBase] for manipulating the persisted [User]s.
class UserDriftProvider extends DriftProviderBaseWithScope with IdentityAware {
  UserDriftProvider(super.common, super.scoped);

  @override
  int get order => IdentityAware.providerOrder;

  /// [StreamController] emitting [DtoUser]s in [watch].
  final Map<UserId, StreamController<DtoUser?>> _controllers = {};

  /// [DtoUser]s that have started the [upsert]ing, but not yet finished it.
  final Map<UserId, DtoUser> _cache = {};

  @override
  void onIdentityChanged(UserId me) {
    _cache.clear();
  }

  /// Creates or updates the provided [user] in the database.
  Future<DtoUser> upsert(DtoUser user) async {
    _cache[user.id] = user;

    final result = await safe((db) async {
      final DtoUser stored = UserDb.fromDb(
        await db
            .into(db.users)
            .insertReturning(user.toDb(), mode: InsertMode.insertOrReplace),
      );

      _controllers[stored.id]?.add(stored);

      return stored;
    }, tag: 'user.upsert(user)');

    _cache.remove(user.id);

    return result ?? user;
  }

  /// Returns the [DtoUser] stored in the database by the provided [id], if
  /// any.
  Future<DtoUser?> read(UserId id) async {
    final DtoUser? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<DtoUser?>(
      (db) async {
        final stmt = db.select(db.users)..where((u) => u.id.equals(id.val));
        final UserRow? row = await stmt.getSingleOrNull();

        if (row == null) {
          return null;
        }

        return UserDb.fromDb(row);
      },
      tag: 'user.read($id)',
      exclusive: false,
    );
  }

  /// Deletes the [DtoUser] identified by the provided [id] from the database.
  Future<void> delete(UserId id) async {
    _cache.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.users)..where((e) => e.id.equals(id.val));
      await stmt.go();

      _controllers[id]?.add(null);
    }, tag: 'user.delete($id)');
  }

  /// Deletes all the [DtoUser]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.users).go();
    }, tag: 'user.clear()');
  }

  /// Returns the [Stream] of real-time changes happening with the [DtoUser]
  /// identified by the provided [id].
  Stream<DtoUser?> watch(UserId id) {
    return stream((db) {
      final stmt = db.select(db.users)..where((u) => u.id.equals(id.val));

      StreamController<DtoUser?>? controller = _controllers[id];
      if (controller == null) {
        controller = StreamController<DtoUser?>.broadcast(sync: true);
        _controllers[id] = controller;
      }

      return StreamGroup.merge([
        controller.stream,
        stmt.watch().map((e) => e.isEmpty ? null : UserDb.fromDb(e.first)),
      ]);
    });
  }
}

/// Extension adding conversion methods from [UserRow] to [DtoUser].
extension UserDb on DtoUser {
  /// Constructs a [DtoUser] from the provided [UserRow].
  static DtoUser fromDb(UserRow e) {
    return DtoUser(
      User(
        UserId(e.id),
        UserNum(e.num),
        name: e.name == null ? null : UserName(e.name!),
        bio: e.bio == null ? null : UserBio(e.bio!),
        avatar: e.avatar == null
            ? null
            : UserAvatar.fromJson(jsonDecode(e.avatar!)),
        callCover: e.callCover == null
            ? null
            : UserCallCover.fromJson(jsonDecode(e.callCover!)),
        mutualContactsCount: e.mutualContactsCount,
        online: e.online,
        presenceIndex: e.presenceIndex,
        status: e.status == null ? null : UserTextStatus(e.status!),
        isDeleted: e.isDeleted,
        dialog: e.dialog == null ? null : ChatId(e.dialog!),
        isBlocked: e.isBlocked == null
            ? null
            : BlocklistRecord.fromJson(jsonDecode(e.isBlocked!)),
        lastSeenAt: e.lastSeenAt,
        contacts: (jsonDecode(e.contacts) as List)
            .map((e) => NestedChatContact.fromJson(e))
            .cast<NestedChatContact>()
            .toList(),
        welcomeMessage: e.welcomeMessage == null
            ? null
            : WelcomeMessage.fromJson(jsonDecode(e.welcomeMessage!)),
      ),
      UserVersion(e.ver),
      BlocklistVersion(e.blockedVer),
    );
  }

  /// Constructs a [UserRow] from this [DtoUser].
  UserRow toDb() {
    return UserRow(
      id: value.id.val,
      num: value.num.val,
      name: value.name?.val,
      bio: value.bio?.val,
      avatar: value.avatar == null ? null : jsonEncode(value.avatar?.toJson()),
      callCover: value.callCover == null
          ? null
          : jsonEncode(value.callCover?.toJson()),
      mutualContactsCount: value.mutualContactsCount,
      online: value.online,
      presenceIndex: value.presenceIndex,
      status: value.status?.val,
      isDeleted: value.isDeleted,
      dialog: value.dialog.val,
      isBlocked: value.isBlocked == null
          ? null
          : jsonEncode(value.isBlocked?.toJson()),
      lastSeenAt: value.lastSeenAt,
      contacts: jsonEncode(value.contacts.map((e) => e.toJson()).toList()),
      ver: ver.val,
      blockedVer: blockedVer.val,
      welcomeMessage: value.welcomeMessage == null
          ? null
          : jsonEncode(value.welcomeMessage?.toJson()),
    );
  }
}
