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

part 'user_call_cover.g.dart';

/// Call cover of an [User].
///
/// Specified as relative paths on a files storage. Prepend them with a files
/// storage URL to obtain a link to the concrete image.
@JsonSerializable()
class UserCallCover {
  UserCallCover({
    required this.full,
    required this.vertical,
    required this.square,
    required this.original,
    this.crop,
  });

  /// Constructs a [UserCallCover] from the provided [json].
  factory UserCallCover.fromJson(Map<String, dynamic> json) =>
      _$UserCallCoverFromJson(json);

  /// Original image [StorageFile] representing this [UserCallCover].
  final ImageFile original;

  /// Full-sized [UserCallCover]'s image [StorageFile], keeping the original
  /// sizes.
  final ImageFile full;

  /// Vertical [UserCallCover]'s view image [StorageFile] of `675px`x`900px`
  /// size.
  final ImageFile vertical;

  /// Square [[UserCallCover]]'s view image [StorageFile] of `300px`x`300px`
  /// size.
  final ImageFile square;

  /// [CropArea] applied to the original [ImageFile] for creating this
  /// [UserCallCover].
  final CropArea? crop;

  /// Returns a [Map] representing this [UserCallCover].
  Map<String, dynamic> toJson() => _$UserCallCoverToJson(this);
}
