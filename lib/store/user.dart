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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mutex/mutex.dart';

import '/api/backend/extension/page_info.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/search.dart';
import '/domain/repository/user.dart';
import '/provider/gql/graphql.dart';
import '/provider/hive/user.dart';
import '/store/event/user.dart';
import '/store/model/user.dart';
import '/store/pagination.dart';
import '/store/pagination/graphql.dart';
import '/store/user_rx.dart';
import '/util/new_type.dart';
import 'event/my_user.dart'
    show BlocklistEvent, EventBlocklistRecordAdded, EventBlocklistRecordRemoved;
import 'search.dart';

/// Implementation of an [AbstractUserRepository].
class UserRepository implements AbstractUserRepository {
  UserRepository(
    this._graphQlProvider,
    this._userLocal,
  );

  /// Callback, called when a [RxChat] with the provided [ChatId] is required
  /// by this [UserRepository].
  ///
  /// Used to populate the [RxUser.dialog] values.
  Future<RxChat?> Function(ChatId id)? getChat;

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [User]s local [Hive] storage.
  final UserHiveProvider _userLocal;

  /// [isReady] value.
  final RxBool _isReady = RxBool(false);

  /// [users] value.
  final RxMap<UserId, RxUser> _users = RxMap<UserId, RxUser>();

  /// [Mutex]es guarding access to the [get] method.
  final Map<UserId, Mutex> _locks = {};

  /// [UserHiveProvider.boxEvents] subscription.
  StreamIterator? _localSubscription;

  @override
  RxBool get isReady => _isReady;

  @override
  RxMap<UserId, RxUser> get users => _users;

  @override
  Future<void> init() async {
    if (!_userLocal.isEmpty) {
      for (HiveUser c in _userLocal.users) {
        _users[c.value.id] = HiveRxUser(this, _userLocal, c);
      }
      isReady.value = true;
    }

    _initLocalSubscription();
  }

  @override
  Future<void> clearCache() => _userLocal.clear();

  @override
  void dispose() {
    _localSubscription?.cancel();
  }

  @override
  SearchResult<UserId, RxUser> search({
    UserNum? num,
    UserName? name,
    UserLogin? login,
    ChatDirectLinkSlug? link,
  }) {
    if (num == null && name == null && login == null && link == null) {
      return SearchResultImpl();
    }

    Pagination<RxUser, UsersCursor, UserId>? pagination;
    if (name != null) {
      pagination = Pagination(
        perPage: 30,
        provider: GraphQlPageProvider(
          fetch: ({after, before, first, last}) {
            return searchByName(
              name,
              after: after,
              first: first,
            );
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

    print('users: $users');

    Map<UserId, RxUser> toMap(RxUser? u) {
      if (u != null) {
        return {u.id: u};
      }

      return {};
    }

    final SearchResultImpl<UserId, RxUser, UsersCursor> searchResult =
        SearchResultImpl(
      pagination: pagination,
      initial: [
        {for (var u in users) u.id: u},
        if (num != null) searchByNum(num).then(toMap),
        if (login != null) searchByLogin(login).then(toMap),
        if (link != null) searchByLink(link).then(toMap),
      ],
    );

    return searchResult;
  }

  @override
  Future<RxUser?> get(UserId id) {
    Mutex? mutex = _locks[id];
    if (mutex == null) {
      mutex = Mutex();
      _locks[id] = mutex;
    }

    return mutex.protect(() async {
      RxUser? user = _users[id];
      if (user == null) {
        var query = (await _graphQlProvider.getUser(id)).user;
        if (query != null) {
          HiveUser stored = query.toHive();
          put(stored);
          var fetched = HiveRxUser(this, _userLocal, stored);
          users[id] = fetched;
          user = fetched;
        }
      }

      return user;
    });
  }

  @override
  Future<void> blockUser(UserId id, BlocklistReason? reason) async {
    final RxUser? user = _users[id];
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
    final RxUser? user = _users[id];
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

  /// Updates the locally stored [HiveUser] with the provided [user] value.
  void update(User user) {
    HiveUser? hiveUser = _userLocal.get(user.id);
    if (hiveUser != null) {
      hiveUser.value = user;
      put(hiveUser, ignoreVersion: true);
    }
  }

  /// Puts the provided [user] into the local [Hive] storage.
  void put(HiveUser user, {bool ignoreVersion = false}) {
    _putUser(user, ignoreVersion: ignoreVersion);
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

  /// Returns a [Stream] of [UserEvent]s of the specified [User].
  Stream<UserEvents> userEvents(UserId id, UserVersion? Function() ver) {
    return _graphQlProvider.userEvents(id, ver).asyncExpand((event) async* {
      var events = UserEvents$Subscription.fromJson(event.data!).userEvents;
      if (events.$$typename == 'SubscriptionInitialized') {
        events as UserEvents$Subscription$UserEvents$SubscriptionInitialized;
        yield const UserEventsInitialized();
      } else if (events.$$typename == 'User') {
        var mixin = events as UserEvents$Subscription$UserEvents$User;
        yield UserEventsUser(mixin.toHive());
      } else if (events.$$typename == 'UserEventsVersioned') {
        var mixin = events as UserEventsVersionedMixin;
        yield UserEventsEvent(UserEventsVersioned(
          mixin.events.map((e) => _userEvent(e)).toList(),
          mixin.ver,
        ));
      } else if (events.$$typename == 'BlocklistEventsVersioned') {
        var mixin = events as BlocklistEventsVersionedMixin;
        yield UserEventsBlocklistEventsEvent(BlocklistEventsVersioned(
          mixin.events.map((e) => _blocklistEvent(e)).toList(),
          mixin.myVer,
        ));
      } else if (events.$$typename == 'isBlocked') {
        var node = events as UserEvents$Subscription$UserEvents$IsBlocked;
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
    var saved = _userLocal.get(user.value.id);

    if (saved == null ||
        saved.ver < user.ver ||
        saved.blacklistedVer < user.blacklistedVer ||
        ignoreVersion) {
      await _userLocal.put(user);
    }
  }

  /// Initializes [ContactHiveProvider.boxEvents] subscription.
  Future<void> _initLocalSubscription() async {
    _localSubscription = StreamIterator(_userLocal.boxEvents);
    while (await _localSubscription!.moveNext()) {
      BoxEvent event = _localSubscription!.current;
      if (event.deleted) {
        _users.remove(UserId(event.key));
      } else {
        RxUser? user = _users[UserId(event.key)];
        if (user == null) {
          _users[UserId(event.key)] = HiveRxUser(this, _userLocal, event.value);
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
    const maxInt = 120;
    var query = await _graphQlProvider.searchUsers(
      num: num,
      name: name,
      login: login,
      link: link,
      after: after,
      first: first ?? maxInt,
    );

    final List<HiveUser> result =
        query.searchUsers.edges.map((c) => c.node.toHive()).toList();

    for (HiveUser user in result) {
      put(user);
    }
    await Future.delayed(Duration.zero);

    Iterable<Future<RxUser?>> futures = result.map((e) => get(e.value.id));
    List<RxUser> users = (await Future.wait(futures)).whereNotNull().toList();

    return Page(
      RxList(users),
      query.searchUsers.pageInfo.toModel((c) => UsersCursor(c)),
    );
  }

  /// Constructs a [UserEvent] from the [UserEventsVersionedMixin$Events].
  UserEvent _userEvent(UserEventsVersionedMixin$Events e) {
    if (e.$$typename == 'EventUserAvatarDeleted') {
      var node = e as UserEventsVersionedMixin$Events$EventUserAvatarDeleted;
      return EventUserAvatarDeleted(node.userId, node.at);
    } else if (e.$$typename == 'EventUserAvatarUpdated') {
      var node = e as UserEventsVersionedMixin$Events$EventUserAvatarUpdated;
      return EventUserAvatarUpdated(
        node.userId,
        node.avatar.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventUserCallCoverDeleted') {
      var node = e as UserEventsVersionedMixin$Events$EventUserCallCoverDeleted;
      return EventUserCallCoverDeleted(node.userId, node.at);
    } else if (e.$$typename == 'EventUserCallCoverUpdated') {
      var node = e as UserEventsVersionedMixin$Events$EventUserCallCoverUpdated;
      return EventUserCallCoverUpdated(
        node.userId,
        node.callCover.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventUserCameOffline') {
      var node = e as UserEventsVersionedMixin$Events$EventUserCameOffline;
      return EventUserCameOffline(node.userId, node.at);
    } else if (e.$$typename == 'EventUserCameOnline') {
      var node = e as UserEventsVersionedMixin$Events$EventUserCameOnline;
      return EventUserCameOnline(node.userId);
    } else if (e.$$typename == 'EventUserDeleted') {
      var node = e as UserEventsVersionedMixin$Events$EventUserDeleted;
      return EventUserDeleted(node.userId, node.at);
    } else if (e.$$typename == 'EventUserNameDeleted') {
      var node = e as UserEventsVersionedMixin$Events$EventUserNameDeleted;
      return EventUserNameDeleted(node.userId, node.at);
    } else if (e.$$typename == 'EventUserNameUpdated') {
      var node = e as UserEventsVersionedMixin$Events$EventUserNameUpdated;
      return EventUserNameUpdated(node.userId, node.name, node.at);
    } else if (e.$$typename == 'EventUserPresenceUpdated') {
      var node = e as UserEventsVersionedMixin$Events$EventUserPresenceUpdated;
      return EventUserPresenceUpdated(node.userId, node.presence, node.at);
    } else if (e.$$typename == 'EventUserStatusDeleted') {
      var node = e as UserEventsVersionedMixin$Events$EventUserStatusDeleted;
      return EventUserStatusDeleted(node.userId, node.at);
    } else if (e.$$typename == 'EventUserStatusUpdated') {
      var node = e as UserEventsVersionedMixin$Events$EventUserStatusUpdated;
      return EventUserStatusUpdated(node.userId, node.status, node.at);
    } else {
      throw UnimplementedError('Unknown UserEvent: ${e.$$typename}');
    }
  }

  /// Constructs a [BlocklistEvent] from the
  /// [BlocklistEventsVersionedMixin$Events].
  BlocklistEvent _blocklistEvent(BlocklistEventsVersionedMixin$Events e) {
    if (e.$$typename == 'EventBlocklistRecordAdded') {
      var node =
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
