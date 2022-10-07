// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '../schema.dart';
import '/domain/model/chat_call.dart';
import 'user.dart';

/// Extension adding models construction from a [ChatCallMemberMixin].
extension ChatCallMemberConversion on ChatCallMemberMixin {
  /// Constructs a new [ChatCallMember] from this [ChatCallMemberMixin].
  ChatCallMember toModel() => ChatCallMember(
        user: user.toModel(),
        handRaised: handRaised,
        joinedAt: joinedAt,
      );
}

/// Extension adding models construction from [ChatCallMixin].
extension ChatCallConversion on ChatCallMixin {
  /// Constructs a new [ChatCall] from this [ChatCallMixin].
  ChatCall toModel() => ChatCall(
        id,
        chatId,
        authorId,
        at,
        caller: caller?.toModel(),
        members: members.map((e) => e.toModel()).toList(),
        withVideo: withVideo,
        conversationStartedAt: conversationStartedAt,
        finishReasonIndex: finishReason?.index,
        finishedAt: finishedAt,
        joinLink: joinLink,
        answered: answered,
      );
}
