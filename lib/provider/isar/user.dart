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

import 'package:isar/isar.dart';

import '/domain/model/user.dart';
import '/store/model/my_user.dart';
import '/store/model/user.dart';

part 'user.g.dart';

/// Persisted in [Isar] storage [User]'s [value].
@Collection(accessor: 'users')
@Name('User')
class IsarUser {
  IsarUser(this.value, this.ver, this.blacklistedVer);

  /// ID of this [User].
  String get id => value.id.val;

  /// Persisted [User] model.
  User value;

  /// Version of this [User]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  UserVersion ver;

  /// Version of the authenticated [MyUser]'s blacklist state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  MyUserVersion blacklistedVer;
}
