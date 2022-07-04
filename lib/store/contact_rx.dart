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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/domain/model/contact.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/provider/hive/contact.dart';

/// [RxChatContact] implementation backed by local [Hive] storage.
class HiveRxChatContact implements RxChatContact {
  HiveRxChatContact(this._userRepository, HiveChatContact hiveChatContact)
      : contact = Rx<ChatContact>(hiveChatContact.value);

  @override
  final Rx<ChatContact> contact;

  @override
  final Rx<RxUser?> user = Rx(null);

  /// [AbstractUserRepository] fetching and updating the [user].
  final AbstractUserRepository _userRepository;

  /// [Worker] reacting on the [contact] changes updating the [user].
  late final Worker _worker;

  /// Initializes this [HiveRxChatContact].
  void init() {
    _updateUser(contact.value);
    _worker = ever(contact, _updateUser);
  }

  /// Disposes this [HiveRxChatContact].
  void dispose() {
    _worker.dispose();
  }

  /// Updates the [user] fetched from the [AbstractUserRepository], if needed.
  void _updateUser(ChatContact c) async {
    if (user.value?.id != c.users.firstOrNull?.id) {
      user.value = c.users.isEmpty
          ? null
          : (await _userRepository.get(c.users.first.id));
    }
  }

  @override
  ChatContactId get id => contact.value.id;
}
