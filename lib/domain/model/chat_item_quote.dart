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

import '/api/backend/schema.dart' show ChatItemQuoteInput;
import 'attachment.dart';
import 'chat_item.dart';

/// Quotes of the [ChatItem]s to be forwarded.
class ChatItemQuote {
  ChatItemQuote({
    required this.item,
    required this.withText,
    required this.attachments,
  });

  /// [ChatItem] to be forwarded.
  final ChatItem item;

  /// Indicator whether a forward should contain the full [ChatMessageText] of
  /// the original [ChatItem] (if it contains any).
  final bool withText;

  /// IDs of the [ChatItem]'s [Attachment]s to be forwarded.
  ///
  /// If no [Attachment]s are provided, then [ChatForward] will only contain a
  /// [ChatMessageText].
  final List<AttachmentId> attachments;
}
