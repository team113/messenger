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

import 'dart:async';

import 'package:get/get.dart';

import '../model/contact.dart';
import '../repository/contact.dart';
import '/domain/model/user.dart';
import '/domain/service/user.dart';
import '/store/model/contact.dart';
import '/store/pagination.dart';
import '/store/pagination/graphql.dart';
import '/util/obs/obs.dart';
import 'disposable_service.dart';

/// Service responsible for [ChatContact]s related functionality.
class ContactService extends DisposableService {
  ContactService(this._contactRepository);

  /// Repository to fetch [ChatContact]s from.
  final AbstractContactRepository _contactRepository;

  /// Returns the [RxStatus] of the [contacts] and [favorites] initialization.
  Rx<RxStatus> get status => _contactRepository.status;

  /// Returns the current reactive observable map of [ChatContact]s.
  RxObsMap<ChatContactId, RxChatContact> get contacts =>
      _contactRepository.contacts;

  /// Returns the current reactive map of favorite [ChatContact]s.
  RxObsMap<ChatContactId, RxChatContact> get favorites =>
      _contactRepository.favorites;

  @override
  void onInit() {
    _contactRepository.init();
    super.onInit();
  }

  @override
  void onClose() {
    _contactRepository.dispose();
    super.onClose();
  }

  /// Adds the specified [user] to the current [MyUser]'s address book.
  Future<void> createChatContact(User user) => _contactRepository
      .createChatContact(user.name ?? UserName(user.num.val), user.id);

  /// Deletes the specified [ChatContact] from the authenticated [MyUser]'s
  /// address book.
  Future<void> deleteContact(ChatContactId id) =>
      _contactRepository.deleteContact(id);

  /// Updates `name` of the specified [ChatContact] in the authenticated
  /// [MyUser]'s address book.
  Future<void> changeContactName(ChatContactId id, UserName name) =>
      _contactRepository.changeContactName(id, name);

  /// Marks the specified [ChatContact] as favorited for the authenticated
  /// [MyUser] and sets its position in the favorites list.
  Future<void> favoriteChatContact(
    ChatContactId id, [
    ChatContactFavoritePosition? position,
  ]) =>
      _contactRepository.favoriteChatContact(id, position);

  /// Removes the specified [ChatContact] from the favorites list of the
  /// authenticated [MyUser].
  Future<void> unfavoriteChatContact(ChatContactId id) =>
      _contactRepository.unfavoriteChatContact(id);

  /// Searches [ChatContact]s by the given criteria.
  SearchResult<RxChatContact> search({
    UserName? name,
    UserEmail? email,
    UserPhone? phone,
  }) {
    Pagination<RxChatContact, ChatContactsCursor, ChatContactId>? pagination;
    if (name != null) {
      pagination = Pagination(
        provider: GraphQlPageProvider(
          fetch: ({after, before, first, last}) {
            return _contactRepository.searchByName(
              name,
              after: after,
              first: first,
            );
          },
        ),
        onKey: (RxChatContact u) => u.id,
      );
    }
    final SearchResult<RxChatContact> searchResult =
        SearchResult(pagination: pagination);

    if (phone == null && name == null && email == null) {
      return searchResult;
    }

    final List<RxChatContact> contacts = [
      ..._contactRepository.contacts.values,
      ..._contactRepository.favorites.values
    ]
        .where((u) =>
            (phone != null && u.contact.value.phones.contains(phone)) ||
            (name != null &&
                u.contact.value.name.val.contains(name.val) == true))
        .toList();

    searchResult.items.value = contacts;
    searchResult.status.value =
        contacts.isEmpty ? RxStatus.loading() : RxStatus.loadingMore();

    void add(List<RxChatContact> c) {
      Set<RxChatContact> contacts = searchResult.items.toSet()..addAll(c);
      searchResult.items.value = contacts.toList();
    }

    List<Future> futures = [
      if (name != null) searchResult.pagination!.around(),
      if (phone != null) _contactRepository.searchByPhone(phone).then(add),
      if (email != null) _contactRepository.searchByEmail(email).then(add),
    ];

    Future.wait(futures)
        .then((_) => searchResult.status.value = RxStatus.success());

    return searchResult;
  }
}
