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

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/contact.dart';
import '/provider/hive/contact.dart';
import '/store/user.dart';

/// [RxChatContact] implementation backed by local [Hive] storage.
class HiveRxChatContact implements RxChatContact {
  HiveRxChatContact(
      HiveChatContact hiveChatContact, this._local, this._userRepo)
      : contact = Rx<ChatContact>(hiveChatContact.value);

  @override
  final Rx<ChatContact> contact;

  @override
  Rx<User>? user;

  /// [ChatContact]s local [Hive] storage.
  final ContactHiveProvider _local;

  /// [UserRepository] uses for updating of [user].
  final UserRepository _userRepo;

  /// [ContactHiveProvider.boxEvents] subscription.
  StreamIterator<BoxEvent>? _localSubscription;

  /// Initializes this [HiveRxChatContact].
  void init() async {
    user = contact.value.users.isEmpty
        ? null
        : await _userRepo.get(contact.value.users.first.id);
    _initLocalSubscription();
  }

  /// Disposes this [HiveRxChatContact].
  void dispose() {
    _localSubscription?.cancel();
  }

  /// Initializes [ContactHiveProvider.boxEvents] subscription.
  void _initLocalSubscription() async {
    contact.listen((c) async {
      if (user != null) {
        if (user!.value.id != c.users.firstOrNull?.id) {
          user = contact.value.users.isEmpty
              ? null
              : await _userRepo.get(contact.value.users.first.id);
        }
      } else {
        if (c.users.firstOrNull != null) {
          user = await _userRepo.get(contact.value.users.first.id);
        }
      }
    });
  }
}
