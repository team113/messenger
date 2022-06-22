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

import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/api/backend/extension/my_user.dart';
import '/api/backend/schema.dart';
import '/domain/model/avatar.dart';
import '/domain/model/crop_area.dart';
import '/domain/model/gallery_item.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/domain/repository/my_user.dart';
import '/provider/gql/exceptions.dart';
import '/provider/gql/graphql.dart';
import '/provider/hive/gallery_item.dart';
import '/provider/hive/my_user.dart';
import '/util/new_type.dart';
import 'event/my_user.dart';
import 'model/my_user.dart';

/// [MyUser] repository.
class MyUserRepository implements AbstractMyUserRepository {
  MyUserRepository(
    this._graphQlProvider,
    this._myUserLocal,
    this._galleryItemLocal,
  );

  @override
  late final Rx<MyUser?> myUser;

  /// GraphQL's Endpoint provider.
  final GraphQlProvider _graphQlProvider;

  /// [MyUser] local [Hive] storage.
  final MyUserHiveProvider _myUserLocal;

  /// `ImageGalleryItem` local [Hive] storage.
  final GalleryItemHiveProvider _galleryItemLocal;

  /// [MyUserHiveProvider.boxEvents] subscription.
  StreamIterator? _localSubscription;

  /// [_myUserRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamIterator? _remoteSubscription;

  /// [GraphQlProvider.keepOnline] subscription keeping the [MyUser] online.
  StreamSubscription? _keepOnlineSubscription;

  /// Callback that is called when [MyUser] is deleted.
  late final void Function() onUserDeleted;

  /// Callback that is called when [MyUser]'s password is changed.
  late final void Function() onPasswordUpdated;

  @override
  Future<void> init({
    required Function() onUserDeleted,
    required Function() onPasswordUpdated,
  }) async {
    this.onPasswordUpdated = onPasswordUpdated;
    this.onUserDeleted = onUserDeleted;

    myUser = Rx<MyUser?>(_myUserLocal.myUser?.value);
    _initLocalSubscription();
    _initRemoteSubscription();
    _initKeepOnlineSubscription();
  }

  @override
  void dispose() {
    _localSubscription?.cancel();
    _remoteSubscription?.cancel();
    _keepOnlineSubscription?.cancel();
  }

  @override
  Future<void> clearCache() => _myUserLocal.clear();

  @override
  Future<void> updateUserName(UserName? name) =>
      _graphQlProvider.updateUserName(name);

  @override
  Future<void> updateUserBio(UserBio? bio) =>
      _graphQlProvider.updateUserBio(bio);

  @override
  Future<void> updateUserLogin(UserLogin login) =>
      _graphQlProvider.updateUserLogin(login);

  @override
  Future<void> updateUserPresence(Presence presence) =>
      _graphQlProvider.updateUserPresence(presence);

  @override
  Future<void> updateUserPassword(
    UserPassword? oldPassword,
    UserPassword newPassword,
  ) =>
      _graphQlProvider.updateUserPassword(oldPassword, newPassword);

  @override
  Future<void> deleteMyUser() => _graphQlProvider.deleteMyUser();

  @override
  Future<void> deleteUserEmail(UserEmail email) =>
      _graphQlProvider.deleteUserEmail(email);

  @override
  Future<void> deleteUserPhone(UserPhone phone) =>
      _graphQlProvider.deleteUserPhone(phone);

  @override
  Future<void> addUserEmail(UserEmail email) =>
      _graphQlProvider.addUserEmail(email);

  @override
  Future<void> addUserPhone(UserPhone phone) =>
      _graphQlProvider.addUserPhone(phone);

  @override
  Future<void> confirmEmailCode(ConfirmationCode code) =>
      _graphQlProvider.confirmEmailCode(code);

  @override
  Future<void> confirmPhoneCode(ConfirmationCode code) =>
      _graphQlProvider.confirmPhoneCode(code);

  @override
  Future<void> resendEmail() => _graphQlProvider.resendEmail();

  @override
  Future<void> resendPhone() => _graphQlProvider.resendPhone();

  @override
  Future<void> createChatDirectLink(ChatDirectLinkSlug slug) =>
      _graphQlProvider.createUserDirectLink(slug);

  @override
  Future<void> deleteChatDirectLink() =>
      _graphQlProvider.deleteUserDirectLink();

  @override
  Future<void> uploadGalleryItem(
    NativeFile file, {
    void Function(int count, int total)? onSendProgress,
  }) async {
    dio.MultipartFile upload;

    if (file.stream != null) {
      upload = dio.MultipartFile(
        file.stream!,
        file.size,
        filename: file.name,
        contentType: file.mime,
      );
    } else if (file.bytes != null) {
      upload = dio.MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
        contentType: file.mime,
      );
    } else if (file.path != null) {
      upload = await dio.MultipartFile.fromFile(
        file.path!,
        filename: file.name,
        contentType: file.mime,
      );
    } else {
      throw ArgumentError(
        'At least stream, bytes or path should be specified.',
      );
    }

    await _graphQlProvider.uploadUserGalleryItem(
      upload,
      onSendProgress: onSendProgress,
    );
  }

  @override
  Future<void> deleteGalleryItem(GalleryItemId id) =>
      _graphQlProvider.deleteUserGalleryItem(id);

  @override
  Future<void> updateAvatar(GalleryItemId? id) =>
      _graphQlProvider.updateUserAvatar(id, null);

  @override
  Future<void> updateCallCover(GalleryItemId? id) =>
      _graphQlProvider.updateUserCallCover(id, null);

  /// Initializes [MyUserHiveProvider.boxEvents] subscription.
  Future<void> _initLocalSubscription() async {
    _localSubscription = StreamIterator(_myUserLocal.boxEvents);
    while (await _localSubscription!.moveNext()) {
      BoxEvent event = _localSubscription!.current;
      if (event.deleted) {
        myUser.value = null;
        _remoteSubscription?.cancel();
      } else {
        myUser.value = event.value?.value;

        // Refresh the value since [event.value] is the same [MyUser] stored in
        // [_myUser] (so `==` operator fails to distinguish them).
        myUser.refresh();
      }
    }
  }

  /// Initializes [_myUserRemoteEvents] subscription.
  Future<void> _initRemoteSubscription({bool noVersion = false}) async {
    _remoteSubscription?.cancel();
    _remoteSubscription = StreamIterator(
        await _myUserRemoteEvents(noVersion ? null : _myUserLocal.myUser?.ver));

    while (await _remoteSubscription!
        .moveNext()
        .onError<ResubscriptionRequiredException>((_, __) {
      _initRemoteSubscription();
      return false;
    }).onError<StaleVersionException>((_, __) {
      _initRemoteSubscription(noVersion: true);
      return false;
    })) {
      _myUserRemoteEvent(_remoteSubscription!.current);
    }
  }

  /// Initializes the [GraphQlProvider.keepOnline] subscription.
  Future<void> _initKeepOnlineSubscription() async {
    _keepOnlineSubscription?.cancel();
    _keepOnlineSubscription = (await _graphQlProvider.keepOnline()).listen(
      (_) {
        // No-op.
      },
      onError: (e) {
        if (e is ResubscriptionRequiredException) {
          _initKeepOnlineSubscription();
        } else {
          throw e;
        }
      },
    );
  }

  /// Saves the provided [user] in [Hive].
  void _setMyUser(HiveMyUser user) {
    if (user.ver > _myUserLocal.myUser?.ver) {
      _myUserLocal.set(user);
      user.value.gallery?.forEach(_galleryItemLocal.put);
    }
  }

  /// Handles [MyUserEvent] from the [_myUserRemoteEvents] subscription.
  Future<void> _myUserRemoteEvent(MyUserEventsVersioned versioned) async {
    var userEntity = _myUserLocal.myUser;

    if (userEntity == null || versioned.ver <= userEntity.ver) {
      return;
    }
    userEntity.ver = versioned.ver;

    for (var event in versioned.events) {
      switch (event.kind) {
        case MyUserEventKind.nameUpdated:
          event as EventUserNameUpdated;
          userEntity.value.name = event.name;
          break;

        case MyUserEventKind.nameDeleted:
          event as EventUserNameDeleted;
          userEntity.value.name = null;
          break;

        case MyUserEventKind.bioUpdated:
          event as EventUserBioUpdated;
          userEntity.value.bio = event.bio;
          break;

        case MyUserEventKind.bioDeleted:
          event as EventUserBioDeleted;
          userEntity.value.bio = null;
          break;

        case MyUserEventKind.avatarUpdated:
          event as EventUserAvatarUpdated;
          userEntity.value.avatar = event.avatar;
          break;

        case MyUserEventKind.avatarDeleted:
          event as EventUserAvatarDeleted;
          userEntity.value.avatar = null;
          break;

        case MyUserEventKind.callCoverUpdated:
          event as EventUserCallCoverUpdated;
          userEntity.value.callCover = event.callCover;
          break;

        case MyUserEventKind.callCoverDeleted:
          event as EventUserCallCoverDeleted;
          userEntity.value.callCover = null;
          break;

        case MyUserEventKind.galleryItemAdded:
          event as EventUserGalleryItemAdded;
          userEntity.value.gallery ??= [];
          userEntity.value.gallery?.insert(0, event.galleryItem);
          _galleryItemLocal.put(event.galleryItem);
          break;

        case MyUserEventKind.galleryItemDeleted:
          event as EventUserGalleryItemDeleted;
          userEntity.value.gallery
              ?.removeWhere((e) => e.id == event.galleryItemId);
          _galleryItemLocal.remove(event.galleryItemId);
          break;

        case MyUserEventKind.presenceUpdated:
          event as EventUserPresenceUpdated;
          userEntity.value.presence = event.presence;
          break;

        case MyUserEventKind.statusUpdated:
          event as EventUserStatusUpdated;
          userEntity.value.status = event.status;
          break;

        case MyUserEventKind.statusDeleted:
          event as EventUserStatusDeleted;
          userEntity.value.status = null;
          break;

        case MyUserEventKind.loginUpdated:
          event as EventUserLoginUpdated;
          userEntity.value.login = event.login;
          break;

        case MyUserEventKind.emailAdded:
          event as EventUserEmailAdded;
          userEntity.value.emails.unconfirmed = event.email;
          break;

        case MyUserEventKind.emailConfirmed:
          event as EventUserEmailConfirmed;
          userEntity.value.emails.confirmed.addIf(
            !userEntity.value.emails.confirmed.contains(event.email),
            event.email,
          );
          if (userEntity.value.emails.unconfirmed == event.email) {
            userEntity.value.emails.unconfirmed = null;
          }
          break;

        case MyUserEventKind.emailDeleted:
          event as EventUserEmailDeleted;
          if (userEntity.value.emails.unconfirmed == event.email) {
            userEntity.value.emails.unconfirmed = null;
          }
          userEntity.value.emails.confirmed
              .removeWhere((element) => element == event.email);
          break;

        case MyUserEventKind.phoneAdded:
          event as EventUserPhoneAdded;
          userEntity.value.phones.unconfirmed = event.phone;
          break;

        case MyUserEventKind.phoneConfirmed:
          event as EventUserPhoneConfirmed;
          userEntity.value.phones.confirmed.addIf(
            !userEntity.value.phones.confirmed.contains(event.phone),
            event.phone,
          );
          if (userEntity.value.phones.unconfirmed == event.phone) {
            userEntity.value.phones.unconfirmed = null;
          }
          break;

        case MyUserEventKind.phoneDeleted:
          event as EventUserPhoneDeleted;
          if (userEntity.value.phones.unconfirmed == event.phone) {
            userEntity.value.phones.unconfirmed = null;
          }
          userEntity.value.phones.confirmed
              .removeWhere((element) => element == event.phone);
          break;

        case MyUserEventKind.passwordUpdated:
          event as EventUserPasswordUpdated;
          userEntity.value.hasPassword = true;
          onPasswordUpdated();
          break;

        case MyUserEventKind.userMuted:
          event as EventUserMuted;
          userEntity.value.muted = event.until;
          break;

        case MyUserEventKind.unmuted:
          event as EventUserUnmuted;
          userEntity.value.muted = null;
          break;

        case MyUserEventKind.cameOnline:
          event as EventUserCameOnline;
          userEntity.value.online = true;
          break;

        case MyUserEventKind.cameOffline:
          event as EventUserCameOffline;
          userEntity.value.online = false;
          break;

        case MyUserEventKind.unreadChatsCountUpdated:
          event as EventUserUnreadChatsCountUpdated;
          userEntity.value.unreadChatsCount = event.count;
          break;

        case MyUserEventKind.deleted:
          event as EventUserDeleted;
          onUserDeleted();
          break;

        case MyUserEventKind.directLinkDeleted:
          event as EventUserDirectLinkDeleted;
          userEntity.value.chatDirectLink = null;
          break;

        case MyUserEventKind.directLinkUpdated:
          event as EventUserDirectLinkUpdated;
          userEntity.value.chatDirectLink = event.directLink;
          break;
      }
    }

    _myUserLocal.set(userEntity);
  }

  /// Subscribes to remote [MyUserEvent]s of the authenticated [MyUser].
  Future<Stream<MyUserEventsVersioned>> _myUserRemoteEvents(
    MyUserVersion? ver,
  ) async =>
      (await _graphQlProvider.myUserEvents(ver)).asyncExpand((event) async* {
        GraphQlProviderExceptions.fire(event);
        var events =
            MyUserEvents$Subscription.fromJson(event.data!).myUserEvents;

        if (events.$$typename == 'SubscriptionInitialized') {
          events
              as MyUserEvents$Subscription$MyUserEvents$SubscriptionInitialized;
          // No-op.
        } else if (events.$$typename == 'MyUser') {
          _setMyUser((events as MyUserMixin).toHive());
        } else if (events.$$typename == 'MyUserEventsVersioned') {
          var mixin = events as MyUserEventsVersionedMixin;
          yield MyUserEventsVersioned(
            mixin.events.map((e) => _myUserEvent(e)).toList(),
            mixin.ver,
          );
        }
      });

  /// Constructs a [MyUserEvent] from the [MyUserEventsVersionedMixin$Event].
  MyUserEvent _myUserEvent(MyUserEventsVersionedMixin$Events e) {
    if (e.$$typename == 'EventUserNameUpdated') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserNameUpdated;
      return EventUserNameUpdated(node.userId, node.name);
    } else if (e.$$typename == 'EventUserNameDeleted') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserNameDeleted;
      return EventUserNameDeleted(node.userId);
    } else if (e.$$typename == 'EventUserBioUpdated') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserBioUpdated;
      return EventUserBioUpdated(node.userId, node.bio);
    } else if (e.$$typename == 'EventUserBioDeleted') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserBioDeleted;
      return EventUserBioDeleted(node.userId);
    } else if (e.$$typename == 'EventUserAvatarUpdated') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserAvatarUpdated;
      return EventUserAvatarUpdated(
        node.userId,
        UserAvatar(
            full: node.avatar.full,
            original: node.avatar.original,
            galleryItemId: node.avatar.galleryItemId,
            big: node.avatar.big,
            medium: node.avatar.medium,
            small: node.avatar.small,
            crop: node.avatar.crop != null
                ? CropArea(
                    topLeft: CropPoint(
                      x: node.avatar.crop!.topLeft.x,
                      y: node.avatar.crop!.topLeft.y,
                    ),
                    bottomRight: CropPoint(
                      x: node.avatar.crop!.bottomRight.x,
                      y: node.avatar.crop!.bottomRight.y,
                    ),
                    angle: node.avatar.crop?.angle,
                  )
                : null),
      );
    } else if (e.$$typename == 'EventUserAvatarDeleted') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserAvatarDeleted;
      return EventUserAvatarDeleted(node.userId);
    } else if (e.$$typename == 'EventUserCallCoverUpdated') {
      var node =
          e as MyUserEventsVersionedMixin$Events$EventUserCallCoverUpdated;
      return EventUserCallCoverUpdated(
        node.userId,
        UserCallCover(
            galleryItemId: node.callCover.galleryItemId,
            full: node.callCover.full,
            original: node.callCover.original,
            vertical: node.callCover.vertical,
            square: node.callCover.square,
            crop: node.callCover.crop != null
                ? CropArea(
                    topLeft: CropPoint(
                      x: node.callCover.crop!.topLeft.x,
                      y: node.callCover.crop!.topLeft.y,
                    ),
                    bottomRight: CropPoint(
                      x: node.callCover.crop!.bottomRight.x,
                      y: node.callCover.crop!.bottomRight.y,
                    ),
                    angle: node.callCover.crop?.angle,
                  )
                : null),
      );
    } else if (e.$$typename == 'EventUserCallCoverDeleted') {
      var node =
          e as MyUserEventsVersionedMixin$Events$EventUserCallCoverDeleted;
      return EventUserCallCoverDeleted(node.userId);
    } else if (e.$$typename == 'EventUserGalleryItemAdded') {
      var node =
          e as MyUserEventsVersionedMixin$Events$EventUserGalleryItemAdded;
      var image = node.galleryItem
          as MyUserEventsVersionedMixin$Events$EventUserGalleryItemAdded$GalleryItem$ImageGalleryItem;
      return EventUserGalleryItemAdded(
        node.userId,
        ImageGalleryItem(
          original: Original(image.original),
          square: Square(image.square),
          id: image.id,
          addedAt: image.addedAt,
        ),
      );
    } else if (e.$$typename == 'EventUserGalleryItemDeleted') {
      var node =
          e as MyUserEventsVersionedMixin$Events$EventUserGalleryItemDeleted;
      return EventUserGalleryItemDeleted(node.userId, node.galleryItemId);
    } else if (e.$$typename == 'EventUserPresenceUpdated') {
      var node =
          e as MyUserEventsVersionedMixin$Events$EventUserPresenceUpdated;
      return EventUserPresenceUpdated(node.userId, node.presence);
    } else if (e.$$typename == 'EventUserStatusUpdated') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserStatusUpdated;
      return EventUserStatusUpdated(node.userId, node.status);
    } else if (e.$$typename == 'EventUserStatusDeleted') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserStatusDeleted;
      return EventUserStatusDeleted(node.userId);
    } else if (e.$$typename == 'EventUserLoginUpdated') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserLoginUpdated;
      return EventUserLoginUpdated(node.userId, node.login);
    } else if (e.$$typename == 'EventUserEmailAdded') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserEmailAdded;
      return EventUserEmailAdded(node.userId, node.email);
    } else if (e.$$typename == 'EventUserEmailConfirmed') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserEmailConfirmed;
      return EventUserEmailConfirmed(node.userId, node.email);
    } else if (e.$$typename == 'EventUserEmailDeleted') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserEmailDeleted;
      return EventUserEmailDeleted(node.userId, node.email);
    } else if (e.$$typename == 'EventUserPhoneAdded') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserPhoneAdded;
      return EventUserPhoneAdded(node.userId, node.phone);
    } else if (e.$$typename == 'EventUserPhoneConfirmed') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserPhoneConfirmed;
      return EventUserPhoneConfirmed(node.userId, node.phone);
    } else if (e.$$typename == 'EventUserPhoneDeleted') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserPhoneDeleted;
      return EventUserPhoneDeleted(node.userId, node.phone);
    } else if (e.$$typename == 'EventUserPasswordUpdated') {
      var node =
          e as MyUserEventsVersionedMixin$Events$EventUserPasswordUpdated;
      return EventUserPasswordUpdated(node.userId);
    } else if (e.$$typename == 'EventUserMuted') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserMuted;
      return EventUserMuted(
        node.userId,
        node.until.$$typename == 'MuteForeverDuration'
            ? MuteDuration.forever()
            : MuteDuration.until((node.until
                    as MyUserEventsVersionedMixin$Events$EventUserMuted$Until$MuteUntilDuration)
                .until),
      );
    } else if (e.$$typename == 'EventUserCameOffline') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserCameOffline;
      return EventUserCameOffline(node.userId);
    } else if (e.$$typename == 'EventUserUnreadChatsCountUpdated') {
      var node = e
          as MyUserEventsVersionedMixin$Events$EventUserUnreadChatsCountUpdated;
      return EventUserUnreadChatsCountUpdated(node.userId, node.count);
    } else if (e.$$typename == 'EventUserDirectLinkUpdated') {
      var node =
          e as MyUserEventsVersionedMixin$Events$EventUserDirectLinkUpdated;
      return EventUserDirectLinkUpdated(
        node.userId,
        ChatDirectLink(
          slug: node.directLink.slug,
          usageCount: node.directLink.usageCount,
        ),
      );
    } else if (e.$$typename == 'EventUserDirectLinkDeleted') {
      var node =
          e as MyUserEventsVersionedMixin$Events$EventUserDirectLinkDeleted;
      return EventUserDirectLinkDeleted(node.userId);
    } else if (e.$$typename == 'EventUserDeleted') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserDeleted;
      return EventUserDeleted(node.userId);
    } else if (e.$$typename == 'EventUserUnmuted') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserUnmuted;
      return EventUserUnmuted(node.userId);
    } else if (e.$$typename == 'EventUserCameOnline') {
      var node = e as MyUserEventsVersionedMixin$Events$EventUserCameOnline;
      return EventUserCameOffline(node.userId);
    } else {
      throw UnimplementedError('Unknown MyUserEvent: ${e.$$typename}');
    }
  }
}
