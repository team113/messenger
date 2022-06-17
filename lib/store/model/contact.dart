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

import 'package:hive/hive.dart';

import '/domain/model_type_id.dart';
import '/util/new_type.dart';
import 'version.dart';

part 'contact.g.dart';

/// Version of a [ChatContact]'s state.
@HiveType(typeId: ModelTypeId.chatContactVersion)
class ChatContactVersion extends Version {
  ChatContactVersion(String val) : super(val);
}

/// Cursor used for a subscription to [ChatContactEvent]s.
@HiveType(typeId: ModelTypeId.chatContactsListVersion)
class ChatContactsListVersion extends Version {
  ChatContactsListVersion(String val) : super(val);
}

/// Cursor used for [ChatContact]s pagination.
@HiveType(typeId: ModelTypeId.chatContactsCursor)
class ChatContactsCursor extends NewType<String> {
  ChatContactsCursor(String val) : super(val);
}
