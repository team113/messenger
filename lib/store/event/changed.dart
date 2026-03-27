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

import 'package:collection/collection.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';

/// Changed [ChatMessageText].
class ChangedChatMessageText {
  const ChangedChatMessageText(this.changed);

  /// Changed [ChatMessageText].
  ///
  /// `null` means that the previous [ChatMessageText] was deleted.
  final ChatMessageText? changed;

  @override
  bool operator ==(Object other) =>
      other is ChangedChatMessageText && other.changed == changed;

  @override
  int get hashCode => changed.hashCode;
}

/// Changed [Attachment]s.
class ChangedChatMessageAttachments {
  const ChangedChatMessageAttachments(this.attachments);

  /// New [Attachment]s.
  ///
  /// Empty list means that the previous [Attachment]s were deleted.
  final List<Attachment> attachments;

  @override
  bool operator ==(Object other) =>
      other is ChangedChatMessageAttachments &&
      const ListEquality().equals(other.attachments, attachments);

  @override
  int get hashCode => attachments.hashCode;
}
