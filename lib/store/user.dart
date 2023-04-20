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

import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/provider/gql/graphql.dart';
import '/provider/hive/gallery_item.dart';
import '/provider/hive/user.dart';
import '/store/event/user.dart';
import '/store/model/user.dart';
import '/store/user_rx.dart';
import '/util/new_type.dart';
import 'event/my_user.dart'
    show BlacklistEvent, EventBlacklistRecordAdded, EventBlacklistRecordRemoved;

/// Implementation of an [AbstractUserRepository].
class UserRepository implements AbstractUserRepository {
  UserRepository(
    this._graphQlProvider,
    this._userLocal,
    this._galleryItemLocal,
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

  /// [ImageGalleryItem] local [Hive] storage.
  final GalleryItemHiveProvider _galleryItemLocal;

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
  Future<void> blacklistUser(UserId id, BlacklistReason? reason) async {
    final RxUser? user = _users[id];
    final BlacklistRecord? record = user?.user.value.isBlacklisted;

    if (user?.user.value.isBlacklisted == null) {
      user?.user.value.isBlacklisted = BlacklistRecord(
        reason: reason,
        at: PreciseDateTime.now().toUtc(),
      );
      user?.user.refresh();
    }

    try {
      await _graphQlProvider.blacklistUser(id, reason);
    } catch (_) {
      if (user != null && user.user.value.isBlacklisted != record) {
        user.user.value.isBlacklisted = record ?? user.user.value.isBlacklisted;
        user.user.refresh();
      }
      rethrow;
    }
  }

  @override
  Future<void> unblacklistUser(UserId id) async {
    final RxUser? user = _users[id];
    final BlacklistRecord? record = user?.user.value.isBlacklisted;

    if (user?.user.value.isBlacklisted != null) {
      user?.user.value.isBlacklisted = null;
      user?.user.refresh();
    }

    try {
      await _graphQlProvider.unblacklistUser(id);
    } catch (_) {
      if (user != null && user.user.value.isBlacklisted != record) {
        user.user.value.isBlacklisted = record ?? user.user.value.isBlacklisted;
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
    List<ImageGalleryItem> gallery = user.value.gallery ?? [];
    for (ImageGalleryItem item in gallery) {
      _galleryItemLocal.put(item);
    }
    _putUser(user, ignoreVersion: ignoreVersion);
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
        yield UserEventsUser(mixin.toHive());
      } else if (events.$$typename == 'UserEventsVersioned') {
        var mixin = events as UserEventsVersionedMixin;
        yield UserEventsEvent(UserEventsVersioned(
          mixin.events.map((e) => _userEvent(e)).toList(),
          mixin.ver,
        ));
      } else if (events.$$typename == 'BlacklistEventsVersioned') {
        var mixin = events as BlacklistEventsVersionedMixin;
        yield UserEventsBlacklistEventsEvent(BlacklistEventsVersioned(
          mixin.events.map((e) => _blacklistEvent(e)).toList(),
          mixin.myVer,
        ));
      } else if (events.$$typename == 'IsBlacklisted') {
        var node = events as UserEvents$Subscription$UserEvents$IsBlacklisted;
        yield UserEventsIsBlacklisted(
          node.record == null
              ? null
              : BlacklistRecord(
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
  Future<List<RxUser>> _search({
    UserNum? num,
    UserName? name,
    UserLogin? login,
    ChatDirectLinkSlug? link,
  }) async {
    const maxInt = 120;
    List<HiveUser> result = (await _graphQlProvider.searchUsers(
      first: maxInt,
      num: num,
      name: name,
      login: login,
      link: link,
    ))
        .searchUsers
        .nodes
        .map((c) => c.toHive())
        .toList();

    for (HiveUser user in result) {
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
    } else if (e.$$typename == 'EventUserBioDeleted') {
      var node = e as UserEventsVersionedMixin$Events$EventUserBioDeleted;
      return EventUserBioDeleted(node.userId, node.at);
    } else if (e.$$typename == 'EventUserBioUpdated') {
      var node = e as UserEventsVersionedMixin$Events$EventUserBioUpdated;
      return EventUserBioUpdated(node.userId, node.bio, node.at);
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
    } else if (e.$$typename == 'EventUserGalleryItemAdded') {
      var node = e as UserEventsVersionedMixin$Events$EventUserGalleryItemAdded;
      return EventUserGalleryItemAdded(
        node.userId,
        node.galleryItem.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventUserGalleryItemDeleted') {
      var node =
          e as UserEventsVersionedMixin$Events$EventUserGalleryItemDeleted;
      return EventUserGalleryItemDeleted(
        node.userId,
        node.galleryItemId,
        node.at,
      );
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

  /// Constructs a [BlacklistEvent] from the
  /// [BlacklistEventsVersionedMixin$Events].
  BlacklistEvent _blacklistEvent(BlacklistEventsVersionedMixin$Events e) {
    if (e.$$typename == 'EventBlacklistRecordAdded') {
      return EventBlacklistRecordAdded(
        e.userId,
        e.user.toHive(),
        e.at,
      );
    } else if (e.$$typename == 'EventBlacklistRecordRemoved') {
      return EventBlacklistRecordRemoved(
        e.userId,
        e.user.toHive(),
        e.at,
      );
    } else {
      throw UnimplementedError('Unknown UserEvent: ${e.$$typename}');
    }
  }
}
