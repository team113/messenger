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
import 'package:json_annotation/json_annotation.dart';

import '../model_type_id.dart';
import 'crop_area.dart';
import 'file.dart';

part 'avatar.g.dart';

/// Image representing a particular [User] or a [Chat].
///
/// Specified as relative paths on a files storage. Prepend them with a files
/// storage URL to obtain a link to the concrete image.
abstract class Avatar {
  Avatar({
    required this.full,
    required this.big,
    required this.medium,
    required this.small,
    required this.original,
    this.crop,
  });

  /// Full-sized [ImageFile] representing this [UserAvatar], keeping the
  /// original dimensions.
  @HiveField(0)
  final ImageFile full;

  /// Big view [ImageFile] of this [UserAvatar], square-cropped to its minimum
  /// dimension (either width or height), and scaled to `250px`x`250px`.
  @HiveField(1)
  final ImageFile big;

  /// Medium view [ImageFile] of this [UserAvatar], square-cropped to its
  /// minimum dimension (either width or height), and scaled to `100px`x`100px`.
  @HiveField(2)
  final ImageFile medium;

  /// Small view [ImageFile] of this [UserAvatar], square-cropped to its minimum
  /// dimension (either width or height), and scaled to `46px`x`46px`.
  @HiveField(3)
  final ImageFile small;

  /// Original [ImageFile] representing this [UserAvatar].
  @HiveField(4)
  final ImageFile original;

  /// [CropArea] applied to this [Avatar].
  @HiveField(5)
  final CropArea? crop;
}

/// [Avatar] of a [User].
@JsonSerializable()
@HiveType(typeId: ModelTypeId.userAvatar)
class UserAvatar extends Avatar {
  UserAvatar({
    required super.full,
    required super.big,
    required super.medium,
    required super.small,
    required super.original,
    super.crop,
  });

  /// Constructs a [UserAvatar] from the provided [json].
  factory UserAvatar.fromJson(Map<String, dynamic> json) =>
      _$UserAvatarFromJson(json);

  /// Returns a [Map] representing this [UserAvatar].
  Map<String, dynamic> toJson() => _$UserAvatarToJson(this);
}

/// [Avatar] of a [Chat].
@JsonSerializable()
@HiveType(typeId: ModelTypeId.chatAvatar)
class ChatAvatar extends Avatar {
  ChatAvatar({
    required super.full,
    required super.big,
    required super.medium,
    required super.small,
    required super.original,
    super.crop,
  });

  /// Constructs a [ChatAvatar] from the provided [json].
  factory ChatAvatar.fromJson(Map<String, dynamic> json) =>
      _$ChatAvatarFromJson(json);

  /// Returns a [Map] representing this [ChatAvatar].
  Map<String, dynamic> toJson() => _$ChatAvatarToJson(this);
}
