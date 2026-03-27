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

import '/domain/model/chat_item.dart';
import '/util/new_type.dart';
import 'chat_item.dart';

part 'chat_call.g.dart';

/// Persisted in storage [ChatCall]'s [value].
@JsonSerializable()
class DtoChatCall extends DtoChatItem {
  DtoChatCall(super.value, super.cursor, super.ver);

  /// Constructs a [DtoChatCall] from the provided [json].
  factory DtoChatCall.fromJson(Map<String, dynamic> json) =>
      _$DtoChatCallFromJson(json);

  /// Returns a [Map] representing this [DtoChatCall].
  @override
  Map<String, dynamic> toJson() =>
      _$DtoChatCallToJson(this)..['runtimeType'] = 'DtoChatCall';
}

/// Cursor of an [OngoingCall] position.
class IncomingChatCallsCursor extends NewType<String> {
  const IncomingChatCallsCursor(super.val);
}
