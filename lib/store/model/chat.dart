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
import 'version.dart';

part 'chat.g.dart';

/// Version of a [Chat]'s state.
@HiveType(typeId: ModelTypeId.chatVersion)
class ChatVersion extends Version {
  ChatVersion(String val) : super(val);
}

/// Cursor used for recent [Chat]s pagination.
@HiveType(typeId: ModelTypeId.recentChatsCursor)
class RecentChatsCursor extends Version {
  RecentChatsCursor(String val) : super(val);
}

/// Version of a favorite [Chat]s list.
@HiveType(typeId: ModelTypeId.favoriteChatsListVersion)
class FavoriteChatsListVersion extends Version {
  FavoriteChatsListVersion(String val) : super(val);
}
