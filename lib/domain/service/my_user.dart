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

import 'package:get/get.dart';
import 'package:mutex/mutex.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/user.dart';
import '/domain/repository/my_user.dart';
import '/routes.dart';
import '/util/log.dart';
import '/util/obs/rxmap.dart';
import '/util/web/web_utils.dart';
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

  /// Returns a reactive map of all authenticated [MyUser]s available.
  RxObsMap<UserId, Rx<MyUser>> get myUsers => _userRepo.myUsers;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

    assert(_auth.initialized);
    _userRepo.init(
      onPasswordUpdated: _onPasswordUpdated,
      onUserDeleted: _onUserDeleted,
    );
    super.onInit();
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    _userRepo.dispose();
    super.onClose();
  }

  /// Updates [MyUser.name] field for the authenticated [MyUser].
  ///
  /// If [name] is `null`, then resets [MyUser.name] field.
  Future<void> updateUserName(UserName? name) async {
    Log.debug('updateUserName($name)', '$runtimeType');
    await _userRepo.updateUserName(name);
  }

  /// Updates [MyUser.login] field for the authenticated [MyUser].
  ///
  /// Throws [UpdateUserLoginException].
  Future<void> updateUserLogin(UserLogin? login) async {
    Log.debug('updateUserLogin($login)', '$runtimeType');
    await _userRepo.updateUserLogin(login);
  }

  /// Updates or resets the [MyUser.status] field of the authenticated [MyUser].
  Future<void> updateUserStatus(UserTextStatus? status) async {
    Log.debug('updateUserStatus($status)', '$runtimeType');
    await _userRepo.updateUserStatus(status);
  }

  /// Updates or resets the [MyUser.bio] field of the authenticated [MyUser].
  Future<void> updateUserBio(UserBio? bio) async {
    Log.debug('updateUserBio($bio)', '$runtimeType');
    await _userRepo.updateUserBio(bio);
  }

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
  }) async {
    Log.debug('updateUserPassword(***, ***)', '$runtimeType');

    final bool locked = _passwordChangeGuard.isLocked;

    await _passwordChangeGuard.protect(() async {
      if (locked) {
        return;
      }

      await WebUtils.protect(() async {
        await _userRepo.updateUserPassword(oldPassword, newPassword);

        await _auth.signIn(
          newPassword,
          num: myUser.value?.num,
          ignoreLock: true,
        );
      });
    });
  }

  /// Updates [MyUser.presence] to the provided value.
  Future<void> updateUserPresence(Presence presence) async {
    Log.debug('updateUserPresence($presence)', '$runtimeType');
    await _userRepo.updateUserPresence(presence);
  }

  /// Deletes the authenticated [MyUser] completely.
  ///
  /// __This action cannot be reverted.__
  Future<void> deleteMyUser() async {
    Log.debug('deleteMyUser()', '$runtimeType');

    await _userRepo.deleteMyUser();
    _onUserDeleted();
  }

  /// Deletes the given [email] from [MyUser.emails] of the authenticated
  /// [MyUser].
  Future<void> deleteUserEmail(UserEmail email) async {
    Log.debug('deleteUserEmail($email)', '$runtimeType');
    await _userRepo.deleteUserEmail(email);
  }

  /// Deletes the given [phone] from [MyUser.phones] for the authenticated
  /// [MyUser].
  Future<void> deleteUserPhone(UserPhone phone) async {
    Log.debug('deleteUserPhone($phone)', '$runtimeType');
    await _userRepo.deleteUserPhone(phone);
  }

  /// Adds a new [email] address for the authenticated [MyUser].
  ///
  /// Sets the given [email] address as an [MyUserEmails.unconfirmed] sub-field
  /// of a [MyUser.emails] field and sends to this address an email message with
  /// a [ConfirmationCode].
  Future<void> addUserEmail(UserEmail email) async {
    Log.debug('addUserEmail($email)', '$runtimeType');
    await _userRepo.addUserEmail(email);
  }

  /// Adds a new [phone] number for the authenticated [MyUser].
  ///
  /// Sets the given [phone] number as an [MyUserPhones.unconfirmed] sub-field
  /// of a [MyUser.phones] field and sends to this number SMS with a
  /// [ConfirmationCode].
  Future<void> addUserPhone(UserPhone phone) async {
    Log.debug('addUserPhone($phone)', '$runtimeType');
    await _userRepo.addUserPhone(phone);
  }

  /// Confirms the given [MyUserEmails.unconfirmed] address with the provided
  /// [ConfirmationCode] for the authenticated [MyUser], and moves it to a
  /// [MyUserEmails.confirmed] sub-field unlocking the related capabilities.
  Future<void> confirmEmailCode(ConfirmationCode code) async {
    Log.debug('confirmEmailCode($code)', '$runtimeType');
    await _userRepo.confirmEmailCode(code);
  }

  /// Confirms the given [MyUserPhones.unconfirmed] number with the provided
  /// [ConfirmationCode] for the authenticated [MyUser], and moves it to a
  /// [MyUserPhones.confirmed] sub-field unlocking the related capabilities.
  Future<void> confirmPhoneCode(ConfirmationCode code) async {
    Log.debug('confirmPhoneCode($code)', '$runtimeType');
    await _userRepo.confirmPhoneCode(code);
  }

  /// Resends a new [ConfirmationCode] to [MyUserEmails.unconfirmed] address for
  /// the authenticated [MyUser].
  Future<void> resendEmail() async {
    Log.debug('resendEmail()', '$runtimeType');
    await _userRepo.resendEmail();
  }

  /// Resends a new [ConfirmationCode] to [MyUserPhones.unconfirmed] number for
  /// the authenticated [MyUser].
  Future<void> resendPhone() async {
    Log.debug('resendPhone()', '$runtimeType');
    await _userRepo.resendPhone();
  }

  /// Creates a new [ChatDirectLink] with the specified [ChatDirectLinkSlug] and
  /// deletes the current active [ChatDirectLink] of the authenticated [MyUser]
  /// (if any).
  Future<void> createChatDirectLink(ChatDirectLinkSlug slug) async {
    Log.debug('createChatDirectLink($slug)', '$runtimeType');
    await _userRepo.createChatDirectLink(slug);
  }

  /// Deletes the current [ChatDirectLink] of the authenticated [MyUser].
  Future<void> deleteChatDirectLink() async {
    Log.debug('deleteChatDirectLink()', '$runtimeType');
    await _userRepo.deleteChatDirectLink();
  }

  /// Updates or resets the [MyUser.avatar] field with the provided image
  /// [file].
  Future<void> updateAvatar(
    NativeFile? file, {
    void Function(int count, int total)? onSendProgress,
  }) async {
    Log.debug('updateAvatar($file, onSendProgress)', '$runtimeType');
    await _userRepo.updateAvatar(file, onSendProgress: onSendProgress);
  }

  /// Updates or resets the [MyUser.callCover] field with the provided image
  /// [file].
  Future<void> updateCallCover(
    NativeFile? file, {
    void Function(int count, int total)? onSendProgress,
  }) async {
    Log.debug('updateCallCover($file, onSendProgress)', '$runtimeType');
    await _userRepo.updateCallCover(file, onSendProgress: onSendProgress);
  }

  /// Mutes or unmutes all the [Chat]s of the authenticated [MyUser].
  Future<void> toggleMute(MuteDuration? mute) async {
    Log.debug('toggleMute($mute)', '$runtimeType');
    await _userRepo.toggleMute(mute);
  }

  /// Refreshes the [MyUser] to be up to date.
  Future<void> refresh() async {
    Log.debug('refresh()', '$runtimeType');
    await _userRepo.refresh();
  }

  /// Callback to be called when the active [MyUser]'s password is updated.
  ///
  /// Performs log out if the current [AccessToken] is not valid.
  Future<void> _onPasswordUpdated() async {
    Log.debug('_onPasswordUpdated()', '$runtimeType');

    await _passwordChangeGuard.protect(() async {
      final bool isTokenValid = await _auth.validateToken();
      if (!isTokenValid) {
        try {
          await _auth.deleteSession();
        } finally {
          router.auth();
        }
      }
    });
  }

  /// Callback to be called when the active [MyUser] is deleted.
  ///
  /// Performs log out.
  Future<void> _onUserDeleted() async {
    Log.debug('_onUserDeleted()', '$runtimeType');

    try {
      await _auth.deleteSession(force: true);
    } finally {
      router.auth();
    }
  }
}
