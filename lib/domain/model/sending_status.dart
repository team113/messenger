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
import 'package:hive/hive.dart';

import '/domain/model_type_id.dart';

part 'sending_status.g.dart';

/// Sending status of some request, e.g. posting a [ChatItem] or uploading an
/// [Attachment].
@HiveType(typeId: ModelTypeId.sendingStatus)
enum SendingStatus {
  /// Request is sending.
  @HiveField(0)
  sending,

  /// Successfully sent.
  @HiveField(1)
  sent,

  /// Error occurred.
  @HiveField(2)
  error,
}

/// Extension adding methods to construct the [SendingStatus] to/from primitive
/// types.
///
/// Intended to be used as [JsonKey.toJson] and [JsonKey.fromJson] methods.
extension SendingStatusJson on SendingStatus {
  /// Returns a [String] representing the [value].
  static String toJson(Rx<SendingStatus> value) => value.value.name;
}
