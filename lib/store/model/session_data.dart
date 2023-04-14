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

import '/domain/model/session.dart';
import '/domain/model_type_id.dart';
import '/store/model/chat.dart';
import '/util/new_type.dart';
import 'contact.dart';

part 'session_data.g.dart';

/// [Session] relative preferences.
@HiveType(typeId: ModelTypeId.sessionData)
class SessionData extends HiveObject {
  /// Persisted [Credentials] data.
  @HiveField(0)
  Credentials? credentials;

  /// Persisted [ChatContactsListVersion] data.
  @HiveField(1)
  ChatContactsListVersion? chatContactsListVersion;

  /// Persisted [FavoriteChatsListVersion] data.
  @HiveField(2)
  FavoriteChatsListVersion? favoriteChatsListVersion;
}

/// Version of [Session]'s state.
///
/// It increases monotonically, so may be used (and is intended to) for
/// tracking state's actuality.
@HiveType(typeId: ModelTypeId.sessionVersion)
class SessionVersion extends NewType<BigInt> {
  const SessionVersion(BigInt val) : super(val);

  factory SessionVersion.parse(String val) => SessionVersion(BigInt.parse(val));
}

/// Version of [RememberedSession]'s state.
///
/// It increases monotonically, so may be used (and is intended to) for
/// tracking state's actuality.
@HiveType(typeId: ModelTypeId.rememberedSessionVersion)
class RememberedSessionVersion extends NewType<BigInt> {
  const RememberedSessionVersion(BigInt val) : super(val);

  factory RememberedSessionVersion.parse(String val) =>
      RememberedSessionVersion(BigInt.parse(val));
}
