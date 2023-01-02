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

import 'package:get/get.dart';

import '../model/my_user.dart';
import '../model/user.dart';
import '/api/backend/schema.dart' show Presence;
import '/domain/model/gallery_item.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/native_file.dart';
import '/domain/repository/user.dart';

/// [MyUser] repository interface.
abstract class AbstractMyUserRepository {
  /// Returns stored [MyUser] value.
  Rx<MyUser?> get myUser;

  /// Returns [User]s blacklisted by the authenticated [MyUser].
  RxList<RxUser> get blacklist;

  /// Initializes the repository.
  ///
  /// Callback [onUserDeleted] should be called when [myUser] is deleted.
  /// Callback [onPasswordUpdated] should be called when [myUser]'s password
  /// is updated.
  Future<void> init({
    required Function() onUserDeleted,
    required Function() onPasswordUpdated,
  });

  /// Clears the stored [MyUser].
  Future<void> clearCache();

  /// Updates [MyUser.name] field for the authenticated [MyUser].
  ///
  /// Resets [MyUser.name] field to `null` for the authenticated [MyUser] if
  /// the provided [name] is `null`.
  Future<void> updateUserName(UserName? name);

  /// Updates [MyUser.bio] field for the authenticated [MyUser].
  ///
  /// Resets [MyUser.bio] field to `null` for the authenticated [MyUser] if the
  /// provided [bio] is `null`.
  Future<void> updateUserBio(UserBio? bio);

  /// Updates or resets the [MyUser.status] field of the authenticated [MyUser].
  Future<void> updateUserStatus(UserTextStatus? status);

  /// Updates [MyUser.login] field for the authenticated [MyUser].
  Future<void> updateUserLogin(UserLogin login);

  /// Updates [MyUser.presence] to the provided value.
  Future<void> updateUserPresence(Presence presence);

  /// Updates password for the authenticated [MyUser].
  ///
  /// If [MyUser] has no password yet (when sets his password), then `old`
  /// password is not required. Otherwise (when changes his password), it's
  /// mandatory to specify the `old` one.
  Future<void> updateUserPassword(
      UserPassword? oldPassword, UserPassword newPassword);

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

  /// Uploads a new [GalleryItem] to the gallery of the authenticated [MyUser].
  Future<ImageGalleryItem?> uploadGalleryItem(
    NativeFile galleryItem, {
    void Function(int count, int total)? onSendProgress,
  });

  /// Removes the specified [GalleryItem] from the authenticated [MyUser]'s
  /// gallery.
  Future<void> deleteGalleryItem(GalleryItemId id);

  /// Updates or resets the [MyUser.avatar] field with the provided
  /// [GalleryItem] from the gallery of the authenticated [MyUser].
  Future<void> updateAvatar(GalleryItemId? id);

  /// Updates or resets the [MyUser.callCover] field with the provided
  /// [GalleryItem] from the gallery of the authenticated [MyUser].
  Future<void> updateCallCover(GalleryItemId? id);

  /// Mutes or unmutes all the [Chat]s of the authenticated [MyUser].
  Future<void> toggleMute(MuteDuration? mute);

  /// Disposes the repository.
  void dispose();
}
