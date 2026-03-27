// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:json_annotation/json_annotation.dart';

import 'crop_area.dart';
import 'file.dart';
import 'native_file.dart';

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
  final ImageFile full;

  /// Big view [ImageFile] of this [UserAvatar], square-cropped to its minimum
  /// dimension (either width or height), and scaled to `250px`x`250px`.
  final ImageFile big;

  /// Medium view [ImageFile] of this [UserAvatar], square-cropped to its
  /// minimum dimension (either width or height), and scaled to `100px`x`100px`.
  final ImageFile medium;

  /// Small view [ImageFile] of this [UserAvatar], square-cropped to its minimum
  /// dimension (either width or height), and scaled to `46px`x`46px`.
  final ImageFile small;

  /// Original [ImageFile] representing this [UserAvatar].
  final ImageFile original;

  /// [CropArea] applied to this [Avatar].
  final CropArea? crop;
}

/// [Avatar] of a [User].
@JsonSerializable()
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

/// [Avatar] from the [file].
class LocalAvatar extends Avatar {
  LocalAvatar({super.crop, required this.file})
    : super(
        full: ImageFile(relativeRef: ''),
        big: ImageFile(relativeRef: ''),
        medium: ImageFile(relativeRef: ''),
        small: ImageFile(relativeRef: ''),
        original: ImageFile(relativeRef: ''),
      );

  /// [NativeFile] this avatar should be rendered from.
  final NativeFile file;
}
