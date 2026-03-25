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
import '/domain/model/link.dart';
import '/domain/model/user.dart';
import 'paginated.dart';

/// [DirectLink] repository interface.
abstract class AbstractLinkRepository {
  /// Returns [DirectLink]s owned by the authenticated [MyUser] or the specified
  /// [Chat]-group.
  Paginated<DirectLinkSlug, DirectLink> links({UserId? userId, ChatId? chatId});

  /// Listens to the updates of [DirectLink]s for the provided [ChatId] while
  /// the returned [Stream] is listened to.
  Stream<void> updatesFor(ChatId id);

  /// Creates, updates or disabled the specified [DirectLink] owned by the
  /// authenticated [MyUser].
  Future<void> updateLink(DirectLinkSlug slug, UserId? userId);

  /// Creates, updates or disables the current [DirectLink] of the specified
  /// [Chat]-group.
  Future<void> updateGroupLink(ChatId groupId, DirectLinkSlug? slug);
}
