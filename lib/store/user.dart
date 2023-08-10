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
import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';

import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/provider/gql/graphql.dart';
import '/provider/isar/user.dart';
import '/store/event/user.dart';
import '/store/model/user.dart';
import '/store/user_rx.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import 'event/my_user.dart'
    show BlocklistEvent, EventBlocklistRecordAdded, EventBlocklistRecordRemoved;

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

  /// [Isar] instance used to start write transaction.
  final UserIsarProvider _userLocal;

  /// [isReady] value.
  final RxBool _isReady = RxBool(false);

  /// [users] value.
  final RxMap<UserId, RxUser> _users = RxMap<UserId, RxUser>();

  /// [Mutex]es guarding access to the [get] method.
  final Map<UserId, Mutex> _locks = {};

  /// Subscription for the [_userLocal] changes.
  StreamIterator<ListChangeNotification<IsarUser>>? _localSubscription;

  @override
  RxBool get isReady => _isReady;

  @override
  RxMap<UserId, RxUser> get users => _users;

  @override
  Future<void> init() async {
    if (_userLocal.count > 0) {
      for (IsarUser c in await _userLocal.users) {
        _users[c.value.id] = IsarRxUser(this, _userLocal, c);
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
  Future<List<RxUser>> searchByNum(UserNum num) => _search(num: num);

  @override
  Future<List<RxUser>> searchByLogin(UserLogin login) => _search(login: login);

  @override
  Future<List<RxUser>> searchByName(UserName name) => _search(name: name);

  @override
  Future<List<RxUser>> searchByLink(ChatDirectLinkSlug link) =>
      _search(link: link);

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
          IsarUser stored = query.toIsar();
          put(stored);
          var fetched = IsarRxUser(this, _userLocal, stored);
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

  /// Updates the locally stored [IsarUser] with the provided [user] value.
  void update(User user) {
    IsarUser? isarUser = _userLocal.get(user.id.val);
    if (isarUser != null) {
      isarUser.value = user;
      put(isarUser, ignoreVersion: true);
    }
  }

  /// Puts the provided [user] into the local [Isar] storage.
  Future<void> put(IsarUser user, {bool ignoreVersion = false}) async {
    var saved = _userLocal.get(user.value.id.val);

    if (saved == null ||
        saved.ver < user.ver ||
        saved.blacklistedVer < user.blacklistedVer ||
        ignoreVersion) {
      await _userLocal.put(user);
    }
  }

  /// Returns a [Stream] of [UserEvent]s of the specified [User].
  Stream<UserEvents> userEvents(UserId id, UserVersion? Function() ver) {
    return _graphQlProvider.userEvents(id, ver).asyncExpand((event) async* {
      var events = UserEvents$Subscription.fromJson(event.data!).userEvents;
      if (events.$$typename == 'SubscriptionInitialized') {
        events as UserEvents$Subscription$UserEvents$SubscriptionInitialized;
        yield const UserEventsInitialized();
      } else if (events.$$typename == 'User') {
        var mixin = events as UserEvents$Subscription$UserEvents$User;
        yield UserEventsUser(mixin.toIsar());
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

  /// Initializes subscription for the [_userLocal] changes.
  Future<void> _initLocalSubscription() async {
    void add(IsarUser user) {
      RxUser? rxUser = _users[user.value.id];
      if (rxUser == null) {
        _users[user.value.id] = IsarRxUser(this, _userLocal, user);
      } else {
        rxUser.user.value = user.value;
        rxUser.user.refresh();
      }
    }

    _localSubscription = StreamIterator(_userLocal.watch());
    while (await _localSubscription!.moveNext()) {
      final ListChangeNotification<IsarUser> event =
          _localSubscription!.current;

      switch (event.op) {
        case OperationKind.added:
          add(event.element);
          break;

        case OperationKind.removed:
          _users.remove(event.element.value.id);
          break;

        case OperationKind.updated:
          add(event.element);
          break;
      }
    }
  }

  /// Searches [User]s by the given criteria.
  ///
  /// Exactly one of [num]/[login]/[link]/[name] arguments must be specified
  /// (be non-`null`).
  Future<List<RxUser>> _search({
    UserNum? num,
    UserName? name,
    UserLogin? login,
    ChatDirectLinkSlug? link,
  }) async {
    const maxInt = 120;
    List<IsarUser> result = (await _graphQlProvider.searchUsers(
      first: maxInt,
      num: num,
      name: name,
      login: login,
      link: link,
    ))
        .searchUsers
        .nodes
        .map((c) => c.toIsar())
        .toList();

    for (IsarUser user in result) {
      put(user);
    }
    await Future.delayed(Duration.zero);

    Iterable<Future<RxUser?>> futures = result.map((e) => get(e.value.id));
    List<RxUser> users = (await Future.wait(futures)).whereNotNull().toList();

    return users;
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
        e.user.toIsar(),
        e.at,
        node.reason,
      );
    } else if (e.$$typename == 'EventBlocklistRecordRemoved') {
      return EventBlocklistRecordRemoved(e.user.toIsar(), e.at);
    } else {
      throw UnimplementedError('Unknown BlocklistEvent: ${e.$$typename}');
    }
  }
}
