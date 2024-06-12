// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:mutex/mutex.dart';

import '/api/backend/extension/page_info.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/user.dart';
import '/provider/drift/user.dart';
import '/provider/gql/graphql.dart';
import '/store/event/user.dart';
import '/store/model/user.dart';
import '/store/pagination.dart';
import '/store/pagination/graphql.dart';
import '/store/user_rx.dart';
import '/util/log.dart';
import '/util/new_type.dart';
import 'event/my_user.dart'
    show BlocklistEvent, EventBlocklistRecordAdded, EventBlocklistRecordRemoved;
import 'paginated.dart';

/// Implementation of an [AbstractUserRepository].
class UserRepository extends DisposableInterface
    implements AbstractUserRepository {
  UserRepository(
    this._graphQlProvider,
    this._userLocal,
  );

  @override
  final RxMap<UserId, RxUserImpl> users = RxMap();

  /// Callback, called when a [RxChat] with the provided [ChatId] is required
  /// by this [UserRepository].
  ///
  /// Used to populate the [RxUser.dialog] values.
  FutureOr<RxChat?> Function(ChatId id)? getChat;

  /// Callback, called when a [RxChatContact] with the provided [ChatContactId]
  /// is required by this [UserRepository].
  ///
  /// Used to populate the [RxUser.contact] value.
  FutureOr<RxChatContact?> Function(ChatContactId id)? getContact;

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [User]s local storage.
  final UserDriftProvider _userLocal;

  /// [Mutex]es guarding access to the [get] method.
  final Map<UserId, Mutex> _locks = {};

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    users.forEach((_, v) => v.dispose());
    super.onClose();
  }

  @override
  Paginated<UserId, RxUser> search({
    UserNum? num,
    UserName? name,
    UserLogin? login,
    ChatDirectLinkSlug? link,
  }) {
    Log.debug('search($num, $name, $login, $link)', '$runtimeType');

    if (num == null && name == null && login == null && link == null) {
      return PaginatedImpl();
    }

    Pagination<RxUser, UsersCursor, UserId>? pagination;
    if (name != null) {
      pagination = Pagination(
        perPage: 30,
        provider: GraphQlPageProvider(
          fetch: ({after, before, first, last}) {
            return searchByName(name, after: after, first: first);
          },
        ),
        onKey: (RxUser u) => u.id,
      );
    }

    final List<RxUser> users = this
        .users
        .values
        .where((u) =>
            (num != null && u.user.value.num == num) ||
            (name != null &&
                u.user.value.name?.val
                        .toLowerCase()
                        .contains(name.val.toLowerCase()) ==
                    true))
        .toList();

    Map<UserId, RxUser> toMap(RxUser? u) => {if (u != null) u.id: u};

    return PaginatedImpl(
      pagination: pagination,
      initial: [
        {for (var u in users) u.id: u},
        if (num != null) searchByNum(num).then(toMap),
        if (login != null) searchByLogin(login).then(toMap),
        if (link != null) searchByLink(link).then(toMap),
      ],
    );
  }

  @override
  FutureOr<RxUserImpl?> get(UserId id) {
    // Return the stored user instance, if it exists.
    final RxUserImpl? user = users[id];
    if (user != null) {
      return user;
    }

    // If [user] doesn't exist, we should lock the [mutex] to avoid remote
    // double invoking.
    Mutex? mutex = _locks[id];
    if (mutex == null) {
      mutex = Mutex();
      _locks[id] = mutex;
    }

    return mutex.protect(() async {
      RxUserImpl? user = users[id];

      if (user == null) {
        final DtoUser? stored = await _userLocal.read(id);
        if (stored != null) {
          final RxUserImpl rxUser = RxUserImpl(this, _userLocal, stored);
          return users[id] = rxUser;
        } else {
          final response = (await _graphQlProvider.getUser(id)).user;
          if (response != null) {
            final DtoUser dto = response.toDto();
            put(dto);

            final RxUserImpl rxUser = RxUserImpl(this, _userLocal, dto);
            return users[id] = rxUser;
          }
        }
      }

      return user;
    });
  }

  @override
  Future<void> blockUser(UserId id, BlocklistReason? reason) async {
    Log.debug('blockUser($id, $reason)', '$runtimeType');

    final RxUser? user = users[id];
    final BlocklistRecord? record = user?.user.value.isBlocked;

    if (user?.user.value.isBlocked == null) {
      user?.user.value.isBlocked = BlocklistRecord(
        userId: id,
        reason: reason,
        at: PreciseDateTime.now(),
      );
      user?.user.refresh();
    }

    try {
      await _graphQlProvider.blockUser(id, reason);
    } catch (_) {
      if (user != null && user.user.value.isBlocked != record) {
        user.user.value.isBlocked = record ?? user.user.value.isBlocked;
        user.user.refresh();
      }
      rethrow;
    }
  }

  @override
  Future<void> unblockUser(UserId id) async {
    Log.debug('unblockUser($id)', '$runtimeType');

    final RxUser? user = users[id];
    final BlocklistRecord? record = user?.user.value.isBlocked;

    if (user?.user.value.isBlocked != null) {
      user?.user.value.isBlocked = null;
      user?.user.refresh();
    }

    try {
      await _graphQlProvider.unblockUser(id);
    } catch (_) {
      if (user != null && user.user.value.isBlocked != record) {
        user.user.value.isBlocked = record ?? user.user.value.isBlocked;
        user.user.refresh();
      }
      rethrow;
    }
  }

  /// Updates the locally stored [DtoUser] with the provided [user] value.
  Future<void> update(User user) async {
    final DtoUser? dto = await _userLocal.read(user.id);
    if (dto != null) {
      put(dto..value = user, ignoreVersion: true);
    }
  }

  /// Puts the provided [user] into the local storage.
  Future<void> put(DtoUser user, {bool ignoreVersion = false}) async {
    Log.trace('put(${user.value.id}, $ignoreVersion)', '$runtimeType');

    // If the provided [user] doesn't exist in the [users] yet, then we should
    // lock the [mutex] to ensure [get] doesn't invoke remote while [put]ting.
    if (users.containsKey(user.value.id)) {
      await _putUser(user, ignoreVersion: ignoreVersion);
    } else {
      Mutex? mutex = _locks[user.value.id];
      if (mutex == null) {
        mutex = Mutex();
        _locks[user.value.id] = mutex;
      }

      await mutex.protect(() async {
        await _putUser(user, ignoreVersion: ignoreVersion);
      });
    }
  }

  /// Searches [User]s by the provided [UserNum].
  ///
  /// This is an exact match search.
  Future<RxUser?> searchByNum(UserNum num) async =>
      (await _search(num: num)).edges.firstOrNull;

  /// Searches [User]s by the provided [UserLogin].
  ///
  /// This is an exact match search.
  Future<RxUser?> searchByLogin(UserLogin login) async =>
      (await _search(login: login)).edges.firstOrNull;

  /// Searches [User]s by the provided [ChatDirectLinkSlug].
  ///
  /// This is an exact match search.
  Future<RxUser?> searchByLink(ChatDirectLinkSlug link) async =>
      (await _search(link: link)).edges.firstOrNull;

  /// Searches [User]s by the provided [UserName].
  ///
  /// This is a fuzzy search.
  Future<Page<RxUser, UsersCursor>> searchByName(
    UserName name, {
    UsersCursor? after,
    int? first,
  }) =>
      _search(name: name, after: after, first: first);

  /// Adds the provided [ChatContactId] to the [User.contacts] with the
  /// specified [UserId].
  ///
  /// Intended to be invoked from [ContactRepository], as [RxUser] has no events
  /// of its [User.contacts] list changes.
  Future<void> addContact(ChatContact contact, UserId userId) async {
    Log.debug('addContact($contact, $userId)', '$runtimeType');

    final DtoUser? dto = await _userLocal.read(userId);
    if (dto != null) {
      final NestedChatContact? existing =
          dto.value.contacts.firstWhereOrNull((e) => e.id == contact.id);

      if (existing == null) {
        dto.value.contacts.add(NestedChatContact.from(contact));
        await _userLocal.upsert(dto);
      } else if (existing.name != contact.name) {
        existing.name = contact.name;
        await _userLocal.upsert(dto);
      }
    }
  }

  /// Removes the provided [ChatContactId] from the [User.contacts] with the
  /// specified [UserId].
  ///
  /// Intended to be invoked from [ContactRepository], as [RxUser] has no events
  /// of its [User.contacts] list changes.
  Future<void> removeContact(ChatContactId contactId, UserId userId) async {
    Log.debug('removeContact($contactId, $userId)', '$runtimeType');

    final DtoUser? dto = await _userLocal.read(userId);
    if (dto != null) {
      final NestedChatContact? existing =
          dto.value.contacts.firstWhereOrNull((e) => e.id == contactId);

      if (existing != null) {
        dto.value.contacts.remove(existing);
        await _userLocal.upsert(dto);
      }
    }
  }

  /// Returns a [Stream] of [UserEvent]s of the specified [User].
  Future<Stream<UserEvents>> userEvents(
    UserId id,
    Future<UserVersion?> Function() ver,
  ) async {
    Log.debug('userEvents($id)', '$runtimeType');

    final Stream events = await _graphQlProvider.userEvents(id, ver);
    return events.asyncExpand((event) async* {
      Log.trace('userEvents($id): ${event.data}', '$runtimeType');

      final events = UserEvents$Subscription.fromJson(event.data!).userEvents;
      if (events.$$typename == 'SubscriptionInitialized') {
        events as UserEvents$Subscription$UserEvents$SubscriptionInitialized;
        yield const UserEventsInitialized();
      } else if (events.$$typename == 'User') {
        final mixin = events as UserEvents$Subscription$UserEvents$User;
        yield UserEventsUser(mixin.toDto());
      } else if (events.$$typename == 'UserEventsVersioned') {
        final mixin = events as UserEventsVersionedMixin;
        yield UserEventsEvent(UserEventsVersioned(
          mixin.events.map((e) => _userEvent(e)).toList(),
          mixin.ver,
        ));
      } else if (events.$$typename == 'BlocklistEventsVersioned') {
        final mixin = events as BlocklistEventsVersionedMixin;
        yield UserEventsBlocklistEventsEvent(BlocklistEventsVersioned(
          mixin.events.map((e) => _blocklistEvent(e)).toList(),
          mixin.myVer,
        ));
      } else if (events.$$typename == 'isBlocked') {
        final node = events as UserEvents$Subscription$UserEvents$IsBlocked;
        yield UserEventsIsBlocked(
          node.record == null
              ? null
              : BlocklistRecord(
                  userId: id,
                  reason: node.record!.reason,
                  at: node.record!.at,
                ),
          node.myVer,
        );
      }
    });
  }

  /// Puts the provided [user] to local storage.
  Future<void> _putUser(DtoUser user, {bool ignoreVersion = false}) async {
    Log.trace('_putUser($user, $ignoreVersion)', '$runtimeType');

    final saved = await _userLocal.read(user.value.id);

    if (saved == null ||
        saved.ver <= user.ver ||
        saved.blockedVer <= user.blockedVer ||
        ignoreVersion) {
      await _userLocal.upsert(user);
    }
  }

  /// Searches [User]s by the given criteria.
  ///
  /// Exactly one of [num]/[login]/[link]/[name] arguments must be specified
  /// (be non-`null`).
  Future<Page<RxUser, UsersCursor>> _search({
    UserNum? num,
    UserName? name,
    UserLogin? login,
    ChatDirectLinkSlug? link,
    UsersCursor? after,
    int? first,
  }) async {
    Log.debug(
      '_search($num, $name, $login, $link, $after, $first)',
      '$runtimeType',
    );

    const maxInt = 120;
    final response = await _graphQlProvider.searchUsers(
      num: num,
      name: name,
      login: login,
      link: link,
      after: after,
      first: first ?? maxInt,
    );

    final List<DtoUser> dtoUsers =
        response.searchUsers.edges.map((c) => c.node.toDto()).toList();

    dtoUsers.forEach(put);

    // We are waiting for a dummy [Future] here because [put] updates
    // [boxEvents] by scheduling a microtask, so we can use [get] method (after
    // this `await` expression) on the next Event Loop iteration.
    await Future.delayed(Duration.zero);

    final List<RxUser> users = [];
    final List<Future<RxUser?>> futures = [];

    for (final dto in dtoUsers) {
      final FutureOr<RxUser?> rxUser = get(dto.value.id);
      if (rxUser is RxUser?) {
        if (rxUser != null) {
          users.add(rxUser);
        }
      } else {
        futures.add(rxUser);
      }
    }

    users.addAll((await Future.wait(futures)).whereNotNull());

    return Page(
      RxList(users),
      response.searchUsers.pageInfo.toModel((c) => UsersCursor(c)),
    );
  }

  /// Constructs a [UserEvent] from the [UserEventsVersionedMixin$Events].
  UserEvent _userEvent(UserEventsVersionedMixin$Events e) {
    Log.trace('_userEvent($e)', '$runtimeType');

    if (e.$$typename == 'EventUserAvatarDeleted') {
      final node = e as UserEventsVersionedMixin$Events$EventUserAvatarDeleted;
      return EventUserAvatarDeleted(node.userId, node.at);
    } else if (e.$$typename == 'EventUserAvatarUpdated') {
      final node = e as UserEventsVersionedMixin$Events$EventUserAvatarUpdated;
      return EventUserAvatarUpdated(
        node.userId,
        node.avatar.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventUserCallCoverDeleted') {
      final node =
          e as UserEventsVersionedMixin$Events$EventUserCallCoverDeleted;
      return EventUserCallCoverDeleted(node.userId, node.at);
    } else if (e.$$typename == 'EventUserCallCoverUpdated') {
      final node =
          e as UserEventsVersionedMixin$Events$EventUserCallCoverUpdated;
      return EventUserCallCoverUpdated(
        node.userId,
        node.callCover.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventUserCameOffline') {
      final node = e as UserEventsVersionedMixin$Events$EventUserCameOffline;
      return EventUserCameOffline(node.userId, node.at);
    } else if (e.$$typename == 'EventUserCameOnline') {
      final node = e as UserEventsVersionedMixin$Events$EventUserCameOnline;
      return EventUserCameOnline(node.userId);
    } else if (e.$$typename == 'EventUserDeleted') {
      final node = e as UserEventsVersionedMixin$Events$EventUserDeleted;
      return EventUserDeleted(node.userId, node.at);
    } else if (e.$$typename == 'EventUserNameDeleted') {
      final node = e as UserEventsVersionedMixin$Events$EventUserNameDeleted;
      return EventUserNameDeleted(node.userId, node.at);
    } else if (e.$$typename == 'EventUserNameUpdated') {
      final node = e as UserEventsVersionedMixin$Events$EventUserNameUpdated;
      return EventUserNameUpdated(node.userId, node.name, node.at);
    } else if (e.$$typename == 'EventUserPresenceUpdated') {
      final node =
          e as UserEventsVersionedMixin$Events$EventUserPresenceUpdated;
      return EventUserPresenceUpdated(node.userId, node.presence, node.at);
    } else if (e.$$typename == 'EventUserStatusDeleted') {
      final node = e as UserEventsVersionedMixin$Events$EventUserStatusDeleted;
      return EventUserStatusDeleted(node.userId, node.at);
    } else if (e.$$typename == 'EventUserStatusUpdated') {
      final node = e as UserEventsVersionedMixin$Events$EventUserStatusUpdated;
      return EventUserStatusUpdated(node.userId, node.status, node.at);
    } else if (e.$$typename == 'EventUserBioDeleted') {
      final node = e as UserEventsVersionedMixin$Events$EventUserBioDeleted;
      return EventUserBioDeleted(node.userId, node.at);
    } else if (e.$$typename == 'EventUserBioUpdated') {
      final node = e as UserEventsVersionedMixin$Events$EventUserBioUpdated;
      return EventUserBioUpdated(node.userId, node.bio, node.at);
    } else {
      throw UnimplementedError('Unknown UserEvent: ${e.$$typename}');
    }
  }

  /// Constructs a [BlocklistEvent] from the
  /// [BlocklistEventsVersionedMixin$Events].
  BlocklistEvent _blocklistEvent(BlocklistEventsVersionedMixin$Events e) {
    Log.trace('_blocklistEvent($e)', '$runtimeType');

    if (e.$$typename == 'EventBlocklistRecordAdded') {
      final node =
          e as BlocklistEventsVersionedMixin$Events$EventBlocklistRecordAdded;
      return EventBlocklistRecordAdded(e.user.toDto(), e.at, node.reason);
    } else if (e.$$typename == 'EventBlocklistRecordRemoved') {
      return EventBlocklistRecordRemoved(e.user.toDto(), e.at);
    } else {
      throw UnimplementedError('Unknown BlocklistEvent: ${e.$$typename}');
    }
  }
}
