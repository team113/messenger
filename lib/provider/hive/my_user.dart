// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model_type_id.dart';
import '/domain/model/avatar.dart';
import '/domain/model/crop_area.dart';
import '/domain/model/file.dart';
import '/domain/model/gallery_item.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/store/model/my_user.dart';
import 'base.dart';

part 'my_user.g.dart';

/// [Hive] storage for [MyUser].
class MyUserHiveProvider extends HiveBaseProvider<HiveMyUser> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch(key: 0);

  @override
  String get boxName => 'my_user';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(ChatDirectLinkAdapter());
    Hive.maybeRegisterAdapter(ChatDirectLinkSlugAdapter());
    Hive.maybeRegisterAdapter(ChatDirectLinkVersionAdapter());
    Hive.maybeRegisterAdapter(CropPointAdapter());
    Hive.maybeRegisterAdapter(GalleryItemIdAdapter());
    Hive.maybeRegisterAdapter(HiveMyUserAdapter());
    Hive.maybeRegisterAdapter(ImageGalleryItemAdapter());
    Hive.maybeRegisterAdapter(MuteDurationAdapter());
    Hive.maybeRegisterAdapter(MyUserAdapter());
    Hive.maybeRegisterAdapter(MyUserEmailsAdapter());
    Hive.maybeRegisterAdapter(MyUserPhonesAdapter());
    Hive.maybeRegisterAdapter(MyUserVersionAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
    Hive.maybeRegisterAdapter(StorageFileAdapter());
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

  /// Returns the stored [MyUser] from [Hive].
  HiveMyUser? get myUser => getSafe(0);

  /// Saves the provided [MyUser] in [Hive].
  Future<void> set(HiveMyUser user) => putSafe(0, user);
}

/// Persisted in [Hive] storage [MyUser]'s [value].
@HiveType(typeId: ModelTypeId.hiveMyUser)
class HiveMyUser extends HiveObject {
  HiveMyUser(
    this.value,
    this.ver,
  );

  /// Persisted [MyUser] model.
  @HiveField(0)
  MyUser value;

  /// Version of this [MyUser]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  @HiveField(1)
  MyUserVersion ver;
}
