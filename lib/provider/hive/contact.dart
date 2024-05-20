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

import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model_type_id.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/store/model/contact.dart';
import '/util/log.dart';
import 'base.dart';

part 'contact.g.dart';

/// [Hive] storage for [ChatContact]s.
class ContactHiveProvider extends HiveLazyProvider<HiveChatContact>
    implements IterableHiveProvider<HiveChatContact, ChatContactId> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'contact';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');

    Hive.maybeRegisterAdapter(ChatCallRoomJoinLinkAdapter());
    Hive.maybeRegisterAdapter(ChatContactAdapter());
    Hive.maybeRegisterAdapter(ChatContactFavoritePositionAdapter());
    Hive.maybeRegisterAdapter(ChatContactIdAdapter());
    Hive.maybeRegisterAdapter(ChatContactsCursorAdapter());
    Hive.maybeRegisterAdapter(ChatContactVersionAdapter());
    Hive.maybeRegisterAdapter(FavoriteChatContactsCursorAdapter());
    Hive.maybeRegisterAdapter(HiveChatContactAdapter());
    Hive.maybeRegisterAdapter(NestedChatContactAdapter());
    Hive.maybeRegisterAdapter(UserAdapter());
    Hive.maybeRegisterAdapter(UserBioAdapter());
    Hive.maybeRegisterAdapter(UserEmailAdapter());
    Hive.maybeRegisterAdapter(UserNameAdapter());
    Hive.maybeRegisterAdapter(UserPhoneAdapter());
  }

  @override
  Iterable<ChatContactId> get keys => keysSafe.map((e) => ChatContactId(e));

  @override
  Future<Iterable<HiveChatContact>> get values => valuesSafe;

  @override
  Future<void> put(HiveChatContact contact) async {
    Log.trace('put($contact)', '$runtimeType');
    await putSafe(contact.value.id.val, contact);
  }

  @override
  Future<HiveChatContact?> get(ChatContactId id) {
    Log.trace('get($id)', '$runtimeType');
    return getSafe(id.val);
  }

  @override
  Future<void> remove(ChatContactId id) async {
    Log.trace('remove($id)', '$runtimeType');
    await deleteSafe(id.val);
  }
}

/// Persisted in [Hive] storage [ChatContact]'s [value].
@HiveType(typeId: ModelTypeId.hiveChatContact)
class HiveChatContact extends HiveObject {
  HiveChatContact(this.value, this.ver, this.cursor, this.favoriteCursor);

  /// Persisted [ChatContact].
  @HiveField(0)
  ChatContact value;

  /// Version of the [ChatContact]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  @HiveField(1)
  ChatContactVersion ver;

  /// Cursor of the [value] when paginating through all [ChatContact]s.
  @HiveField(2)
  ChatContactsCursor? cursor;

  /// Cursor of the [value] when paginating through favorite [ChatContact]s.
  @HiveField(3)
  FavoriteChatContactsCursor? favoriteCursor;
}
