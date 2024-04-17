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

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model_type_id.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/file.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/store/model/my_user.dart';
import '/store/model/user.dart';
import '/util/log.dart';
import 'base.dart';

part 'user.g.dart';

/// [Hive] storage for [User]s.
class UserHiveProvider extends HiveBaseProvider<HiveUser> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'user';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');

    Hive.maybeRegisterAdapter(BlocklistCursorAdapter());
    Hive.maybeRegisterAdapter(BlocklistReasonAdapter());
    Hive.maybeRegisterAdapter(BlocklistRecordAdapter());
    Hive.maybeRegisterAdapter(ChatAdapter());
    Hive.maybeRegisterAdapter(ChatIdAdapter());
    Hive.maybeRegisterAdapter(HiveUserAdapter());
    Hive.maybeRegisterAdapter(ImageFileAdapter());
    Hive.maybeRegisterAdapter(NestedChatContactAdapter());
    Hive.maybeRegisterAdapter(PlainFileAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
    Hive.maybeRegisterAdapter(ThumbHashAdapter());
    Hive.maybeRegisterAdapter(UserAdapter());
    Hive.maybeRegisterAdapter(UserAvatarAdapter());
    Hive.maybeRegisterAdapter(UserBioAdapter());
    Hive.maybeRegisterAdapter(UserCallCoverAdapter());
    Hive.maybeRegisterAdapter(UserIdAdapter());
    Hive.maybeRegisterAdapter(UserNameAdapter());
    Hive.maybeRegisterAdapter(UserNumAdapter());
    Hive.maybeRegisterAdapter(UserTextStatusAdapter());
    Hive.maybeRegisterAdapter(UserVersionAdapter());
  }

  /// Returns a list of [User]s from [Hive].
  Iterable<HiveUser> get users => valuesSafe;

  /// Puts the provided [User] to [Hive].
  Future<void> put(HiveUser user) async {
    Log.trace('put($user)', '$runtimeType');
    await putSafe(user.value.id.val, user);
  }

  /// Returns a [User] from [Hive] by its [id].
  HiveUser? get(UserId id) {
    Log.trace('get($id)', '$runtimeType');
    return getSafe(id.val);
  }

  /// Removes an [User] from [Hive] by its [id].
  Future<void> remove(UserId id) async {
    Log.trace('remove($id)', '$runtimeType');
    await deleteSafe(id.val);
  }
}

/// Persisted in [Hive] storage [User]'s [value].
@HiveType(typeId: ModelTypeId.hiveUser)
class HiveUser extends HiveObject {
  HiveUser(
    this.value,
    this.ver,
    this.blockedVer,
  );

  /// Persisted [User] model.
  @HiveField(0)
  User value;

  /// Version of this [User]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  @HiveField(1)
  UserVersion ver;

  /// Version of the authenticated [MyUser]'s blocklist state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  @HiveField(2)
  MyUserVersion blockedVer;

  @override
  String toString() => '$runtimeType($value, $ver, $blockedVer)';
}
