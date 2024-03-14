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
import 'my_user.dart';
import 'session.dart';

part 'account.g.dart';

@HiveType(typeId: ModelTypeId.account)
class Account extends HiveObject implements Comparable<Account> {
  Account(this.credentials, this.myUser);

  @HiveField(0)
  final Credentials credentials;

  @HiveField(1)
  final MyUser myUser;

  @override
  int compareTo(Account other) {
    if (myUser.name != null && other.myUser.name == null) {
      return -1;
    } else if (myUser.name == null && other.myUser.name != null) {
      return 1;
    } else if (myUser.name == null && other.myUser.name == null) {
      return myUser.num.val.compareTo(other.myUser.num.val);
    } else {
      return myUser.name!.val.compareTo(other.myUser.name!.val);
    }
  }
}
