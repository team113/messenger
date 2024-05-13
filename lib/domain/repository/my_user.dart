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

import 'package:get/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/user.dart';
import '/util/obs/rxmap.dart';

/// [MyUser] repository interface.
abstract class AbstractMyUserRepository {
  /// Returns the currently active [MyUser] profile.
  Rx<MyUser?> get myUser;

  /// Returns a reactive map of known [MyUser] profiles.
  ///
  /// __Note__, that having a [MyUser] here doesn't mean that
  /// [AbstractAuthRepository] can sign into that account: it must also have
  /// non-stale [Credentials], which can be found in [AuthService.sessions]
  /// field.
  RxObsMap<UserId, Rx<MyUser>> get profiles;

  /// Initializes the repository.
  ///
  /// Callback [onUserDeleted] should be called when [myUser] is deleted.
  /// Callback [onPasswordUpdated] should be called when [myUser]'s password
  /// is updated.
  Future<void> init({
    required Function() onUserDeleted,
    required Function() onPasswordUpdated,
  });

  /// Disposes the repository.
  void dispose();

  /// Deletes the stored [MyUser]s.
  Future<void> clearCache();

  /// Updates [MyUser.name] field for the authenticated [MyUser].
  ///
  /// Resets [MyUser.name] field to `null` for the authenticated [MyUser] if
  /// the provided [name] is `null`.
  Future<void> updateUserName(UserName? name);

  /// Updates or resets the [MyUser.status] field of the authenticated [MyUser].
  Future<void> updateUserStatus(UserTextStatus? status);

  /// Updates or resets the [MyUser.bio] field of the authenticated [MyUser].
  Future<void> updateUserBio(UserBio? bio);

  /// Updates [MyUser.login] field for the authenticated [MyUser].
  Future<void> updateUserLogin(UserLogin? login);

  /// Updates [MyUser.presence] to the provided value.
  Future<void> updateUserPresence(Presence presence);

  /// Updates password for the authenticated [MyUser].
  ///
  /// If [MyUser] has no password yet (when sets his password), then `old`
  /// password is not required. Otherwise (when changes his password), it's
  /// mandatory to specify the `old` one.
  Future<void> updateUserPassword(
    UserPassword? oldPassword,
    UserPassword newPassword,
  );

  /// Deletes the authenticated [MyUser] completely.
  ///
  /// __This action cannot be reverted.__
  Future<void> deleteMyUser();

  /// Deletes the given [email] from [MyUser.emails] of the authenticated
  /// [MyUser].
  Future<void> deleteUserEmail(UserEmail email);

  /// Deletes the given [phone] from [MyUser.phones] for the authenticated
  /// [MyUser].
  Future<void> deleteUserPhone(UserPhone phone);

  /// Adds a new [email] address for the authenticated [MyUser].
  ///
  /// Sets the given [email] address as an [MyUserEmails.unconfirmed] sub-field
  /// of a [MyUser.emails] field and sends to this address an email message with
  /// a [ConfirmationCode].
  Future<void> addUserEmail(UserEmail email);

  /// Adds a new [phone] number for the authenticated [MyUser].
  ///
  /// Sets the given [phone] number as an [MyUserPhones.unconfirmed] sub-field
  /// of a [MyUser.phones] field and sends to this number SMS with a
  /// [ConfirmationCode].
  Future<void> addUserPhone(UserPhone phone);

  /// Confirms the given [MyUserEmails.unconfirmed] address with the provided
  /// [ConfirmationCode] for the authenticated [MyUser], and moves it to a
  /// [MyUserEmails.confirmed] sub-field unlocking the related capabilities.
  Future<void> confirmEmailCode(ConfirmationCode confirmEmailCode);

  /// Confirms the given [MyUserPhones.unconfirmed] number with the provided
  /// [ConfirmationCode] for the authenticated [MyUser], and moves it to a
  /// [MyUserPhones.confirmed] sub-field unlocking the related capabilities.
  Future<void> confirmPhoneCode(ConfirmationCode confirmPhoneCode);

  /// Resends a new [ConfirmationCode] to [MyUserEmails.unconfirmed] address for
  /// the authenticated [MyUser].
  Future<void> resendEmail();

  /// Resends a new [ConfirmationCode] to [MyUserPhones.unconfirmed] number for
  /// the authenticated [MyUser].
  Future<void> resendPhone();

  /// Creates a new [ChatDirectLink] with the specified [ChatDirectLinkSlug] and
  /// deletes the current active [ChatDirectLink] of the authenticated [MyUser]
  /// (if any).
  Future<void> createChatDirectLink(ChatDirectLinkSlug slug);

  /// Deletes the current [ChatDirectLink] of the authenticated [MyUser].
  Future<void> deleteChatDirectLink();

  /// Updates or resets the [MyUser.avatar] field with the provided image
  /// [file].
  Future<void> updateAvatar(
    NativeFile? file, {
    void Function(int count, int total)? onSendProgress,
  });

  /// Updates or resets the [MyUser.callCover] field with the provided image
  /// [file].
  Future<void> updateCallCover(
    NativeFile? file, {
    void Function(int count, int total)? onSendProgress,
  });

  /// Mutes or unmutes all the [Chat]s of the authenticated [MyUser].
  Future<void> toggleMute(MuteDuration? mute);

  /// Refreshes the [MyUser] to be up to date.
  Future<void> refresh();
}
