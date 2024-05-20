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

import 'package:hive/hive.dart';

import '../model_type_id.dart';
import '/util/new_type.dart';
import 'chat.dart';
import 'user.dart';

part 'contact.g.dart';

/// Record in an address book of the authenticated [MyUser].
///
/// It may be linked with some real [User]s, but also may not.
@HiveType(typeId: ModelTypeId.chatContact)
class ChatContact extends HiveObject implements Comparable<ChatContact> {
  ChatContact(
    this.id, {
    required this.name,
    List<User>? users,
    List<Chat>? groups,
    List<UserPhone>? phones,
    List<UserEmail>? emails,
    this.favoritePosition,
  })  : users = users ?? List.empty(growable: true),
        groups = groups ?? List.empty(growable: true),
        phones = phones ?? List.empty(growable: true),
        emails = emails ?? List.empty(growable: true);

  /// Unique ID of this [ChatContact].
  @HiveField(0)
  final ChatContactId id;

  /// Custom [UserName] of this [ChatContact] given by the authenticated
  /// [MyUser].
  @HiveField(1)
  UserName name;

  /// [User]s linked to this [ChatContact].
  ///
  /// Guaranteed to have no duplicates.
  @HiveField(2)
  List<User> users;

  /// [Chat]-groups linked to this [ChatContact].
  ///
  /// Guaranteed to have no duplicates.
  @HiveField(3)
  List<Chat> groups;

  /// List of [UserEmail]s provided by this [ChatContact].
  ///
  /// Guaranteed to have no duplicates.
  @HiveField(4)
  List<UserEmail> emails;

  /// List of [UserPhone]s provided by this [ChatContact].
  ///
  /// Guaranteed to have no duplicates.
  @HiveField(5)
  List<UserPhone> phones;

  /// Position of this [ChatContact] in a favorites list of the authenticated
  /// [MyUser].
  @HiveField(6)
  ChatContactFavoritePosition? favoritePosition;

  @override
  int compareTo(ChatContact other) {
    int? result;

    if (favoritePosition != null && other.favoritePosition == null) {
      return -1;
    } else if (favoritePosition == null && other.favoritePosition != null) {
      return 1;
    } else if (favoritePosition != null && other.favoritePosition != null) {
      result ??= other.favoritePosition!.compareTo(favoritePosition!);
    }

    result ??= name.val.compareTo(other.name.val);

    if (result == 0) {
      return id.val.compareTo(other.id.val);
    }

    return result;
  }
}

/// Unique ID of a [ChatContact].
@HiveType(typeId: ModelTypeId.chatContactId)
class ChatContactId extends NewType<String>
    implements Comparable<ChatContactId> {
  const ChatContactId(super.val);

  /// Constructs a [ChatContactId] from the provided [val].
  factory ChatContactId.fromJson(String val) = ChatContactId;

  @override
  int compareTo(ChatContactId other) => val.compareTo(other.val);

  /// Returns a [String] representing this [ChatContactId].
  String toJson() => val;
}

/// Position of a [ChatContact] in a favorites list of the authenticated
/// [MyUser].
@HiveType(typeId: ModelTypeId.chatContactFavoritePosition)
class ChatContactFavoritePosition extends NewType<double>
    implements Comparable<ChatContactFavoritePosition> {
  const ChatContactFavoritePosition(super.val);

  /// Parses the provided [val] as a [ChatContactFavoritePosition].
  static ChatContactFavoritePosition parse(String val) =>
      ChatContactFavoritePosition(double.parse(val));

  @override
  int compareTo(ChatContactFavoritePosition other) => val.compareTo(other.val);
}
