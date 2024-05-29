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

import '/domain/model_type_id.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/util/new_type.dart';
import 'version.dart';

part 'my_user.g.dart';

/// Persisted in [Hive] storage [MyUser]'s [value].
@HiveType(typeId: ModelTypeId.dtoMyUser)
class DtoMyUser extends HiveObject {
  DtoMyUser(this.value, this.ver);

  /// Persisted [MyUser] model.
  @HiveField(0)
  MyUser value;

  /// Version of this [MyUser]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  @HiveField(1)
  MyUserVersion ver;

  /// Returns the [UserId] of the [value].
  UserId get id => value.id;

  @override
  String toString() => '$runtimeType($value, $ver)';
}

/// Version of [MyUser]'s state.
@HiveType(typeId: ModelTypeId.myUserVersion)
class MyUserVersion extends Version {
  MyUserVersion(super.val);
}

/// Version of a [ChatDirectLink]'s state.
@HiveType(typeId: ModelTypeId.chatDirectLinkVersion)
class ChatDirectLinkVersion extends Version {
  ChatDirectLinkVersion(super.val);
}

/// Cursor of blocked [User]s.
@HiveType(typeId: ModelTypeId.blocklistCursor)
class BlocklistCursor extends NewType<String> {
  BlocklistCursor(super.val);
}
