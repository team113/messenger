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
import '/domain/model/mute_duration.dart';
import '/domain/model/user.dart';
import '/provider/hive/chat_item.dart';
import '/provider/hive/chat.dart';
import '/store/chat.dart';
import '/store/model/chat_item.dart';
import 'call.dart';
import 'file.dart';
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
        ongoingCall: ongoingCall?.toModel(),
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
    List<HiveChatItem> items =
        repliesTo.map((e) => e.toHive()).expand((e) => e).toList();

    return [
      HiveChatMessage(
        ChatMessage(
          id,
          chatId,
          authorId,
          at,
          repliesTo: items.map((e) => e.value).toList(),
          text: text,
          editedAt: editedAt,
          attachments: attachments.map((e) => e.toModel()).toList(),
        ),
        cursor,
        ver,
        repliesTo.map((e) => e.cursor).toList(),
      ),
      ...items,
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
        repliesTo: [],
        text: text,
        editedAt: editedAt,
        attachments: attachments.map((e) => e.toModel()).toList(),
      );

  /// Constructs a new [HiveChatMessage] from this [NestedChatMessageMixin].
  HiveChatMessage toHive(ChatItemsCursor cursor) => HiveChatMessage(
        toModel(),
        cursor,
        ver,
        repliesTo.map((e) => e.cursor).toList(),
      );
}

/// Extension adding models construction from [ChatForwardMixin].
extension ChatForwardConversion on ChatForwardMixin {
  /// Constructs the new [HiveChatItem]s from this [ChatForwardMixin].
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
  /// Constructs the new [HiveChatForward]s from this [NestedChatForwardMixin].
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

/// Extension adding models construction from [NestedChatForwardMixin$Item].
extension NestedChatForwardItemConversion on NestedChatForwardMixin$Item {
  /// Constructs a new [HiveChatItem]s from this [NestedChatForwardMixin$Item].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from
/// [GetMessages$Query$Chat$Items$Edges].
extension GetMessagesConversion on GetMessages$Query$Chat$Items$Edges {
  /// Constructs the new [HiveChatItem]s from this
  /// [GetMessages$Query$Chat$Items$Edges].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatMixin$LastItem].
extension ChatLastItemConversion on ChatMixin$LastItem {
  /// Constructs the new [HiveChatItem]s from this [ChatMixin$LastItem].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatMixin$LastReadItem].
extension ChatLastReadItemConversion on ChatMixin$LastReadItem {
  /// Constructs the new [HiveChatItem]s from this [ChatMixin$LastReadItem].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatForwardMixin$Item].
extension ChatForwardMixinItemConversion on ChatForwardMixin$Item {
  /// Constructs the new [HiveChatItem]s from this [ChatForwardMixin$Item].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatMessageMixin$RepliesTo].
extension ChatMessageMixinRepliesToConversion on ChatMessageMixin$RepliesTo {
  /// Constructs the new [HiveChatItem]s from this [ChatMessageMixin$RepliesTo].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from
/// [ChatEventsVersionedMixin$Events$EventChatItemPosted$Item].
extension EventChatItemPostedConversion
    on ChatEventsVersionedMixin$Events$EventChatItemPosted$Item {
  /// Constructs the new [HiveChatItem]s from this
  /// [ChatEventsVersionedMixin$Events$EventChatItemPosted$Item].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from
/// [ChatEventsVersionedMixin$Events$EventChatLastItemUpdated$LastItem].
extension EventChatLastItemUpdatedConversion
    on ChatEventsVersionedMixin$Events$EventChatLastItemUpdated$LastItem {
  /// Constructs the new [HiveChatItem]s from this
  /// [ChatEventsVersionedMixin$Events$EventChatLastItemUpdated$LastItem].
  List<HiveChatItem> toHive() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatAvatarMixin].
extension ChatAvatarConversion on ChatAvatarMixin {
  /// Constructs a new [ChatAvatar] from this [ChatAvatarMixin].
  ChatAvatar toModel() => ChatAvatar(
        medium: medium.toModel(),
        small: small.toModel(),
        original: original.toModel(),
        full: full.toModel(),
        big: big.toModel(),
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

/// Extension adding models construction from
/// [NestedChatMessageMixin$Attachments].
extension NestedChatMessageAttachmentsConversion
    on NestedChatMessageMixin$Attachments {
  /// Constructs a new [Attachment] from this
  /// [NestedChatMessageMixin$Attachments].
  Attachment toModel() => _attachment(this);
}

/// Extension adding models construction from an [ImageAttachmentMixin].
extension ImageAttachmentConversion on ImageAttachmentMixin {
  /// Constructs a new [ImageAttachment] from this [ImageAttachmentMixin].
  ImageAttachment toModel() => ImageAttachment(
        id: id,
        original: original.toModel(),
        filename: filename,
        big: big.toModel(),
        medium: medium.toModel(),
        small: small.toModel(),
      );
}

/// Extension adding models construction from a [FileAttachmentMixin].
extension FileAttachmentConversion on FileAttachmentMixin {
  /// Constructs a new [FileAttachment] from this [FileAttachmentMixin].
  FileAttachment toModel() => FileAttachment(
        id: id,
        original: original.toModel(),
        filename: filename,
      );
}

/// Extension adding models construction from a [GetAttachments$Query$ChatItem].
extension GetAttachmentsConversion on GetAttachments$Query$ChatItem {
  /// Constructs a new list of [Attachment]s from this
  /// [GetAttachments$Query$ChatItem].
  List<Attachment> toModel() {
    final List<Attachment> attachments = [];

    if (node.$$typename == 'ChatMessage') {
      var message = node as GetAttachments$Query$ChatItem$Node$ChatMessage;
      attachments.addAll(message.attachments.map((e) => e.toModel()));

      if (message.repliesTo.isNotEmpty) {
        for (var r in message.repliesTo) {
          if (r.node.$$typename == 'ChatMessage') {
            var replied = r.node
                as GetAttachments$Query$ChatItem$Node$ChatMessage$RepliesTo$Node$ChatMessage;
            attachments.addAll(replied.attachments.map((e) => e.toModel()));
          }
        }
      }
    } else if (node.$$typename == 'ChatForward') {
      var message = node as GetAttachments$Query$ChatItem$Node$ChatForward;
      if (message.item.node.$$typename == 'ChatMessage') {
        var node = message.item.node
            as GetAttachments$Query$ChatItem$Node$ChatForward$Item$Node$ChatMessage;
        attachments.addAll(node.attachments.map((e) => e.toModel()));
      }
    }

    return attachments;
  }
}

/// Extension adding models construction from
/// [GetAttachments$Query$ChatItem$Node$ChatMessage$Attachments].
extension GetAttachmentsChatMessageAttachmentConversion
    on GetAttachments$Query$ChatItem$Node$ChatMessage$Attachments {
  /// Constructs a new [Attachment] from this
  /// [GetAttachments$Query$ChatItem$Node$ChatMessage$Attachments].
  Attachment toModel() => _attachment(this);
}

/// Extension adding models construction from
/// [GetAttachments$Query$ChatItem$Node$ChatForward$Item$Node$ChatMessage$Attachments].
extension GetAttachmentsChatForwardAttachmentConversion
    on GetAttachments$Query$ChatItem$Node$ChatForward$Item$Node$ChatMessage$Attachments {
  /// Constructs a new [Attachment] from this
  /// [GetAttachments$Query$ChatItem$Node$ChatForward$Item$Node$ChatMessage$Attachments].
  Attachment toModel() => _attachment(this);
}

/// Extension adding models construction from
/// [GetAttachments$Query$ChatItem$Node$ChatMessage$RepliesTo$Node$ChatMessage$Attachments].
extension GetAttachmentsChatMessageRepliesToAttachmentConversion
    on GetAttachments$Query$ChatItem$Node$ChatMessage$RepliesTo$Node$ChatMessage$Attachments {
  /// Constructs a new [Attachment] from this
  /// [GetAttachments$Query$ChatItem$Node$ChatMessage$RepliesTo$Node$ChatMessage$Attachments].
  Attachment toModel() => _attachment(this);
}

/// Extension adding models construction from [Muting].
extension MutingToMuteDurationConversion on Muting {
  /// Constructs a new [MuteDuration] from this [Muting].
  MuteDuration toModel() {
    if (duration == null) {
      return MuteDuration.forever();
    }

    return MuteDuration.until(duration!);
  }
}

/// Extension adding models construction from
/// [ChatEventsVersionedMixin$Events$EventChatMuted$Duration].
extension EventChatMuted$DurationConversion
    on ChatEventsVersionedMixin$Events$EventChatMuted$Duration {
  /// Constructs a new [MuteDuration] from this
  /// [ChatEventsVersionedMixin$Events$EventChatMuted$Duration].
  MuteDuration toModel() {
    if ($$typename == 'MuteForeverDuration') {
      return MuteDuration.forever();
    }

    return MuteDuration.until((this
            as ChatEventsVersionedMixin$Events$EventChatMuted$Duration$MuteUntilDuration)
        .until);
  }
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
    return node.toHive(cursor);
  }

  throw UnimplementedError('$node is not implemented');
}
