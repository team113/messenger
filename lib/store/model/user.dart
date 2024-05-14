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
import '/domain/model/user.dart';
import '/util/new_type.dart';
import 'my_user.dart';
import 'version.dart';

part 'user.g.dart';

/// Persisted in storage [User]'s [value].
class DtoUser {
  DtoUser(this.value, this.ver, this.blockedVer);

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

  /// Returns the [UserId] of [value].
  UserId get id => value.id;

  @override
  String toString() => '$runtimeType($value, $ver, $blockedVer)';
}

/// Version of an [User]'s state.
@HiveType(typeId: ModelTypeId.userVersion)
class UserVersion extends Version {
  UserVersion(super.val);

  /// Constructs a [UsersCursor] from the provided [val].
  factory UserVersion.fromJson(String val) = UserVersion;

  /// Returns a [String] representing this [UserId].
  String toJson() => val;
}

/// Cursor used for [User]s pagination.
@HiveType(typeId: ModelTypeId.usersCursor)
class UsersCursor extends NewType<String> {
  UsersCursor(super.val);

  /// Constructs a [UsersCursor] from the provided [val].
  factory UsersCursor.fromJson(String val) = UsersCursor;

  /// Returns a [String] representing this [UsersCursor].
  String toJson() => val;
}
