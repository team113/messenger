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

import 'dart:math';

import 'package:email_validator/email_validator.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/api/backend/schema.dart';
import '/domain/model_type_id.dart';
import '/util/new_type.dart';
import 'avatar.dart';
import 'chat.dart';
import 'image_gallery_item.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user_call_cover.dart';

part 'user.g.dart';

/// User of a system impersonating a real person.
@HiveType(typeId: ModelTypeId.user)
class User extends HiveObject {
  User(
    this.id,
    this.num, {
    this.name,
    this.bio,
    this.avatar,
    this.callCover,
    this.gallery,
    this.mutualContactsCount = 0,
    this.online = false,
    this.presenceIndex = 0,
    this.status,
    this.isDeleted = false,
    ChatId? dialog,
    this.isBlacklisted = false,
    this.lastSeenAt,
  }) : _dialog = dialog;

  /// Unique ID of this [User].
  ///
  /// Once assigned it never changes.
  @HiveField(0)
  final UserId id;

  /// Unique number of this [User].
  ///
  /// [num] is intended for an easier [User] identification by other [User]s.
  /// It's just like a telephone number in a real life.
  ///
  /// [num] allows this [User] to perform a sign-in, when combined with a
  /// password.
  ///
  /// It may be reused by another [User] in future, once this [User] becomes
  /// unreachable (sign-in for this [User] is impossible).
  @HiveField(1)
  final UserNum num;

  /// Name of this [User].
  ///
  /// [name] is not unique and is intended for displaying an [User] in a
  /// well-readable form for an easier [User] identification by other [User]s.
  /// It can be either first name, or last name of an [User], both of them, or
  /// even some nickname. [User] is free to choose how exactly he should be
  /// displayed for other [User]s.
  @HiveField(3)
  UserName? name;

  /// Arbitrary descriptive information about this [User].
  @HiveField(4)
  UserBio? bio;

  /// Avatar of this [User].
  @HiveField(5)
  UserAvatar? avatar;

  /// Call cover of this [User].
  ///
  /// [callCover] is an image helping to identify an [User] visually in
  /// [UserCallCover]s.
  @HiveField(6)
  UserCallCover? callCover;

  /// [ImageGalleryItem]s of this [User] ordered by their adding time.
  @HiveField(7)
  List<ImageGalleryItem>? gallery;

  /// Number of mutual [ChatContact]s that this [User] has with the
  /// authenticated [MyUser].
  @HiveField(8)
  int mutualContactsCount;

  /// Online state of this [User].
  @HiveField(9)
  bool online;

  /// Presence of this [User].
  @HiveField(10)
  int presenceIndex;

  Presence get presence => Presence.values[presenceIndex];
  set presence(Presence pres) {
    presenceIndex = pres.index;
  }

  /// Custom text status of this [User].
  @HiveField(11)
  UserTextStatus? status;

  /// Indicator whether this [User] is deleted.
  @HiveField(12)
  bool isDeleted;

  /// Dialog [Chat] between this [User] and the authenticated [MyUser].
  @HiveField(13)
  ChatId? _dialog;

  /// Indicator whether this [User] is blacklisted by the authenticated
  /// [MyUser].
  @HiveField(14)
  bool isBlacklisted;

  /// [PreciseDateTime] when this [User] was seen online last time.
  @HiveField(17)
  PreciseDateTime? lastSeenAt;

  /// Returns [ChatId] of the dialog with this [User].
  ChatId get dialog => _dialog ?? ChatId.local(id);

  /// Sets the [dialog] value of this [User].
  set dialog(ChatId dialog) {
    _dialog = dialog;
  }
}

/// Unique ID of an [User].
///
/// See more details in [User.id].
@HiveType(typeId: ModelTypeId.userId)
class UserId extends NewType<String> {
  const UserId(String val) : super(val);
}

/// Unique number of an [User].
///
/// See more details in [User.num].
@HiveType(typeId: ModelTypeId.userNum)
class UserNum extends NewType<String> {
  const UserNum._(String val) : super(val);

  UserNum(String val) : super(val) {
    if (val.length != 16) {
      throw const FormatException('Must be 16 characters long');
    } else if (!val.isNumericOnly) {
      throw const FormatException('Must be numeric only');
    }
  }

  /// Creates an object without any validation.
  const factory UserNum.unchecked(String val) = UserNum._;
}

/// Unique login of an [User].
///
/// [UserLogin] allows [User] to perform a sign-in, when combined with a
/// password.
@HiveType(typeId: ModelTypeId.userLogin)
class UserLogin extends NewType<String> {
  const UserLogin._(String val) : super(val);

  UserLogin(String val) : super(val) {
    if (val.isNumericOnly) {
      throw const FormatException('Can not contain only numbers');
    } else if (!_regExp.hasMatch(val)) {
      throw const FormatException('Does not match validation RegExp');
    }
  }

  /// Creates an object without any validation.
  const factory UserLogin.unchecked(String val) = UserLogin._;

  /// Regular expression for basic [UserLogin] validation.
  static final RegExp _regExp = RegExp(r'^[a-z0-9][a-z0-9_-]{1,18}[a-z0-9]$');
}

/// Name of an [User].
///
/// See more details in [User.name].
@HiveType(typeId: ModelTypeId.userName)
class UserName extends NewType<String> {
  const UserName._(String val) : super(val);

  UserName(String val) : super(val) {
    if (!_regExp.hasMatch(val)) {
      throw const FormatException('Does not match validation RegExp');
    }
  }

  /// Creates an object without any validation.
  const factory UserName.unchecked(String val) = UserName._;

  /// Regular expression for basic [UserName] validation.
  static final RegExp _regExp = RegExp(r'^[^\s].{0,98}[^\s]$');
}

/// Arbitrary descriptive information about an [User].
@HiveType(typeId: ModelTypeId.userBio)
class UserBio extends NewType<String> {
  const UserBio._(String val) : super(val);

  UserBio(String val) : super(val) {
    if (val.isEmpty) {
      throw const FormatException('Must not be empty');
    } else if (val.length > 300) {
      throw const FormatException('Must contain no more than 300 characters');
    }
  }

  /// Creates an object without any validation.
  const factory UserBio.unchecked(String val) = UserBio._;
}

/// Password of an [User].
///
/// Password allows [User] to perform a sign-in, when combined with a
/// [UserLogin], [UserNum], [UserEmail] or [UserPhone].
class UserPassword extends NewType<String> {
  const UserPassword._(String val) : super(val);

  UserPassword(String val) : super(val) {
    if (val.isEmpty) {
      throw const FormatException('Must not be empty');
    } else if (val.length > 250) {
      throw const FormatException('Must contain no more than 250 characters');
    } else if (!_regExp.hasMatch(val)) {
      throw const FormatException('Does not match validation RegExp');
    }
  }

  /// Creates an object without any validation.
  const factory UserPassword.unchecked(String val) = UserPassword._;

  /// Regular expression for basic [UserPassword] validation.
  static final RegExp _regExp = RegExp(r'^[^\s](.{0,248}[^\s])?$');
}

/// Email address of an [User].
@HiveType(typeId: ModelTypeId.userEmail)
class UserEmail extends NewType<String> {
  const UserEmail._(String val) : super(val);

  UserEmail(String val) : super(val) {
    if (!EmailValidator.validate(val)) {
      throw const FormatException('Does not match validation RegExp');
    }
  }

  /// Creates an object without any validation.
  const factory UserEmail.unchecked(String val) = UserEmail._;
}

/// Phone number of an [User].
@HiveType(typeId: ModelTypeId.userPhone)
class UserPhone extends NewType<String> {
  const UserPhone._(String val) : super(val);

  UserPhone(String val) : super(val) {
    if (!val.startsWith('+')) {
      throw const FormatException('Must start with plus');
    }

    if (val.length < 8) {
      throw const FormatException('Must contain no less than 8 symbols');
    }

    if (!_regExp.hasMatch(val)) {
      throw const FormatException('Does not match validation RegExp');
    }
  }

  /// Creates an object without any validation.
  const factory UserPhone.unchecked(String val) = UserPhone._;

  /// Regular expression for basic [UserPhone] validation.
  static final RegExp _regExp = RegExp(
    r'^\+[0-9]{0,3}[\s]?[(]?[0-9]{0,3}[)]?[-\s]?[0-9]{0,4}[-\s]?[0-9]{0,4}[-\s]?[0-9]{0,4}$',
  );
}

/// Direct link to a `Chat`.
@HiveType(typeId: ModelTypeId.chatDirectLink)
class ChatDirectLink {
  ChatDirectLink({
    required this.slug,
    this.usageCount = 0,
  });

  /// Unique slug associated with this [ChatDirectLink].
  @HiveField(0)
  ChatDirectLinkSlug slug;

  /// Number of times this [ChatDirectLink] has been used.
  @HiveField(1)
  int usageCount;
}

/// Slug of a [ChatDirectLink].
@HiveType(typeId: ModelTypeId.chatDirectLinkSlug)
class ChatDirectLinkSlug extends NewType<String> {
  const ChatDirectLinkSlug._(String val) : super(val);

  ChatDirectLinkSlug(String val) : super(val) {
    if (val.length > 100) {
      throw const FormatException('Must contain no more than 100 characters');
    } else if (val.isEmpty) {
      throw const FormatException('Must not be empty');
    } else if (!_regExp.hasMatch(val)) {
      throw const FormatException('Does not match validation RegExp');
    }
  }

  /// Creates an object without any validation.
  const factory ChatDirectLinkSlug.unchecked(String val) = ChatDirectLinkSlug._;

  /// Creates a random [ChatDirectLinkSlug] of the provided [length].
  factory ChatDirectLinkSlug.generate([int length = 10]) {
    final Random r = Random();
    const String chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890_-';
    return ChatDirectLinkSlug(
      List.generate(length, (_) => chars[r.nextInt(chars.length)]).join(),
    );
  }

  /// Regular expression for basic [ChatDirectLinkSlug] validation.
  static final RegExp _regExp = RegExp(r'^[A-z0-9_-]{1,100}$');
}

/// Status of an [User].
@HiveType(typeId: ModelTypeId.userTextStatus)
class UserTextStatus extends NewType<String> {
  const UserTextStatus._(String val) : super(val);

  UserTextStatus(String val) : super(val) {
    if (val.length > 25) {
      throw const FormatException('Must contain no more than 25 characters');
    } else if (val.isEmpty) {
      throw const FormatException('Must not be empty');
    }
  }

  /// Creates an object without any validation.
  const factory UserTextStatus.unchecked(String val) = UserTextStatus._;
}
