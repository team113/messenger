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

import 'dart:async';

import 'package:get/get.dart';

import '../model/contact.dart';
import '../model/user.dart';
import '../repository/user.dart';
import '/util/obs/obs.dart';

/// [ChatContact]s repository interface.
abstract class AbstractContactRepository {
  /// Returns reactive observable map of [ChatContact]s.
  RxObsMap<ChatContactId, RxChatContact> get contacts;

  /// Returns reactive map of favorite [ChatContact]s.
  RxObsMap<ChatContactId, RxChatContact> get favorites;

  /// Indicates whether the [contacts] has next page.
  bool get hasNextPage;

  /// Indicates whether this repository was initialized and [contacts] can be
  /// used.
  RxBool get isReady;

  /// Initializes this repository.
  Future<void> init();

  /// Disposes this repository.
  void dispose();

  /// Clears the stored [contacts].
  Future<void> clearCache();

  /// Creates a new [ChatContact] with the specified [User] in the current
  /// [MyUser]'s address book.
  Future<void> createChatContact(UserName name, UserId id);

  /// Deletes the specified [ChatContact] from the authenticated [MyUser]'s
  /// address book.
  ///
  /// No-op if the specified [ChatContact] doesn't exist.
  Future<void> deleteContact(ChatContactId id);

  /// Updates `name` of the specified [ChatContact] in the authenticated
  /// [MyUser]'s address book.
  Future<void> changeContactName(ChatContactId id, UserName name);

  /// Loads next page of a [ChatContact]s.
  Future<void> loadNextPage();

  /// Marks the specified [ChatContact] as favorited for the authenticated
  /// [MyUser] and sets its position in the favorites list.
  Future<void> favoriteChatContact(
    ChatContactId id,
    ChatContactPosition? position,
  );

  /// Removes the specified [ChatContact] from the favorites list of the
  /// authenticated [MyUser].
  Future<void> unfavoriteChatContact(ChatContactId id);
}

/// Unified reactive [ChatContact] entity.
abstract class RxChatContact {
  /// Reactive value of the [ChatContact] this [RxChatContact] represents.
  Rx<ChatContact> get contact;

  /// Returns [ChatContactId] of the [contact].
  ChatContactId get id => contact.value.id;

  /// Reactive value of the first [User] this [ChatContact] contains.
  Rx<RxUser?> get user;
}
