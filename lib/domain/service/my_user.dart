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
import 'package:mutex/mutex.dart';

import '../model/my_user.dart';
import '../model/user.dart';
import '../repository/my_user.dart';
import '/api/backend/schema.dart' show Presence;
import '/domain/model/gallery_item.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/native_file.dart';
import '/domain/repository/user.dart';
import '/routes.dart';
import 'auth.dart';
import 'disposable_service.dart';

/// Service responsible for [MyUser] management.
class MyUserService extends DisposableService {
  MyUserService(this._auth, this._userRepo);

  /// Authentication service providing the authentication capabilities.
  final AuthService _auth;

  /// Repository responsible for storing [MyUser].
  final AbstractMyUserRepository _userRepo;

  /// Mutex guarding [updateUserPassword] mutation and `onPasswordUpdated`
  /// logic.
  final Mutex _passwordChangeGuard = Mutex();

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _userRepo.myUser;

  /// Returns [User]s blacklisted by the authenticated [MyUser].
  RxList<RxUser> get blacklist => _userRepo.blacklist;

  @override
  void onInit() {
    assert(_auth.initialized);
    _userRepo.init(
      onPasswordUpdated: _onPasswordUpdated,
      onUserDeleted: _onUserDeleted,
    );
    super.onInit();
  }

  @override
  void onClose() {
    _userRepo.dispose();
    super.onClose();
  }

  /// Updates [MyUser.name] field for the authenticated [MyUser].
  ///
  /// If [name] is `null`, then resets [MyUser.name] field.
  Future<void> updateUserName(UserName? name) => _userRepo.updateUserName(name);

  /// Updates [MyUser.login] field for the authenticated [MyUser].
  ///
  /// Throws [UpdateUserLoginException].
  Future<void> updateUserLogin(UserLogin login) =>
      _userRepo.updateUserLogin(login);

  /// Updates [MyUser.bio] field for the authenticated [MyUser].
  ///
  /// If [bio] is `null`, then resets [MyUser.bio] field.
  Future<void> updateUserBio(UserBio? bio) => _userRepo.updateUserBio(bio);

  /// Updates or resets the [MyUser.status] field of the authenticated [MyUser].
  Future<void> updateUserStatus(UserTextStatus? status) =>
      _userRepo.updateUserStatus(status);

  /// Updates password for the authenticated [MyUser].
  ///
  /// If [MyUser] has no password yet (when sets his password), then `old`
  /// password is not required. Otherwise (when changes his password), it's
  /// mandatory to specify the `old` one.
  ///
  /// Throws [UpdateUserPasswordException].
  Future<void> updateUserPassword({
    UserPassword? oldPassword,
    required UserPassword newPassword,
  }) =>
      _passwordChangeGuard.protect(() async {
        await _userRepo.updateUserPassword(oldPassword, newPassword);

        await _auth.signIn(
          newPassword,
          num: myUser.value?.num,
        );
      });

  /// Updates [MyUser.presence] to the provided value.
  Future<void> updateUserPresence(Presence presence) =>
      _userRepo.updateUserPresence(presence);

  /// Deletes the authenticated [MyUser] completely.
  ///
  /// __This action cannot be reverted.__
  Future<void> deleteMyUser() async {
    await _userRepo.deleteMyUser();
    _onUserDeleted();
  }

  /// Deletes the given [email] from [MyUser.emails] of the authenticated
  /// [MyUser].
  Future<void> deleteUserEmail(UserEmail email) =>
      _userRepo.deleteUserEmail(email);

  /// Deletes the given [phone] from [MyUser.phones] for the authenticated
  /// [MyUser].
  Future<void> deleteUserPhone(UserPhone phone) =>
      _userRepo.deleteUserPhone(phone);

  /// Adds a new [email] address for the authenticated [MyUser].
  ///
  /// Sets the given [email] address as an [MyUserEmails.unconfirmed] sub-field
  /// of a [MyUser.emails] field and sends to this address an email message with
  /// a [ConfirmationCode].
  Future<void> addUserEmail(UserEmail email) => _userRepo.addUserEmail(email);

  /// Adds a new [phone] number for the authenticated [MyUser].
  ///
  /// Sets the given [phone] number as an [MyUserPhones.unconfirmed] sub-field
  /// of a [MyUser.phones] field and sends to this number SMS with a
  /// [ConfirmationCode].
  Future<void> addUserPhone(UserPhone phone) => _userRepo.addUserPhone(phone);

  /// Confirms the given [MyUserEmails.unconfirmed] address with the provided
  /// [ConfirmationCode] for the authenticated [MyUser], and moves it to a
  /// [MyUserEmails.confirmed] sub-field unlocking the related capabilities.
  Future<void> confirmEmailCode(ConfirmationCode code) =>
      _userRepo.confirmEmailCode(code);

  /// Confirms the given [MyUserPhones.unconfirmed] number with the provided
  /// [ConfirmationCode] for the authenticated [MyUser], and moves it to a
  /// [MyUserPhones.confirmed] sub-field unlocking the related capabilities.
  Future<void> confirmPhoneCode(ConfirmationCode code) =>
      _userRepo.confirmPhoneCode(code);

  /// Resends a new [ConfirmationCode] to [MyUserEmails.unconfirmed] address for
  /// the authenticated [MyUser].
  Future<void> resendEmail() => _userRepo.resendEmail();

  /// Resends a new [ConfirmationCode] to [MyUserPhones.unconfirmed] number for
  /// the authenticated [MyUser].
  Future<void> resendPhone() => _userRepo.resendPhone();

  /// Creates a new [ChatDirectLink] with the specified [ChatDirectLinkSlug] and
  /// deletes the current active [ChatDirectLink] of the authenticated [MyUser]
  /// (if any).
  Future<void> createChatDirectLink(ChatDirectLinkSlug slug) =>
      _userRepo.createChatDirectLink(slug);

  /// Deletes the current [ChatDirectLink] of the authenticated [MyUser].
  Future<void> deleteChatDirectLink() => _userRepo.deleteChatDirectLink();

  /// Uploads a new [GalleryItem] to the gallery of the authenticated [MyUser].
  Future<ImageGalleryItem?> uploadGalleryItem(
    NativeFile galleryItem, {
    void Function(int count, int total)? onSendProgress,
  }) =>
      _userRepo.uploadGalleryItem(galleryItem, onSendProgress: onSendProgress);

  /// Removes the specified [GalleryItem] from the authenticated [MyUser]'s
  /// gallery.
  Future<void> deleteGalleryItem(GalleryItemId id) =>
      _userRepo.deleteGalleryItem(id);

  /// Updates or resets the [MyUser.avatar] field with the provided
  /// [GalleryItem] from the gallery of the authenticated [MyUser].
  Future<void> updateAvatar(GalleryItemId? id) => _userRepo.updateAvatar(id);

  /// Updates or resets the [MyUser.callCover] field with the provided
  /// [GalleryItem] from the gallery of the authenticated [MyUser].
  Future<void> updateCallCover(GalleryItemId? id) =>
      _userRepo.updateCallCover(id);

  /// Removes [MyUser] from the local data storage.
  Future<void> clearCached() async => await _userRepo.clearCache();

  /// Callback to be called when [MyUser]'s password is updated.
  ///
  /// Performs log out if the current [AccessToken] is not valid.
  Future<void> _onPasswordUpdated() => _passwordChangeGuard.protect(() async {
        bool isTokenValid = await _auth.validateToken();
        if (!isTokenValid) {
          router.go(await _auth.logout());
        }
      });

  /// Callback to be called when [MyUser] is deleted.
  ///
  /// Performs log out and clears [MyUser] store.
  Future<void> _onUserDeleted() async {
    _auth.logout();
    router.auth();
    await clearCached();
  }
}
