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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/api/backend/schema.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/provider/gql/graphql.dart';
import '/provider/hive/gallery_item.dart';
import '/provider/hive/user.dart';
import '/util/new_type.dart';

/// Implementation of an [AbstractUserRepository].
class UserRepository implements AbstractUserRepository {
  UserRepository(
    this._graphQlProvider,
    this._userLocal,
    this._galleryItemLocal,
  );

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [User]s local [Hive] storage.
  final UserHiveProvider _userLocal;

  /// [ImageGalleryItem] local [Hive] storage.
  final GalleryItemHiveProvider _galleryItemLocal;

  /// [isReady] value.
  final RxBool _isReady = RxBool(false);

  /// [users] value.
  final RxMap<UserId, Rx<User>> _users = RxMap<UserId, Rx<User>>();

  /// [UserHiveProvider.boxEvents] subscription.
  StreamIterator? _localSubscription;

  @override
  RxBool get isReady => _isReady;

  @override
  RxMap<UserId, Rx<User>> get users => RxMap.unmodifiable(_users);

  @override
  Future<void> init() async {
    if (!_userLocal.isEmpty) {
      for (HiveUser c in _userLocal.users) {
        _users[c.value.id] = Rx<User>(c.value);
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
  Future<List<Rx<User>>> searchByNum(UserNum num) => _search(num: num);

  @override
  Future<List<Rx<User>>> searchByLogin(UserLogin login) =>
      _search(login: login);

  @override
  Future<List<Rx<User>>> searchByName(UserName name) => _search(name: name);

  @override
  Future<List<Rx<User>>> searchByLink(ChatDirectLinkSlug link) =>
      _search(link: link);

  @override
  Future<Rx<User>?> get(UserId id) async {
    Rx<User>? user = _users[id];
    if (user == null) {
      var query = (await _graphQlProvider.getUser(id)).user;
      if (query != null) {
        HiveUser stored = HiveUser(
          _user(query),
          query.ver,
          query.isBlacklisted.ver,
        );
        put(stored);
        var fetched = Rx<User>(stored.value);
        users[id] = fetched;
        user = fetched;
      }
    }

    return user;
  }

  /// Puts the provided [user] into the local [Hive] storage.
  void put(HiveUser user) {
    List<ImageGalleryItem> gallery = user.value.gallery ?? [];
    for (ImageGalleryItem item in gallery) {
      _galleryItemLocal.put(item);
    }
    _putUser(user);
  }

  /// Puts the provided [user] to [Hive].
  Future<void> _putUser(HiveUser user) async {
    var saved = _userLocal.get(user.value.id);
    if (saved == null || saved.ver < user.ver) {
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
        Rx<User>? user = _users[UserId(event.key)];
        if (user == null) {
          _users[UserId(event.key)] = Rx<User>(event.value.value);
        } else {
          user.value = event.value.value;
          user.refresh();
        }
      }
    }
  }

  // TODO: Search in the local storage.
  /// Searches [User]s by the given criteria.
  ///
  /// Exactly one of [num]/[login]/[link]/[name] arguments must be specified
  /// (be non-`null`).
  Future<List<Rx<User>>> _search({
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
        .map((c) => HiveUser(
              _user(c),
              c.ver,
              c.isBlacklisted.ver,
            ))
        .toList();

    for (HiveUser user in result) {
      put(user);
    }
    await Future.delayed(Duration.zero);

    Iterable<Future<Rx<User>?>> futures = result.map((e) => get(e.value.id));
    List<Rx<User>> rxUsers =
        (await Future.wait(futures)).whereNotNull().toList();

    return rxUsers;
  }

  /// Constructs a new [User] from the given [UserMixin].
  User _user(UserMixin u) => User(
        u.id,
        u.num,
        name: u.name,
        bio: u.bio,
        avatar: u.avatar == null
            ? null
            : UserAvatar(
                galleryItemId: u.avatar!.galleryItemId,
                full: u.avatar!.full,
                big: u.avatar!.big,
                medium: u.avatar!.medium,
                small: u.avatar!.small,
                original: u.avatar!.original,
              ),
        callCover: u.callCover == null
            ? null
            : UserCallCover(
                galleryItemId: u.callCover!.galleryItemId,
                full: u.callCover!.full,
                vertical: u.callCover!.vertical,
                square: u.callCover!.square,
                original: u.callCover!.original,
              ),
        gallery: u.gallery.nodes.map((e) {
          var imageData = e as UserMixin$Gallery$Nodes$ImageGalleryItem;
          return ImageGalleryItem(
            original: Original(imageData.original),
            square: Square(imageData.square),
            id: imageData.id,
            addedAt: imageData.addedAt,
          );
        }).toList(),
        mutualContactsCount: u.mutualContactsCount,
        online: u.online?.$$typename == 'UserOnline',
        lastSeenAt: u.online?.$$typename == 'UserOffline'
            ? (u.online as UserMixin$Online$UserOffline).lastSeenAt
            : null,
        dialog: u.dialog == null ? null : Chat(u.dialog!.id),
        presenceIndex: u.presence.index,
        status: u.status,
        isDeleted: u.isDeleted,
        isBlacklisted: u.isBlacklisted.blacklisted,
      );
}
