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

import '../schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/provider/hive/contact.dart';
import '/provider/hive/user.dart';
import '/store/model/contact.dart';
import 'user.dart';

/// Extension adding models construction from a [ChatContactMixin].
extension ChatContactConversion on ChatContactMixin {
  /// Constructs a new [ChatContact] from this [ChatContactMixin].
  ChatContact toModel() => ChatContact(
        id,
        name: name,
        users: users.map((e) => e.toModel()).toList(),
        groups: groups.map((e) => Chat(e.id)).toList(),
        emails: emails.map((e) => e.email).toList(),
        phones: phones.map((e) => e.phone).toList(),
        favoritePosition: favoritePosition,
      );

  /// Constructs a new list of [HiveUser]s from this [ChatContactMixin].
  List<HiveUser> getHiveUsers() => users.map((e) => e.toHive()).toList();

  /// Constructs a new [HiveChatContact] from this [ChatContactMixin].
  HiveChatContact toHive([ChatContactsCursor? cursor]) =>
      HiveChatContact(toModel(), ver, cursor);
}
