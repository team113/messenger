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
import 'package:json_annotation/json_annotation.dart';

import '/api/backend/schema.dart';
import '/domain/model_type_id.dart';
import '/util/new_type.dart';
import 'avatar.dart';
import 'chat.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user_call_cover.dart';

part 'user.g.dart';

/// User of a system impersonating a real person.
@JsonSerializable()
@HiveType(typeId: ModelTypeId.user)
class User {
  User(
    this.id,
    this.num, {
    this.name,
    this.avatar,
    this.callCover,
    this.mutualContactsCount = 0,
    this.online = false,
    this.presenceIndex,
    this.status,
    this.isDeleted = false,
    ChatId? dialog,
    this.isBlocked,
    this.lastSeenAt,
  }) : _dialog = dialog;

  /// Connect the generated [_$UserFromJson] function to the `fromJson`
  /// factory.
  factory User.fromJson(Map<String, dynamic> data) => _$UserFromJson(data);

  /// Connect the generated [_$UserToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$UserToJson(this);

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
  @HiveField(2)
  UserName? name;

  /// Avatar of this [User].
  @HiveField(3)
  UserAvatar? avatar;

  /// Call cover of this [User].
  ///
  /// [callCover] is an image helping to identify an [User] visually in
  /// [UserCallCover]s.
  @HiveField(4)
  UserCallCover? callCover;

  /// Number of mutual [ChatContact]s that this [User] has with the
  /// authenticated [MyUser].
  @HiveField(5)
  int mutualContactsCount;

  /// Online state of this [User].
  @HiveField(6)
  bool online;

  /// Presence of this [User].
  @HiveField(7)
  int? presenceIndex;

  Presence? get presence =>
      presenceIndex == null ? null : Presence.values[presenceIndex!];
  set presence(Presence? value) {
    presenceIndex = value?.index;
  }

  /// Custom text status of this [User].
  @HiveField(8)
  UserTextStatus? status;

  /// Indicator whether this [User] is deleted.
  @HiveField(9)
  bool isDeleted;

  /// Dialog [Chat] between this [User] and the authenticated [MyUser].
  @HiveField(10)
  ChatId? _dialog;

  /// Indicator whether this [User] is blocked by the authenticated [MyUser].
  @HiveField(11)
  BlocklistRecord? isBlocked;

  /// [PreciseDateTime] when this [User] was seen online last time.
  @HiveField(12)
  PreciseDateTime? lastSeenAt;

  /// Returns [ChatId] of the [Chat]-dialog with this [User].
  ChatId get dialog => _dialog ?? ChatId.local(id);

  /// Sets the provided [ChatId] as a [dialog] of this [User].
  set dialog(ChatId dialog) => _dialog = dialog;
}

/// Unique ID of an [User].
///
/// See more details in [User.id].
@JsonSerializable()
@HiveType(typeId: ModelTypeId.userId)
class UserId extends NewType<String> {
  const UserId(String val) : super(val);

  /// Connect the generated [_$UserIdFromJson] function to the `fromJson`
  /// factory.
  factory UserId.fromJson(Map<String, dynamic> data) => _$UserIdFromJson(data);

  /// Connect the generated [_$UserIdToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$UserIdToJson(this);
}

/// Unique number of an [User].
///
/// See more details in [User.num].
@JsonSerializable()
@HiveType(typeId: ModelTypeId.userNum)
class UserNum extends NewType<String> {
  const UserNum._(String val) : super(val);

  factory UserNum(String val) {
    val = val.replaceAll(' ', '');

    if (val.length != 16) {
      throw const FormatException('Must be 16 characters long');
    } else if (!val.isNumericOnly) {
      throw const FormatException('Must be numeric only');
    }

    return UserNum._(val);
  }

  /// Creates an object without any validation.
  const factory UserNum.unchecked(String val) = UserNum._;

  /// Connect the generated [_$UserNumFromJson] function to the `fromJson`
  /// factory.
  factory UserNum.fromJson(Map<String, dynamic> data) =>
      _$UserNumFromJson(data);

  /// Connect the generated [_$UserNumToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$UserNumToJson(this);
}

/// Unique login of an [User].
///
/// [UserLogin] allows [User] to perform a sign-in, when combined with a
/// password.
@JsonSerializable()
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

  /// Connect the generated [_$UserLoginFromJson] function to the `fromJson`
  /// factory.
  factory UserLogin.fromJson(Map<String, dynamic> data) =>
      _$UserLoginFromJson(data);

  /// Connect the generated [_$UserLoginToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$UserLoginToJson(this);

  /// Regular expression for basic [UserLogin] validation.
  static final RegExp _regExp = RegExp(r'^[a-z0-9][a-z0-9_-]{1,18}[a-z0-9]$');
}

/// Name of an [User].
///
/// See more details in [User.name].
@JsonSerializable()
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

  /// Connect the generated [_$UserNameFromJson] function to the `fromJson`
  /// factory.
  factory UserName.fromJson(Map<String, dynamic> data) =>
      _$UserNameFromJson(data);

  /// Connect the generated [_$UserNameToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$UserNameToJson(this);

  /// Regular expression for basic [UserName] validation.
  static final RegExp _regExp = RegExp(r'^[^\s].{0,98}[^\s]$');
}

/// Password of an [User].
///
/// Password allows [User] to perform a sign-in, when combined with a
/// [UserLogin], [UserNum], [UserEmail] or [UserPhone].
@JsonSerializable()
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

  /// Connect the generated [_$UserPasswordFromJson] function to the `fromJson`
  /// factory.
  factory UserPassword.fromJson(Map<String, dynamic> data) =>
      _$UserPasswordFromJson(data);

  /// Connect the generated [_$UserPasswordToJson] function to the `toJson`
  /// method.
  Map<String, dynamic> toJson() => _$UserPasswordToJson(this);

  /// Regular expression for basic [UserPassword] validation.
  static final RegExp _regExp = RegExp(r'^[^\s](.{0,248}[^\s])?$');
}

/// Email address of an [User].
@JsonSerializable()
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

  /// Connect the generated [_$UserEmailFromJson] function to the `fromJson`
  /// factory.
  factory UserEmail.fromJson(Map<String, dynamic> data) =>
      _$UserEmailFromJson(data);

  /// Connect the generated [_$UserEmailToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$UserEmailToJson(this);
}

/// Phone number of an [User].
@JsonSerializable()
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

  /// Connect the generated [_$UserPhoneFromJson] function to the `fromJson`
  /// factory.
  factory UserPhone.fromJson(Map<String, dynamic> data) =>
      _$UserPhoneFromJson(data);

  /// Connect the generated [_$UserPhoneToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$UserPhoneToJson(this);

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
      List.generate(length, (i) {
        // `-` and `_` being the last might not be parsed as a link by some
        // applications.
        if (i == length - 1) {
          final str = chars.replaceFirst('-', '').replaceFirst('_', '');
          return str[r.nextInt(str.length)];
        }

        return chars[r.nextInt(chars.length)];
      }).join(),
    );
  }

  /// Regular expression for basic [ChatDirectLinkSlug] validation.
  static final RegExp _regExp = RegExp(r'^[A-z0-9_-]{1,100}$');
}

/// Status of an [User].
@JsonSerializable()
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

  /// Connect the generated [_$UserTextStatusFromJson] function to the
  /// `fromJson` factory.
  factory UserTextStatus.fromJson(Map<String, dynamic> data) =>
      _$UserTextStatusFromJson(data);

  /// Connect the generated [_$UserTextStatusToJson] function to the `toJson`
  /// method.
  Map<String, dynamic> toJson() => _$UserTextStatusToJson(this);
}

/// [User]'s record in a blocklist of the authenticated [MyUser].
@JsonSerializable()
@HiveType(typeId: ModelTypeId.blocklistRecord)
class BlocklistRecord {
  BlocklistRecord({
    required this.userId,
    this.reason,
    required this.at,
  });

  /// Connect the generated [_$BlocklistRecordFromJson] function to the
  /// `fromJson` factory.
  factory BlocklistRecord.fromJson(Map<String, dynamic> data) =>
      _$BlocklistRecordFromJson(data);

  /// Connect the generated [_$BlocklistRecordToJson] function to the `toJson`
  /// method.
  Map<String, dynamic> toJson() => _$BlocklistRecordToJson(this);

  /// Blocked [User].
  @HiveField(0)
  final UserId userId;

  /// Reason of why the [User] was blocked.
  @HiveField(1)
  final BlocklistReason? reason;

  /// [PreciseDateTime] when the [User] was blocked.
  @HiveField(2)
  final PreciseDateTime at;

  @override
  bool operator ==(Object other) =>
      other is BlocklistRecord && at == other.at && reason == other.reason;

  @override
  int get hashCode => Object.hash(at, reason);
}

/// Reason of blocking a [User] by the authenticated [MyUser].
@JsonSerializable()
@HiveType(typeId: ModelTypeId.blocklistReason)
class BlocklistReason extends NewType<String> {
  const BlocklistReason(super.val);

  /// Connect the generated [_$BlocklistReasonFromJson] function to the
  /// `fromJson` factory.
  factory BlocklistReason.fromJson(Map<String, dynamic> data) =>
      _$BlocklistReasonFromJson(data);

  /// Connect the generated [_$BlocklistReasonToJson] function to the `toJson`
  /// method.
  Map<String, dynamic> toJson() => _$BlocklistReasonToJson(this);
}
