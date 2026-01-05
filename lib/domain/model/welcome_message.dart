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

import 'attachment.dart';
import 'chat_item.dart';
import 'precise_date_time/precise_date_time.dart';

part 'welcome_message.g.dart';

/// Welcome message of a [User] to be posted in new [Chat]-dialogs with him.
@JsonSerializable()
class WelcomeMessage {
  const WelcomeMessage({this.text, this.attachments = const [], this.at});

  /// Constructs a [WelcomeMessage] from the provided [json].
  factory WelcomeMessage.fromJson(Map<String, dynamic> json) =>
      _$WelcomeMessageFromJson(json);

  /// Text of this [WelcomeMessage].
  final ChatMessageText? text;

  /// [Attachment]s of this [WelcomeMessage].
  final List<Attachment> attachments;

  /// [PreciseDateTime] when this [WelcomeMessage] was posted or edited.
  ///
  /// Only available for the owner of this [WelcomeMessage].
  final PreciseDateTime? at;

  /// Returns a [Map] representing this [WelcomeMessage].
  Map<String, dynamic> toJson() => _$WelcomeMessageToJson(this);
}
