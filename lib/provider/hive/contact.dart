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

import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/chat_call.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/model_type_id.dart';
import '/store/model/contact.dart';
import '/store/pagination.dart';
import 'base.dart';

part 'contact.g.dart';

/// [Hive] storage for [ChatContact]s.
class ContactHiveProvider extends HiveBaseProvider<HiveChatContact>
    implements PageProvider<HiveChatContact> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'contact';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(ChatCallRoomJoinLinkAdapter());
    Hive.maybeRegisterAdapter(ChatContactAdapter());
    Hive.maybeRegisterAdapter(ChatContactFavoritePositionAdapter());
    Hive.maybeRegisterAdapter(ChatContactIdAdapter());
    Hive.maybeRegisterAdapter(ChatContactVersionAdapter());
    Hive.maybeRegisterAdapter(ChatContactsCursorAdapter());
    Hive.maybeRegisterAdapter(HiveChatContactAdapter());
    Hive.maybeRegisterAdapter(UserAdapter());
    Hive.maybeRegisterAdapter(UserEmailAdapter());
    Hive.maybeRegisterAdapter(UserNameAdapter());
    Hive.maybeRegisterAdapter(UserPhoneAdapter());
  }

  /// Returns a list of [ChatContact]s from [Hive].
  Iterable<HiveChatContact> get contacts => valuesSafe;

  /// Puts the provided [ChatContact] to [Hive].
  Future<void> put(HiveChatContact contact) =>
      putSafe(contact.value.id.val, contact);

  /// Adds the provided [ChatItem] to [Hive].
  Future<void> add(HiveChatContact contact) async {
    if (contacts.isEmpty ||
        contacts.last.cursor == null ||
        (contacts.last.value.name.val).compareTo(contact.value.name.val) ==
            -1) {
      await put(contact);
    }
  }

  /// Returns a [ChatContact] from [Hive] by its [id].
  HiveChatContact? get(ChatContactId id) => getSafe(id.val);

  /// Removes an [ChatContact] from [Hive] by its [id].
  Future<void> remove(ChatContactId id) => deleteSafe(id.val);

  @override
  Future<ItemsPage<HiveChatContact>> initial(int count, String? cursor) async {
    final List<HiveChatContact> sorted = contacts
        .sortedBy((e) => e.value.name.val + e.value.id.val)
        .take(count)
        .toList();
    return ItemsPage<HiveChatContact>(
      sorted,
      PageInfo(
        endCursor: sorted.lastWhereOrNull((e) => e.cursor != null)?.cursor?.val,
        hasNextPage: box.length > count && sorted.last.cursor == null,
        startCursor:
            sorted.firstWhereOrNull((e) => e.cursor != null)?.cursor?.val,
        hasPreviousPage: false,
      ),
    );
  }

  @override
  Future<ItemsPage<HiveChatContact>> after(
    HiveChatContact after,
    String? cursor,
    int count,
  ) async {
    final sorted =
        contacts.sortedBy((e) => e.value.name.val + e.value.id.val);
    int i = sorted.indexWhere((e) => e.value.id == after.value.id);
    if (i != -1) {
      final List<HiveChatContact> items =
          sorted.skip(i + 1).take(count).toList();
      return ItemsPage<HiveChatContact>(
        items,
        PageInfo(
          endCursor:
              items.lastWhereOrNull((e) => e.cursor != null)?.cursor?.val,
          hasNextPage: box.length > count + i + 1 && sorted.last.cursor == null,
          startCursor:
              items.firstWhereOrNull((e) => e.cursor != null)?.cursor?.val,
          hasPreviousPage: true,
        ),
      );
    }

    return ItemsPage<HiveChatContact>([]);
  }

  @override
  Future<ItemsPage<HiveChatContact>> before(
    HiveChatContact before,
    String? cursor,
    int count,
  ) {
    throw Exception('Unreachable');
  }
}

/// Persisted in [Hive] storage [ChatContact]'s [value].
@HiveType(typeId: ModelTypeId.hiveChatContact)
class HiveChatContact extends HiveObject {
  HiveChatContact(this.value, this.ver, this.cursor);

  /// Persisted [ChatContact].
  @HiveField(0)
  ChatContact value;

  /// Version of the [ChatContact]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  @HiveField(1)
  ChatContactVersion ver;

  /// Cursor of the [value].
  @HiveField(2)
  ChatContactsCursor? cursor;
}
