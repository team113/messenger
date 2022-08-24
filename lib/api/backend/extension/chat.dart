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
import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/crop_area.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/user.dart';
import '/provider/hive/chat_item.dart';
import '/provider/hive/chat.dart';
import '/store/chat.dart';
import '/store/model/chat_item.dart';
import 'call.dart';
import 'user.dart';

/// Extension adding models construction from a [ChatMixin].
extension ChatConversion on ChatMixin {
  /// Constructs a new [Chat] from this [ChatMixin].
  Chat toModel() => Chat(
        id,
        avatar: avatar?.toModel(),
        name: name,
        members: members.nodes
            .map((e) => ChatMember(e.user.toModel(), e.joinedAt))
            .toList(),
        kindIndex: kind.index,
        isHidden: isHidden,
        muted: muted != null
            ? muted!.$$typename == 'MuteForeverDuration'
                ? MuteDuration.forever()
                : MuteDuration.until(
                    (muted! as ChatMixin$Muted$MuteUntilDuration).until)
            : null,
        directLink: directLink != null
            ? ChatDirectLink(
                slug: directLink!.slug,
                usageCount: directLink!.usageCount,
              )
            : null,
        createdAt: createdAt,
        updatedAt: updatedAt,
        lastReads:
            lastReads.map((e) => LastChatRead(e.memberId, e.at)).toList(),
        lastDelivery: lastDelivery,
        lastItem: lastItem?.toHive().first.value,
        lastReadItem: lastReadItem?.toHive().first.value,
        unreadCount: unreadCount,
        totalCount: totalCount,
        currentCall: currentCall?.toModel(),
      );

  /// Constructs a new [HiveChat] from this [ChatMixin].
  HiveChat toHive() => HiveChat(
        toModel(),
        ver,
        lastItem?.cursor,
        lastReadItem?.cursor,
      );

  /// Constructs a new [ChatData] from this [ChatMixin].
  ChatData toData() {
    var lastItem = this.lastItem?.toHive();
    var lastReadItem = this.lastReadItem?.toHive();

    return ChatData(
      toHive(),
      lastItem,
      lastReadItem,
    );
  }
}

/// Extension adding models construction from [ChatMemberInfoMixin].
extension ChatMemberInfoConversion on ChatMemberInfoMixin {
  /// Constructs a new [ChatMemberInfo] from this [ChatMemberInfoMixin].
  ChatMemberInfo toModel() => ChatMemberInfo(
        id,
        chatId,
        authorId,
        at,
        user: user.toModel(),
        actionIndex: action.index,
      );

  /// Constructs a new [HiveChatMemberInfo] from this [ChatMemberInfoMixin].
  HiveChatMemberInfo toHive(ChatItemsCursor cursor) =>
      HiveChatMemberInfo(toModel(), cursor, ver);
}

/// Extension adding models construction from [ChatCallMixin].
extension ChatCallConversion on ChatCallMixin {
  /// Constructs a new [HiveChatCall] from this [ChatCallMixin].
  HiveChatCall toHive(ChatItemsCursor cursor) =>
      HiveChatCall(toModel(), cursor, ver);
}

/// Extension adding models construction from [ChatMessageMixin].
extension ChatMessageConversion on ChatMessageMixin {
  /// Constructs a new [HiveChatItem]s from this [ChatMessageMixin].
  List<HiveChatItem> toHive(ChatItemsCursor cursor) {
    List<HiveChatItem>? items;
    if (repliesTo != null) {
      items = repliesTo!.toHive();
    }

    return [
      HiveChatMessage(
        ChatMessage(
          id,
          chatId,
          authorId,
          at,
          repliesTo: items?.first.value,
          text: text,
          editedAt: editedAt,
          attachments: attachments.map((e) => e.toModel()).toList(),
        ),
        cursor,
        ver,
        repliesTo?.cursor,
      ),
      if (items != null) ...items,
    ];
  }
}

/// Extension adding models construction from [NestedChatMessageMixin].
extension NestedChatMessageConversion on NestedChatMessageMixin {
  /// Constructs a new [ChatMessage] from this [NestedChatMessageMixin].
  ChatMessage toModel() => ChatMessage(
        id,
        chatId,
        authorId,
        at,
        repliesTo: null,
        text: text,
        editedAt: editedAt,
        attachments: attachments.map((e) {
          if (e.$$typename == 'ImageAttachment') {
            e as NestedChatMessageMixin$Attachments$ImageAttachment;
            return ImageAttachment(
              id: e.id,
              original: Original(e.original),
              filename: e.filename,
              size: e.size,
              big: e.big,
              medium: e.medium,
              small: e.small,
            );
          }

          return FileAttachment(
            id: e.id,
            original: Original(e.original),
            filename: e.filename,
            size: e.size,
          );
        }).toList(),
      );

  /// Constructs a new [HiveChatMessage] from this [NestedChatMessageMixin].
  HiveChatMessage toHive(ChatItemsCursor cursor) =>
      HiveChatMessage(toModel(), cursor, ver, repliesTo?.cursor);
}

/// Extension adding models construction from [ChatForwardMixin].
extension ChatForwardConversion on ChatForwardMixin {
  /// Constructs a new [HiveChatItem]s from this [ChatForwardMixin].
  List<HiveChatItem> toHive(ChatItemsCursor cursor) {
    List<HiveChatItem> nested = item.toHive();
    return [
      HiveChatForward(
        ChatForward(
          id,
          chatId,
          authorId,
          at,
          item: nested.first.value,
        ),
        cursor,
        ver,
        item.cursor,
      ),
      ...nested.skip(1),
    ];
  }
}

/// Extension adding models construction from [NestedChatForwardMixin].
extension NestedChatForwardConversion on NestedChatForwardMixin {
  /// Constructs a new [ChatForward] from this [NestedChatForwardMixin].
  ChatForward toModel() => ChatForward(
        id,
        chatId,
        authorId,
        at,
        item: null,
      );

  /// Constructs a new [HiveChatForward] from this [NestedChatForwardMixin].
  HiveChatForward toHive(ChatItemsCursor cursor) =>
      HiveChatForward(toModel(), cursor, ver, item.cursor);
}

/// Extension adding models construction from
/// [GetMessages$Query$Chat$Items$Edges].
extension GetMessagesConversion on GetMessages$Query$Chat$Items$Edges {
  /// Constructs a new [HiveChatItem]s from this
  /// [GetMessages$Query$Chat$Items$Edges].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatMixin$LastItem].
extension ChatLastItemConversion on ChatMixin$LastItem {
  /// Constructs a new [HiveChatItem]s from this [ChatMixin$LastItem].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatMixin$LastReadItem].
extension ChatLastReadItemConversion on ChatMixin$LastReadItem {
  /// Constructs a new [HiveChatItem]s from this [ChatMixin$LastReadItem].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatForwardMixin$Item].
extension ChatForwardMixinItemConversion on ChatForwardMixin$Item {
  /// Constructs a new [HiveChatItem]s from this [ChatForwardMixin$Item].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatMessageMixin$RepliesTo].
extension ChatMessageMixinRepliesToConversion on ChatMessageMixin$RepliesTo {
  /// Constructs a new [HiveChatItem]s from this [ChatMessageMixin$RepliesTo].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from
/// [ChatEventsVersionedMixin$Events$EventChatItemPosted$Item].
extension EventChatItemPostedConversion
    on ChatEventsVersionedMixin$Events$EventChatItemPosted$Item {
  /// Constructs a new [HiveChatItem]s from this
  /// [ChatEventsVersionedMixin$Events$EventChatItemPosted$Item].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from
/// [ChatEventsVersionedMixin$Events$EventChatLastItemUpdated$LastItem].
extension EventChatLastItemUpdatedConversion
    on ChatEventsVersionedMixin$Events$EventChatLastItemUpdated$LastItem {
  /// Constructs a new [HiveChatItem]s from this
  /// [ChatEventsVersionedMixin$Events$EventChatLastItemUpdated$LastItem].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Constructs a new [HiveChatItem]s based on the [node] and [cursor].
List<HiveChatItem> _chatItem(dynamic node, ChatItemsCursor cursor) {
  if (node is ChatMemberInfoMixin) {
    return [node.toHive(cursor)];
  } else if (node is ChatCallMixin) {
    return [node.toHive(cursor)];
  } else if (node is ChatMessageMixin) {
    return node.toHive(cursor);
  } else if (node is NestedChatMessageMixin) {
    return [node.toHive(cursor)];
  } else if (node is ChatForwardMixin) {
    return node.toHive(cursor);
  } else if (node is NestedChatForwardMixin) {
    return [node.toHive(cursor)];
  }

  throw UnimplementedError('$node is not implemented');
}

/// Extension adding models construction from [ChatAvatarMixin].
extension ChatAvatarConversion on ChatAvatarMixin {
  /// Constructs a new [ChatAvatar] from this [ChatAvatarMixin].
  ChatAvatar toModel() => ChatAvatar(
        medium: medium,
        small: small,
        original: original,
        full: full,
        big: big,
        crop: crop == null
            ? null
            : CropArea(
                topLeft: CropPoint(
                  x: crop!.topLeft.x,
                  y: crop!.topLeft.y,
                ),
                bottomRight: CropPoint(
                  x: crop!.bottomRight.x,
                  y: crop!.bottomRight.y,
                ),
              ),
      );
}

/// Extension adding models construction from an
/// [UploadAttachment$Mutation$UploadAttachment$UploadAttachmentOk$Attachment].
extension UploadAttachmentConversion
    on UploadAttachment$Mutation$UploadAttachment$UploadAttachmentOk$Attachment {
  /// Constructs a new [Attachment] from this
  /// [UploadAttachment$Mutation$UploadAttachment$UploadAttachmentOk$Attachment].
  Attachment toModel() => _attachment(this);
}

/// Extension adding models construction from [ChatMessageMixin$Attachments].
extension ChatMessageAttachmentsConversion on ChatMessageMixin$Attachments {
  /// Constructs a new [Attachment] from this [ChatMessageMixin$Attachments].
  Attachment toModel() => _attachment(this);
}

/// Extension adding models construction from an [ImageAttachmentMixin].
extension ImageAttachmentConversion on ImageAttachmentMixin {
  /// Constructs a new [ImageAttachment] from this [ImageAttachmentMixin].
  ImageAttachment toModel() => ImageAttachment(
        id: id,
        original: Original(original),
        filename: filename,
        size: size,
        big: big,
        medium: medium,
        small: small,
      );
}

/// Extension adding models construction from a [FileAttachmentMixin].
extension FileAttachmentConversion on FileAttachmentMixin {
  /// Constructs a new [FileAttachment] from this [FileAttachmentMixin].
  FileAttachment toModel() => FileAttachment(
        id: id,
        original: Original(original),
        filename: filename,
        size: size,
      );
}

/// Constructs a new [Attachment] based on the [node].
Attachment _attachment(dynamic node) {
  if (node is ImageAttachmentMixin) {
    return node.toModel();
  } else if (node is FileAttachmentMixin) {
    return node.toModel();
  }

  throw UnimplementedError('$node is not implemented');
}
