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

import 'package:get/get_utils/get_utils.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '/api/backend/schema.dart';
import '/domain/model/avatar.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model_type_id.dart';
import '/util/new_type.dart';
import 'mute_duration.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user.dart';

part 'my_user.g.dart';

/// `User` of an application being currently signed-in.
@JsonSerializable()
@HiveType(typeId: ModelTypeId.myUser)
class MyUser extends HiveObject {
  MyUser({
    required this.id,
    required this.num,
    this.login,
    this.name,
    this.bio,
    this.hasPassword = false,
    required this.emails,
    required this.phones,
    this.chatDirectLink,
    this.unreadChatsCount = 0,
    this.status,
    this.callCover,
    this.avatar,
    required this.presenceIndex,
    required this.online,
    this.muted,
    this.blocklistCount,
    this.lastSeenAt,
  });

  /// Constructs a [MyUser] from the provided [json].
  factory MyUser.fromJson(Map<String, dynamic> json) => _$MyUserFromJson(json);

  /// Unique ID of this [MyUser].
  ///
  /// Once assigned it never changes.
  @HiveField(0)
  final UserId id;

  /// Unique number of this [MyUser].
  ///
  /// [num] is intended for an easier [MyUser] identification by other `User`s.
  /// It's just like a telephone number in a real life.
  /// [num] allows [MyUser] to perform a sign-in, when combined with a password.
  /// It may be reused by another User in future, once this [MyUser] becomes
  /// unreachable (sign-in for this [MyUser] is impossible).
  @HiveField(1)
  final UserNum num;

  /// Unique login of this [MyUser].
  ///
  /// [login] allows [MyUser] to perform a sign-in, when combined with a
  /// password.
  @HiveField(2)
  UserLogin? login;

  /// Name of this [MyUser].
  ///
  /// [name] of a [MyUser] is not unique and is intended for displaying a
  /// [MyUser] in a well-readable form. It can be either first name, or last
  /// name of a [MyUser], both of them, or even some nickname.
  @HiveField(3)
  UserName? name;

  /// Arbitrary descriptive information about this [MyUser].
  @HiveField(4)
  UserBio? bio;

  /// Indicator whether this [MyUser] has a password.
  ///
  /// Password allows [MyUser] to perform a sign-in, when combined with a
  /// [login], [num], [emails] or [phones].
  @HiveField(5)
  bool hasPassword;

  /// List of already confirmed email addresses.
  ///
  /// Any confirmed email address can be used in combination with
  /// password to sign-in a [MyUser].
  /// All confirmed email addresses can be used for a password recovery.
  @HiveField(6)
  final MyUserEmails emails;

  /// List of already confirmed phone numbers.
  ///
  /// Any confirmed phone number can be used in combination with
  /// password to sign-in a [MyUser].
  /// All confirmed phone numbers can be used for a password recovery.
  @HiveField(7)
  MyUserPhones phones;

  /// Count of the unread Chats of this [MyUser].
  @HiveField(8)
  int unreadChatsCount;

  /// [ChatDirectLink] to the `Chat` with this [MyUser].
  @HiveField(9)
  ChatDirectLink? chatDirectLink;

  /// Custom text status of this [MyUser].
  @HiveField(10)
  UserTextStatus? status;

  /// Call cover of this [MyUser].
  @HiveField(11)
  UserCallCover? callCover;

  /// Avatar of this [MyUser].
  @HiveField(12)
  UserAvatar? avatar;

  /// Presence of this [MyUser].
  @HiveField(13)
  int presenceIndex;

  Presence get presence => Presence.values[presenceIndex];
  set presence(Presence pres) {
    presenceIndex = pres.index;
  }

  /// Online state of this [MyUser].
  @HiveField(14)
  bool online;

  /// Mute duration of this [MyUser].
  @HiveField(15)
  MuteDuration? muted;

  /// Total count of blocked users.
  @HiveField(16)
  int? blocklistCount;

  /// [PreciseDateTime] this [MyUser] was last seen online at.
  @HiveField(17)
  PreciseDateTime? lastSeenAt;

  @override
  String toString() => '$runtimeType($id)';

  /// Returns a copy of this [MyUser].
  MyUser copyWith() => MyUser(
        id: id,
        num: num,
        login: login,
        name: name,
        bio: bio,
        hasPassword: hasPassword,
        emails: emails.copyWith(),
        phones: phones.copyWith(),
        chatDirectLink: chatDirectLink,
        unreadChatsCount: unreadChatsCount,
        status: status,
        callCover: callCover,
        avatar: avatar,
        presenceIndex: presenceIndex,
        online: online,
        muted: muted,
        blocklistCount: blocklistCount,
        lastSeenAt: lastSeenAt,
      );

  /// Returns a [Map] representing this [MyUser].
  Map<String, dynamic> toJson() => _$MyUserToJson(this);
}

/// List of [UserPhone]s associated with [MyUser].
@HiveType(typeId: ModelTypeId.myUserPhones)
class MyUserPhones {
  MyUserPhones({
    required this.confirmed,
    this.unconfirmed,
  });

  /// Constructs the [MyUserPhones] from the provided [json].
  factory MyUserPhones.fromJson(Map<String, dynamic> json) =>
      _$MyUserPhonesFromJson(json);

  /// List of already confirmed phone numbers.
  ///
  /// Any confirmed phone number can be used in combination with
  /// password to sign-in a [MyUser].
  /// All confirmed phone numbers can be used for a password recovery.
  @HiveField(0)
  List<UserPhone> confirmed;

  /// Phone number that still requires a confirmation.
  ///
  /// Unconfirmed phone number doesn't provide any functionality like
  /// confirmed ones do.
  /// Unconfirmed phone number can be moved to confirmed ones after
  /// completion of confirmation process only.
  @HiveField(1)
  UserPhone? unconfirmed;

  /// Returns a copy of these [MyUserPhones].
  MyUserPhones copyWith() =>
      MyUserPhones(confirmed: confirmed, unconfirmed: unconfirmed);

  /// Returns a [Map] representing these [MyUserPhones].
  Map<String, dynamic> toJson() => _$MyUserPhonesToJson(this);
}

/// List of [UserEmail]s associated with [MyUser].
@JsonSerializable()
@HiveType(typeId: ModelTypeId.myUserEmails)
class MyUserEmails {
  MyUserEmails({
    required this.confirmed,
    this.unconfirmed,
  });

  /// Constructs the [MyUserEmails] from the provided [json].
  factory MyUserEmails.fromJson(Map<String, dynamic> json) =>
      _$MyUserEmailsFromJson(json);

  /// List of already confirmed email addresses.
  ///
  /// Any confirmed email address can be used in combination with
  /// password to sign-in a [MyUser].
  /// All confirmed email addresses can be used for a password recovery.
  @HiveField(0)
  List<UserEmail> confirmed;

  /// Email address that still requires a confirmation.
  ///
  /// Unconfirmed email address doesn't provide any functionality like
  /// confirmed ones do.
  /// Unconfirmed email address can be moved to confirmed ones after
  /// completion of confirmation process only.
  @HiveField(1)
  UserEmail? unconfirmed;

  /// Returns a copy of these [MyUserEmails].
  MyUserEmails copyWith() =>
      MyUserEmails(confirmed: confirmed, unconfirmed: unconfirmed);

  /// Returns a [Map] representing these [MyUserEmails].
  Map<String, dynamic> toJson() => _$MyUserEmailsToJson(this);
}

/// Confirmation code used by [MyUser].
class ConfirmationCode extends NewType<String> {
  const ConfirmationCode._(super.val);

  ConfirmationCode(String val) : super(val) {
    if (val.length != 4) {
      throw const FormatException('Must be 4 characters long');
    } else if (!val.isNumericOnly) {
      throw const FormatException('Must contain only numbers');
    }
  }

  /// Creates an object without any validation.
  const factory ConfirmationCode.unchecked(String val) = ConfirmationCode._;

  /// Constructs a [ConfirmationCode] from the provided [val].
  factory ConfirmationCode.fromJson(String val) = ConfirmationCode.unchecked;

  /// Parses the provided [val] as a [ConfirmationCode], if [val] meets the
  /// validation, or returns `null` otherwise.
  static ConfirmationCode? tryParse(String val) {
    try {
      return ConfirmationCode(val);
    } catch (_) {
      return null;
    }
  }

  /// Returns a [String] representing this [ConfirmationCode].
  String toJson() => val;
}
