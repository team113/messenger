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

import 'dart:async';

import '/domain/model/chat.dart';
import '/domain/model/link.dart';
import '/domain/model/user.dart';
import '/domain/repository/link.dart';
import '/domain/repository/paginated.dart';
import '/util/log.dart';
import 'disposable_service.dart';

/// Service responsible for [DirectLink]s management.
class LinkService extends Dependency {
  LinkService(this._linkRepository);

  /// [AbstractLinkRepository] maintaining the [DirectLink]s.
  final AbstractLinkRepository _linkRepository;

  /// Listens to the updates of [DirectLink]s for the provided [ChatId] while
  /// the returned [Stream] is listened to.
  Stream<void> updatesFor(ChatId id) => _linkRepository.updatesFor(id);

  /// Returns [DirectLink]s owned by the authenticated [MyUser] or the specified
  /// [Chat]-group.
  Paginated<DirectLinkSlug, DirectLink> links({
    UserId? userId,
    ChatId? chatId,
  }) {
    Log.debug('links(userId: $userId, chatId: $chatId)', '$runtimeType');
    return _linkRepository.links(userId: userId, chatId: chatId);
  }

  /// Creates, updates or disabled the specified [DirectLink] owned by the
  /// authenticated [MyUser].
  Future<void> updateLink(DirectLinkSlug slug, UserId? userId) async {
    Log.debug('updateLink($slug, $userId)', '$runtimeType');
    return await _linkRepository.updateLink(slug, userId);
  }

  /// Creates, updates or disables the current [DirectLink] of the specified
  /// [Chat]-group.
  Future<void> updateGroupLink(ChatId groupId, DirectLinkSlug? slug) async {
    Log.debug('updateGroupLink($groupId, $slug)', '$runtimeType');
    return await _linkRepository.updateGroupLink(groupId, slug);
  }
}
