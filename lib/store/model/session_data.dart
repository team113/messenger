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

import 'package:hive/hive.dart';

import '/domain/model/chat.dart';
import '/domain/model_type_id.dart';
import '/store/model/chat.dart';
import '/store/model/contact.dart';

part 'session_data.g.dart';

/// [Session] relative preferences.
@HiveType(typeId: ModelTypeId.sessionData)
class SessionData extends HiveObject {
  /// Persisted [FavoriteChatsListVersion] data.
  @HiveField(0)
  FavoriteChatsListVersion? favoriteChatsListVersion;

  /// Persisted indicator whether all favorite [Chat]s are synchronized with the
  /// remote, meaning no queries should be made.
  @HiveField(1)
  bool? favoriteChatsSynchronized;

  /// Persisted [ChatContactsListVersion] data.
  @HiveField(2)
  ChatContactsListVersion? chatContactsListVersion;

  @HiveField(3)
  /// Persisted indicator whether all favorite [ChatContact]s are stored
  /// locally.
  bool? favoriteContactsSynchronized;

  @HiveField(4)
  /// Persisted indicator whether all [ChatContact]s are stored locally.
  bool? contactsSynchronized;
}
