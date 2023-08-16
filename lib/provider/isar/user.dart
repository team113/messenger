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

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:isar/isar.dart';

import '/domain/model/user.dart';
import '/provider/isar/utils.dart';
import '/store/model/my_user.dart';
import '/store/model/user.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';

part 'user.g.dart';

/// [Isar] storage for [User]s.
class UserIsarProvider {
  UserIsarProvider(this._isar);

  /// [Isar] storing [IsarUser]s.
  final Isar _isar;

  /// [StreamController] of changes of this [UserIsarProvider].
  final _changes =
      StreamController<ListChangeNotification<IsarUser>>.broadcast();

  /// Returns a list of [User]s from [Isar].
  Future<List<IsarUser>> get users async {
    if (PlatformUtils.isWeb) {
      return _isar.users.where().findAll();
    } else {
      return await _isar.users.where().findAllAsync();
    }
  }

  /// Returns count of the stored [User]s.
  int get count => _isar.users.count();

  /// Returns stream of changes of this [UserIsarProvider].
  Stream<ListChangeNotification<IsarUser>> watch() {
    if (PlatformUtils.isWeb) {
      return _changes.stream;
    } else {
      return _isar.users
          .where()
          .watch(fireImmediately: true)
          .changes((e) => e.id);
    }
  }

  /// Returns a [User] from [Isar] by its [id].
  IsarUser? get(UserId id) => _isar.users.get(id.val);

  /// Puts the provide [user] to [Isar].
  Future<void> put(IsarUser user) async {
    if (PlatformUtils.isWeb) {
      _isar.write((isar) => isar.users.put(user));
      _changes.add(ListChangeNotification.added(user, 0));
    } else {
      await _isar.writeAsync((isar) => isar.users.put(user));
    }
  }

  /// Clears this [UserIsarProvider].
  Future<void> clear() async {
    if (PlatformUtils.isWeb) {
      final List<IsarUser> users = _isar.users.where().findAll();

      _isar.write((isar) => isar.users.clear());

      users.forEachIndexed((int index, IsarUser user) {
        _changes.add(ListChangeNotification.removed(user, index));
      });
    } else {
      await _isar.writeAsync((isar) => isar.users.clear());
    }
  }
}

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

  @override
  bool operator ==(Object other) {
    return other is IsarUser &&
        jsonEncode(other.value.toJson()) == jsonEncode(value.toJson()) &&
        other.ver == ver &&
        other.blacklistedVer == blacklistedVer;
  }

  @override
  int get hashCode => Object.hash(ver, blacklistedVer, value);
}
