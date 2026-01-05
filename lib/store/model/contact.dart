// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model/contact.dart';
import '/util/new_type.dart';
import 'version.dart';

/// Persisted in storage [ChatContact]'s [value].
class DtoChatContact {
  DtoChatContact(this.value, this.ver, this.cursor, this.favoriteCursor);

  /// Persisted [ChatContact].
  ChatContact value;

  /// Version of the [ChatContact]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  ChatContactVersion ver;

  /// Cursor of the [value] when paginating through all [ChatContact]s.
  ChatContactsCursor? cursor;

  /// Cursor of the [value] when paginating through favorite [ChatContact]s.
  FavoriteChatContactsCursor? favoriteCursor;
}

/// Version of a [ChatContact]'s state.
class ChatContactVersion extends Version {
  ChatContactVersion(super.val);
}

/// Cursor used for a subscription to [ChatContactEvent]s.
class ChatContactsListVersion extends Version {
  ChatContactsListVersion(super.val);
}

/// Cursor used for [ChatContact]s pagination.
class ChatContactsCursor extends NewType<String> {
  ChatContactsCursor(super.val);
}

/// Cursor used for favorite [ChatContact]s pagination.
class FavoriteChatContactsCursor extends NewType<String> {
  FavoriteChatContactsCursor(super.val);
}
