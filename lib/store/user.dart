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
import 'package:hive/hive.dart';
import 'package:mutex/mutex.dart';

import '/api/backend/extension/page_info.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/user.dart';
import '/provider/gql/graphql.dart';
import '/provider/hive/user.dart';
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
  final RxMap<UserId, HiveRxUser> users = RxMap();

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

  // TODO: Make [UserHiveProvider] lazy.
  /// [User]s local [Hive] storage.
  final UserHiveProvider _userLocal;

  /// [isReady] value.
  final RxBool _isReady = RxBool(false);

  /// [Mutex]es guarding access to the [get] method.
  final Map<UserId, Mutex> _locks = {};

  /// [UserHiveProvider.boxEvents] subscription.
  StreamIterator? _localSubscription;

  @override
  RxBool get isReady => _isReady;

  @override
  Future<void> onReady() async {
    Log.debug('onReady()', '$runtimeType');

    if (!_userLocal.isEmpty) {
      for (HiveUser c in _userLocal.users) {
        users[c.value.id] ??= HiveRxUser(this, _userLocal, c);
      }
      isReady.value = true;
    }

    _initLocalSubscription();

    super.onReady();
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    users.forEach((_, v) => v.dispose());
    _localSubscription?.cancel();

    super.onClose();
  }

  @override
  Future<void> clearCache() async {
    Log.debug('clearCache()', '$runtimeType');
    await _userLocal.clear();
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
  FutureOr<RxUser?> get(UserId id) {
    // Return the stored user instance, if it exists.
    final HiveRxUser? user = users[id];
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
      HiveRxUser? user = users[id];

      if (user == null) {
        final response = (await _graphQlProvider.getUser(id)).user;
        if (response != null) {
          final HiveUser hiveUser = response.toHive();
          put(hiveUser);

          final HiveRxUser hiveRxUser = HiveRxUser(this, _userLocal, hiveUser);
          users[id] = hiveRxUser;
          user = hiveRxUser;
        }
      }

      return user;
    });
  }

  @override
  Future<void> blockUser(UserId id, BlocklistReason? reason) async {
    Log.debug('blockUser($id, $reason)', '$runtimeType');

    final BlocklistEventsVersionedMixin? response =
        await _graphQlProvider.blockUser(id, reason);

    if (response != null) {
      final event = UserEventsBlocklistEventsEvent(
        BlocklistEventsVersioned(
          response.events.map((e) => _blocklistEvent(e)).toList(),
          response.myVer,
        ),
      );

      await users[id]?.userEvent(event, updateVersion: false);
    }
  }

  @override
  Future<void> unblockUser(UserId id) async {
    Log.debug('unblockUser($id)', '$runtimeType');

    final BlocklistEventsVersionedMixin? response =
        await _graphQlProvider.unblockUser(id);

    if (response != null) {
      final event = UserEventsBlocklistEventsEvent(
        BlocklistEventsVersioned(
          response.events.map((e) => _blocklistEvent(e)).toList(),
          response.myVer,
        ),
      );

      await users[id]?.userEvent(event, updateVersion: false);
    }
  }

  /// Updates the locally stored [HiveUser] with the provided [user] value.
  void update(User user) {
    Log.debug('update($user)', '$runtimeType');

    final HiveUser? hiveUser = _userLocal.get(user.id);
    if (hiveUser != null) {
      hiveUser.value = user;
      put(hiveUser, ignoreVersion: true);
    }
  }

  /// Puts the provided [user] into the local [Hive] storage.
  Future<void> put(HiveUser user, {bool ignoreVersion = false}) async {
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

    final HiveUser? user = _userLocal.get(userId);
    if (user != null) {
      final NestedChatContact? existing =
          user.value.contacts.firstWhereOrNull((e) => e.id == contact.id);

      if (existing == null) {
        user.value.contacts.add(NestedChatContact.from(contact));
        await _userLocal.put(user);
      } else if (existing.name != contact.name) {
        existing.name = contact.name;
        await _userLocal.put(user);
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

    final HiveUser? user = _userLocal.get(userId);
    if (user != null) {
      final NestedChatContact? existing =
          user.value.contacts.firstWhereOrNull((e) => e.id == contactId);

      if (existing != null) {
        user.value.contacts.remove(existing);
        await _userLocal.put(user);
      }
    }
  }

  /// Returns a [Stream] of [UserEvent]s of the specified [User].
  Stream<UserEvents> userEvents(UserId id, UserVersion? Function() ver) {
    Log.debug('userEvents($id)', '$runtimeType');

    return _graphQlProvider.userEvents(id, ver).asyncExpand((event) async* {
      Log.trace('userEvents($id): ${event.data}', '$runtimeType');

      final events = UserEvents$Subscription.fromJson(event.data!).userEvents;
      if (events.$$typename == 'SubscriptionInitialized') {
        events as UserEvents$Subscription$UserEvents$SubscriptionInitialized;
        yield const UserEventsInitialized();
      } else if (events.$$typename == 'User') {
        final mixin = events as UserEvents$Subscription$UserEvents$User;
        yield UserEventsUser(mixin.toHive());
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

  /// Puts the provided [user] to [Hive].
  Future<void> _putUser(HiveUser user, {bool ignoreVersion = false}) async {
    Log.trace('_putUser($user, $ignoreVersion)', '$runtimeType');

    final saved = _userLocal.get(user.value.id);

    if (saved == null ||
        saved.ver <= user.ver ||
        saved.blockedVer <= user.blockedVer ||
        ignoreVersion) {
      await _userLocal.put(user);
    }
  }

  /// Initializes [ContactHiveProvider.boxEvents] subscription.
  Future<void> _initLocalSubscription() async {
    Log.debug('_initLocalSubscription()', '$runtimeType');

    _localSubscription = StreamIterator(_userLocal.boxEvents);
    while (await _localSubscription!.moveNext()) {
      final BoxEvent event = _localSubscription!.current;
      if (event.deleted) {
        users.remove(UserId(event.key))?.dispose();
      } else {
        final RxUser? user = users[UserId(event.key)];
        if (user == null) {
          users[UserId(event.key)] = HiveRxUser(this, _userLocal, event.value);
        } else {
          user.user.value = event.value.value;
          user.user.refresh();
        }
      }
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

    final List<HiveUser> hiveUsers =
        response.searchUsers.edges.map((c) => c.node.toHive()).toList();

    hiveUsers.forEach(put);

    // We are waiting for a dummy [Future] here because [put] updates
    // [boxEvents] by scheduling a microtask, so we can use [get] method (after
    // this `await` expression) on the next Event Loop iteration.
    await Future.delayed(Duration.zero);

    final List<RxUser> users = [];
    final List<Future<RxUser?>> futures = [];

    for (final hiveUser in hiveUsers) {
      final FutureOr<RxUser?> rxUser = get(hiveUser.value.id);
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
      return EventBlocklistRecordAdded(
        e.user.toHive(),
        e.at,
        node.reason,
      );
    } else if (e.$$typename == 'EventBlocklistRecordRemoved') {
      return EventBlocklistRecordRemoved(e.user.toHive(), e.at);
    } else {
      throw UnimplementedError('Unknown BlocklistEvent: ${e.$$typename}');
    }
  }
}
