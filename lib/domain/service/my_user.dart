// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import '/api/backend/schema.dart' show UserPresence, CropAreaInput;
import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/repository/my_user.dart';
import '/routes.dart';
import '/util/log.dart';
import '/util/obs/rxmap.dart';
import '/util/web/web_utils.dart';
import 'auth.dart';
import 'disposable_service.dart';

/// Service responsible for [MyUser] management.
class MyUserService extends Dependency {
  MyUserService(this._authService, this._myUserRepository);

  /// Authentication service providing the authentication capabilities.
  final AuthService _authService;

  /// Repository responsible for storing [MyUser].
  final AbstractMyUserRepository _myUserRepository;

  /// Mutex guarding [updateUserPassword] mutation and `onPasswordUpdated`
  /// logic.
  final Mutex _passwordChangeGuard = Mutex();

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserRepository.myUser;

  /// Returns a reactive map of all the known [MyUser] profiles.
  RxObsMap<UserId, Rx<MyUser>> get profiles => _myUserRepository.profiles;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

    _myUserRepository.init(
      onPasswordUpdated: _onPasswordUpdated,
      onUserDeleted: _onUserDeleted,
    );
    super.onInit();
  }

  /// Updates [MyUser.name] field for the authenticated [MyUser].
  ///
  /// If [name] is `null`, then resets [MyUser.name] field.
  Future<void> updateUserName(UserName? name) async {
    Log.debug('updateUserName($name)', '$runtimeType');
    await _myUserRepository.updateUserName(name);
  }

  /// Updates [MyUser.login] field for the authenticated [MyUser].
  Future<void> updateUserLogin(UserLogin? login) async {
    Log.debug('updateUserLogin($login)', '$runtimeType');
    await _myUserRepository.updateUserLogin(login);
  }

  /// Updates or resets the [MyUser.status] field of the authenticated [MyUser].
  Future<void> updateUserStatus(UserTextStatus? status) async {
    Log.debug('updateUserStatus($status)', '$runtimeType');
    await _myUserRepository.updateUserStatus(status);
  }

  /// Updates or resets the [MyUser.bio] field of the authenticated [MyUser].
  Future<void> updateUserBio(UserBio? bio) async {
    Log.debug('updateUserBio($bio)', '$runtimeType');
    await _myUserRepository.updateUserBio(bio);
  }

  /// Updates the [WelcomeMessage] of the authenticated [MyUser].
  Future<void> updateWelcomeMessage({
    ChatMessageText? text,
    List<Attachment>? attachments,
  }) async {
    Log.debug(
      'updateWelcomeMessage(text: $text, attachments: $attachments)',
      '$runtimeType',
    );

    await _myUserRepository.updateWelcomeMessage(
      text: text,
      attachments: attachments,
    );
  }

  /// Updates password for the authenticated [MyUser].
  ///
  /// If [MyUser] has no password yet (when sets his password), then `old`
  /// password is not required. Otherwise (when changes his password), it's
  /// mandatory to specify the `old` one.
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
        if (isClosed) {
          return;
        }

        await _myUserRepository.updateUserPassword(oldPassword, newPassword);

        // TODO: Replace `unsafe` with something more granular and correct.
        await _authService.signIn(
          password: newPassword,
          num: myUser.value?.num,
          unsafe: true,
          force: true,
        );
      });
    });
  }

  /// Updates [MyUser.presence] to the provided value.
  Future<void> updateUserPresence(UserPresence presence) async {
    Log.debug('updateUserPresence($presence)', '$runtimeType');
    await _myUserRepository.updateUserPresence(presence);
  }

  /// Deletes the authenticated [MyUser] completely.
  ///
  /// __This action cannot be reverted.__
  Future<void> deleteMyUser({
    UserPassword? password,
    ConfirmationCode? confirmation,
  }) async {
    Log.debug(
      'deleteMyUser(password: ***, confirmation: $confirmation)',
      '$runtimeType',
    );

    await _myUserRepository.deleteMyUser(
      password: password,
      confirmation: confirmation,
    );

    _onUserDeleted();
  }

  /// Deletes the given [email] from [MyUser.emails] of the authenticated
  /// [MyUser].
  Future<void> removeUserEmail(
    UserEmail email, {
    UserPassword? password,
    ConfirmationCode? confirmation,
  }) async {
    Log.debug(
      'removeUserEmail($email, password: ***, confirmation: $confirmation)',
      '$runtimeType',
    );

    await _myUserRepository.removeUserEmail(
      email,
      password: password,
      confirmation: confirmation,
    );
  }

  /// Deletes the given [phone] from [MyUser.phones] for the authenticated
  /// [MyUser].
  Future<void> removeUserPhone(
    UserPhone phone, {
    UserPassword? password,
    ConfirmationCode? confirmation,
  }) async {
    Log.debug(
      'removeUserPhone($phone, password: ***, confirmation: $confirmation)',
      '$runtimeType',
    );

    await _myUserRepository.removeUserPhone(
      phone,
      password: password,
      confirmation: confirmation,
    );
  }

  /// Adds a new [email] address for the authenticated [MyUser].
  ///
  /// Sets the given [email] address as an [MyUserEmails.unconfirmed] sub-field
  /// of a [MyUser.emails] field and sends to this address an email message with
  /// a [ConfirmationCode].
  Future<void> addUserEmail(
    UserEmail email, {
    ConfirmationCode? confirmation,
    String? locale,
  }) async {
    Log.debug(
      'addUserEmail($email, confirmation: $confirmation, locale: $locale)',
      '$runtimeType',
    );

    await _myUserRepository.addUserEmail(
      email,
      confirmation: confirmation,
      locale: locale,
    );
  }

  /// Adds a new [phone] number for the authenticated [MyUser].
  ///
  /// Sets the given [phone] number as an [MyUserPhones.unconfirmed] sub-field
  /// of a [MyUser.phones] field and sends to this number SMS with a
  /// [ConfirmationCode].
  Future<void> addUserPhone(
    UserPhone phone, {
    ConfirmationCode? confirmation,
    String? locale,
  }) async {
    Log.debug(
      'addUserPhone($phone, confirmation: $confirmation, locale: $locale)',
      '$runtimeType',
    );

    await _myUserRepository.addUserPhone(
      phone,
      confirmation: confirmation,
      locale: locale,
    );
  }

  /// Creates a new [ChatDirectLink] with the specified [ChatDirectLinkSlug] and
  /// deletes the current active [ChatDirectLink] of the authenticated [MyUser]
  /// (if any).
  Future<void> createChatDirectLink(ChatDirectLinkSlug slug) async {
    Log.debug('createChatDirectLink($slug)', '$runtimeType');
    await _myUserRepository.createChatDirectLink(slug);
  }

  /// Deletes the current [ChatDirectLink] of the authenticated [MyUser].
  Future<void> deleteChatDirectLink() async {
    Log.debug('deleteChatDirectLink()', '$runtimeType');
    await _myUserRepository.deleteChatDirectLink();
  }

  /// Updates or resets the [MyUser.avatar] field with the provided image
  /// [file].
  Future<void> updateAvatar(
    NativeFile? file, {
    CropAreaInput? crop,
    void Function(int count, int total)? onSendProgress,
  }) async {
    Log.debug(
      'updateAvatar($file, crop: $crop, onSendProgress)',
      '$runtimeType',
    );

    await _myUserRepository.updateAvatar(
      file,
      crop: crop,
      onSendProgress: onSendProgress,
    );
  }

  /// Updates or resets the [MyUser.callCover] field with the provided image
  /// [file].
  Future<void> updateCallCover(
    NativeFile? file, {
    void Function(int count, int total)? onSendProgress,
  }) async {
    Log.debug('updateCallCover($file, onSendProgress)', '$runtimeType');
    await _myUserRepository.updateCallCover(
      file,
      onSendProgress: onSendProgress,
    );
  }

  /// Mutes or unmutes all the [Chat]s of the authenticated [MyUser].
  Future<void> toggleMute(MuteDuration? mute) async {
    Log.debug('toggleMute($mute)', '$runtimeType');
    await _myUserRepository.toggleMute(mute);
  }

  /// Refreshes the [MyUser] to be up to date.
  Future<void> refresh() async {
    Log.debug('refresh()', '$runtimeType');
    await _myUserRepository.refresh();
  }

  /// Callback to be called when the active [MyUser]'s password is updated.
  ///
  /// Performs log out if the current [AccessToken] is not valid.
  Future<void> _onPasswordUpdated() async {
    Log.debug('_onPasswordUpdated()', '$runtimeType');

    await _passwordChangeGuard.protect(() async {
      final bool isTokenValid = await _authService.validateToken();
      if (!isTokenValid) {
        try {
          await _authService.deleteSession();
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
      await _authService.deleteSession(force: true);
    } finally {
      router.auth();
    }
  }
}
