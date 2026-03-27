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

import 'attachment.dart';
import 'chat_item.dart';

/// New [ChatMessageText] to assign to the [ChatMessage].
class ChatMessageTextInput {
  const ChatMessageTextInput(this.changed);

  /// New [ChatMessageText].
  ///
  /// `null` means that the previous [ChatMessageText] should be deleted.
  final ChatMessageText? changed;
}

/// New [Attachment]s to assign to the [ChatMessage].
class ChatMessageAttachmentsInput {
  const ChatMessageAttachmentsInput(this.changed);

  /// New [Attachment]s.
  final List<Attachment> changed;
}

/// New replied [ChatItemId]s to assign to the [ChatMessage].
class ChatMessageRepliesInput {
  const ChatMessageRepliesInput(this.changed);

  /// New replies IDs.
  final List<ChatItemId> changed;
}
