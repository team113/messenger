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

import 'package:hive_flutter/adapters.dart';
import 'package:messenger/domain/model/avatar.dart';
import 'package:messenger/domain/model/crop_area.dart';
import 'package:messenger/domain/model/file.dart';
import 'package:messenger/domain/model/mute_duration.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/user_call_cover.dart';
import 'package:messenger/store/model/my_user.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/account.dart';
import '/domain/model/user.dart';
import '/util/log.dart';
import 'base.dart';
import 'my_user.dart';

/// [Hive] storage for a [Account]s.
class AccountHiveProvider extends HiveBaseProvider<Account> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'account';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');

    Hive.maybeRegisterAdapter(BlocklistReasonAdapter());
    Hive.maybeRegisterAdapter(BlocklistRecordAdapter());
    Hive.maybeRegisterAdapter(ChatDirectLinkAdapter());
    Hive.maybeRegisterAdapter(ChatDirectLinkSlugAdapter());
    Hive.maybeRegisterAdapter(ChatDirectLinkVersionAdapter());
    Hive.maybeRegisterAdapter(CropPointAdapter());
    Hive.maybeRegisterAdapter(HiveMyUserAdapter());
    Hive.maybeRegisterAdapter(ImageFileAdapter());
    Hive.maybeRegisterAdapter(ThumbHashAdapter());
    Hive.maybeRegisterAdapter(MuteDurationAdapter());
    Hive.maybeRegisterAdapter(MyUserAdapter());
    Hive.maybeRegisterAdapter(MyUserEmailsAdapter());
    Hive.maybeRegisterAdapter(MyUserPhonesAdapter());
    Hive.maybeRegisterAdapter(MyUserVersionAdapter());
    Hive.maybeRegisterAdapter(PlainFileAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
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
    Hive.maybeRegisterAdapter(AccountAdapter());
  }

  /// Returns the stored [Credentials] from [Hive].
  Account? get(UserId id) {
    return getSafe(id.val);
  }

  /// Stores new [Credentials] to [Hive].
  Future<void> put(Account account) async {
    await putSafe(account.myUser.id.val, account);
  }

  /// Stores new [Credentials] to [Hive].
  Future<void> remove(UserId id) async {
    await deleteSafe(id.val);
  }
}
