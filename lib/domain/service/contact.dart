// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'package:get/get.dart';

import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/paginated.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import 'disposable_service.dart';

/// Service responsible for [ChatContact]s related functionality.
class ContactService extends Dependency {
  ContactService(this._contactRepository);

  /// Repository to fetch [ChatContact]s from.
  final AbstractContactRepository _contactRepository;

  /// Returns the [RxStatus] of the [paginated] initialization.
  Rx<RxStatus> get status => _contactRepository.status;

  /// Indicates whether the [paginated] have next page.
  RxBool get hasNext => _contactRepository.hasNext;

  /// Indicates whether a next page of the [paginated] is loading.
  RxBool get nextLoading => _contactRepository.nextLoading;

  /// Returns the reactive map of the currently paginated [RxChatContact]s.
  RxObsMap<ChatContactId, RxChatContact> get paginated =>
      _contactRepository.paginated;

  /// Returns the current reactive map of all [RxChatContact]s available.
  RxObsMap<ChatContactId, RxChatContact> get contacts =>
      _contactRepository.contacts;

  /// Fetches the next [paginated] page.
  FutureOr<void> next() {
    Log.debug('next()', '$runtimeType');
    return _contactRepository.next();
  }

  /// Adds the specified [user] to the current [MyUser]'s address book.
  Future<void> createChatContact(User user) {
    Log.debug('createChatContact($user)', '$runtimeType');

    return _contactRepository.createChatContact(
      user.name ?? UserName(user.num.toString()),
      user.id,
    );
  }

  /// Deletes the specified [ChatContact] from the authenticated [MyUser]'s
  /// address book.
  Future<void> deleteContact(ChatContactId id) async {
    Log.debug('deleteContact($id)', '$runtimeType');
    await _contactRepository.deleteContact(id);
  }

  /// Updates `name` of the specified [ChatContact] in the authenticated
  /// [MyUser]'s address book.
  Future<void> changeContactName(ChatContactId id, UserName name) async {
    Log.debug('changeContactName($id, $name)', '$runtimeType');
    await _contactRepository.changeContactName(id, name);
  }

  /// Marks the specified [ChatContact] as favorited for the authenticated
  /// [MyUser] and sets its position in the favorites list.
  Future<void> favoriteChatContact(
    ChatContactId id, [
    ChatContactFavoritePosition? position,
  ]) async {
    Log.debug('favoriteChatContact($id, $position)', '$runtimeType');
    await _contactRepository.favoriteChatContact(id, position);
  }

  /// Removes the specified [ChatContact] from the favorites list of the
  /// authenticated [MyUser].
  Future<void> unfavoriteChatContact(ChatContactId id) async {
    Log.debug('unfavoriteChatContact($id)', '$runtimeType');
    await _contactRepository.unfavoriteChatContact(id);
  }

  /// Searches [ChatContact]s by the given criteria.
  Paginated<ChatContactId, RxChatContact> search({
    UserName? name,
    UserEmail? email,
    UserPhone? phone,
  }) {
    Log.debug('search($name, $email, $phone)', '$runtimeType');

    return _contactRepository.search(name: name, email: email, phone: phone);
  }
}
