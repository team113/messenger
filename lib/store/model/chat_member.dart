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

import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import 'chat.dart';
import 'user.dart';

/// Persisted in storage [ChatMember].
class DtoChatMember implements Comparable<DtoChatMember> {
  DtoChatMember(this.user, this.joinedAt, this.cursor, {UserId? userId})
    : id = userId ?? user!.id;

  /// [UserId] of the [User] this [ChatMember] is about.
  UserId id;

  /// Persisted [DtoUser] model.
  User? user;

  /// [PreciseDateTime] when the [User] became a [ChatMember].
  final PreciseDateTime joinedAt;

  /// Cursor of this [ChatMember].
  ChatMembersCursor? cursor;

  @override
  String toString() => '$runtimeType($user, $joinedAt, $cursor)';

  @override
  int compareTo(DtoChatMember other) {
    final int result = joinedAt.compareTo(other.joinedAt);
    if (result == 0) {
      return id.compareTo(other.id);
    }

    return result;
  }
}
