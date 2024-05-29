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

import 'package:hive/hive.dart';

import '/domain/model/avatar.dart';
import '/domain/model/crop_area.dart';
import '/domain/model/file.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/store/model/my_user.dart';
import '/util/log.dart';
import 'base.dart';

/// [Hive] storage for [MyUser].
class MyUserHiveProvider extends HiveBaseProvider<DtoMyUser> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'my_user';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');

    Hive.maybeRegisterAdapter(BlocklistCursorAdapter());
    Hive.maybeRegisterAdapter(BlocklistReasonAdapter());
    Hive.maybeRegisterAdapter(BlocklistRecordAdapter());
    Hive.maybeRegisterAdapter(ChatDirectLinkAdapter());
    Hive.maybeRegisterAdapter(ChatDirectLinkSlugAdapter());
    Hive.maybeRegisterAdapter(ChatDirectLinkVersionAdapter());
    Hive.maybeRegisterAdapter(CropPointAdapter());
    Hive.maybeRegisterAdapter(DtoMyUserAdapter());
    Hive.maybeRegisterAdapter(ImageFileAdapter());
    Hive.maybeRegisterAdapter(MuteDurationAdapter());
    Hive.maybeRegisterAdapter(MyUserAdapter());
    Hive.maybeRegisterAdapter(MyUserEmailsAdapter());
    Hive.maybeRegisterAdapter(MyUserPhonesAdapter());
    Hive.maybeRegisterAdapter(MyUserVersionAdapter());
    Hive.maybeRegisterAdapter(PlainFileAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
    Hive.maybeRegisterAdapter(ThumbHashAdapter());
    Hive.maybeRegisterAdapter(UserAvatarAdapter());
    Hive.maybeRegisterAdapter(UserBioAdapter());
    Hive.maybeRegisterAdapter(UserCallCoverAdapter());
    Hive.maybeRegisterAdapter(UserEmailAdapter());
    Hive.maybeRegisterAdapter(UserIdAdapter());
    Hive.maybeRegisterAdapter(UserLoginAdapter());
    Hive.maybeRegisterAdapter(UserNameAdapter());
    Hive.maybeRegisterAdapter(UserNumAdapter());
    Hive.maybeRegisterAdapter(UserPhoneAdapter());
    Hive.maybeRegisterAdapter(UserTextStatusAdapter());
  }

  /// Returns the stored [MyUser]s from [Hive].
  Iterable<DtoMyUser> get myUsers => valuesSafe;

  /// Saves the provided [MyUser] in [Hive].
  Future<void> put(DtoMyUser user) async {
    Log.trace('put($user)', '$runtimeType');
    await putSafe(user.value.id.val, user);
  }

  /// Returns the [MyUser] from [Hive] by its [id].
  DtoMyUser? get(UserId id) {
    Log.trace('get($id)', '$runtimeType');
    return getSafe(id.val);
  }

  /// Removes the [MyUser] from [Hive] by its [id].
  Future<void> remove(UserId id) async {
    Log.trace('remove($id)', '$runtimeType');
    await deleteSafe(id.val);
  }
}
