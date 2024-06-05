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
import '/domain/model/contact.dart';
import '/util/new_type.dart';
import 'version.dart';

part 'contact.g.dart';

/// Persisted in storage [ChatContact]'s [value].
@HiveType(typeId: ModelTypeId.dtoChatContact)
class DtoChatContact extends HiveObject {
  DtoChatContact(this.value, this.ver, this.cursor, this.favoriteCursor);

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

/// Version of a [ChatContact]'s state.
@HiveType(typeId: ModelTypeId.chatContactVersion)
class ChatContactVersion extends Version {
  ChatContactVersion(super.val);
}

/// Cursor used for a subscription to [ChatContactEvent]s.
@HiveType(typeId: ModelTypeId.chatContactsListVersion)
class ChatContactsListVersion extends Version {
  ChatContactsListVersion(super.val);
}

/// Cursor used for [ChatContact]s pagination.
@HiveType(typeId: ModelTypeId.chatContactsCursor)
class ChatContactsCursor extends NewType<String> {
  ChatContactsCursor(super.val);
}

/// Cursor used for favorite [ChatContact]s pagination.
@HiveType(typeId: ModelTypeId.favoriteChatContactsCursor)
class FavoriteChatContactsCursor extends NewType<String> {
  FavoriteChatContactsCursor(super.val);
}
