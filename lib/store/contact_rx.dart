// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:hive/hive.dart';

import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/contact.dart';
import '/provider/hive/contact.dart';
import '/store/user.dart';

/// [RxChatContact] implementation backed by local [Hive] storage.
class HiveRxChatContact implements RxChatContact {
  HiveRxChatContact(HiveChatContact hiveChatContact, this._userRepo)
      : contact = Rx<ChatContact>(hiveChatContact.value);

  @override
  final Rx<ChatContact> contact;

  /// [UserRepository] uses for updating of [user].
  final UserRepository _userRepo;

  @override
  Rx<User>? user;

  /// Initializes this [HiveRxChatContact].
  void refreshUser() async {
    user = contact.value.users.isNotEmpty
        ? await _userRepo.get(contact.value.users.first.id)
        : null;
    user?.refresh();
  }
}
