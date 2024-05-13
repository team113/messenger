import 'dart:convert';

import 'package:drift/drift.dart';

import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/store/model/my_user.dart';
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
  TextColumn get avatar => text().nullable()(); // JSON
  TextColumn get callCover => text().nullable()(); // JSON
  IntColumn get mutualContactsCount =>
      integer().withDefault(const Constant(0))();
  BoolColumn get online => boolean().withDefault(const Constant(false))();
  IntColumn get presenceIndex => integer().nullable()();
  TextColumn get status => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get dialog => text().nullable()();
  TextColumn get isBlocked => text().nullable()(); // JSON
  IntColumn get lastSeenAt =>
      integer().nullable().map(const PreciseDateTimeConverter())();
  TextColumn get contacts =>
      text().withDefault(const Constant('[]'))(); // Array of JSONs
  TextColumn get ver => text()();
  TextColumn get blockedVer => text()();
}

/// [DriftProviderBase] for manipulating the [User]s stored.
class UserDriftProvider extends DriftProviderBase {
  UserDriftProvider(super.database);

  Future<DriftUser> create(DriftUser user) async {
    return UserDb.fromDb(await db.into(db.users).insertReturning(user.toDb()));
  }

  Future<DriftUser?> read(UserId id) async {
    final dto = await (db.select(db.users)..where((u) => u.id.equals(id.val)))
        .getSingleOrNull();

    if (dto == null) {
      return null;
    }

    return UserDb.fromDb(dto);
  }

  Future<void> update(DriftUser user) async {
    final stmt = db.update(db.users);
    await stmt.replace(user.toDb());
  }

  Future<void> delete(UserId id) async {
    final stmt = db.delete(db.users);
    stmt.where((e) => e.id.equals(id.val));
    await stmt.go();
  }

  Future<void> clear() async => await db.delete(db.users).go();

  Future<DriftUser> upsert(DriftUser user) async {
    return UserDb.fromDb(
      await db
          .into(db.users)
          .insertReturning(user.toDb(), mode: InsertMode.replace),
    );
  }

  Stream<DriftUser?> watch(UserId id) {
    final stmt = db.select(db.users)..where((u) => u.id.equals(id.val));

    return stmt.watch().map((e) {
      if (e.isEmpty) {
        return null;
      }

      return UserDb.fromDb(e.first);
    });
  }
}

/// Persisted in [Users] storage [User]'s [value].
class DriftUser {
  DriftUser(this.value, this.ver, this.blockedVer);

  /// Persisted [User] model.
  User value;

  /// Version of this [User]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  UserVersion ver;

  /// Version of the authenticated [MyUser]'s blocklist state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  MyUserVersion blockedVer;

  @override
  String toString() => '$runtimeType($value, $ver, $blockedVer)';
}

extension UserDb on DriftUser {
  static DriftUser fromDb(UserRow e) {
    return DriftUser(
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
      ),
      UserVersion(e.ver),
      MyUserVersion(e.blockedVer),
    );
  }

  UserRow toDb() {
    return UserRow(
      id: value.id.val,
      num: value.num.val,
      name: value.name?.val,
      bio: value.bio?.val,
      avatar: value.avatar == null ? null : jsonEncode(value.avatar?.toJson()),
      callCover:
          value.avatar == null ? null : jsonEncode(value.callCover?.toJson()),
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
    );
  }
}
