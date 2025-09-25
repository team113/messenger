// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '../schema.dart';
import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/crop_area.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/user.dart';
import '/store/chat.dart';
import '/store/model/chat_call.dart';
import '/store/model/chat_item.dart';
import '/store/model/chat.dart';
import '/store/model/chat_member.dart';
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
    isArchived: isArchived,
    muted: muted != null
        ? muted!.$$typename == 'MuteForeverDuration'
              ? MuteDuration.forever()
              : MuteDuration.until(
                  (muted! as ChatMixin$Muted$MuteUntilDuration).until,
                )
        : null,
    directLink: directLink != null
        ? ChatDirectLink(
            slug: directLink!.slug,
            usageCount: directLink!.usageCount,
            createdAt: createdAt,
          )
        : null,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lastReads: lastReads.map((e) => LastChatRead(e.memberId, e.at)).toList(),
    lastDelivery: lastDelivery,
    lastItem: lastItem?.toDto().value,
    lastReadItem: lastReadItem?.toDto().value.id,
    unreadCount: unreadCount,
    totalCount: totalCount,
    ongoingCall: ongoingCall?.toModel(),
    favoritePosition: favoritePosition,
    membersCount: members.totalCount,
  );

  /// Constructs a new [DtoChat] from this [ChatMixin].
  DtoChat toDto(RecentChatsCursor? recent, FavoriteChatsCursor? favorite) =>
      DtoChat(
        toModel(),
        ver,
        lastItem?.cursor,
        lastReadItem?.cursor,
        recent,
        favorite,
      );

  /// Constructs a new [ChatData] from this [ChatMixin].
  ChatData toData([RecentChatsCursor? recent, FavoriteChatsCursor? favorite]) {
    final lastItem = this.lastItem?.toDto();
    final lastReadItem = this.lastReadItem?.toDto();
    return ChatData(toDto(recent, favorite), lastItem, lastReadItem);
  }
}

/// Extension adding models construction from [ChatInfoMixin].
extension ChatInfoConversion on ChatInfoMixin {
  /// Constructs a new [ChatInfo] from this [ChatInfoMixin].
  ChatInfo toModel() =>
      ChatInfo(id, chatId, author.toModel(), at, action: action.toModel());

  /// Constructs a new [DtoChatInfo] from this [ChatInfoMixin].
  DtoChatInfo toDto(ChatItemsCursor cursor) =>
      DtoChatInfo(toModel(), cursor, ver);
}

/// Extension adding models construction from [ChatInfoMixin$Action].
extension ChatInfoActionConversion on ChatInfoMixin$Action {
  /// Constructs a new [ChatInfoAction] from this [ChatInfoMixin$Action].
  ChatInfoAction toModel() {
    if ($$typename == 'ChatInfoActionAvatarUpdated') {
      final model = this as ChatInfoMixin$Action$ChatInfoActionAvatarUpdated;
      return ChatInfoActionAvatarUpdated(model.avatar?.toModel());
    } else if ($$typename == 'ChatInfoActionCreated') {
      final model = this as ChatInfoMixin$Action$ChatInfoActionCreated;
      return ChatInfoActionCreated(model.directLinkSlug);
    } else if ($$typename == 'ChatInfoActionMemberAdded') {
      final model = this as ChatInfoMixin$Action$ChatInfoActionMemberAdded;
      return ChatInfoActionMemberAdded(
        model.user.toModel(),
        model.directLinkSlug,
      );
    } else if ($$typename == 'ChatInfoActionMemberRemoved') {
      final model = this as ChatInfoMixin$Action$ChatInfoActionMemberRemoved;
      return ChatInfoActionMemberRemoved(model.user.toModel());
    } else if ($$typename == 'ChatInfoActionNameUpdated') {
      final model = this as ChatInfoMixin$Action$ChatInfoActionNameUpdated;
      return ChatInfoActionNameUpdated(model.name);
    }

    throw Exception('Unexpected ChatInfoAction: ${$$typename}');
  }
}

/// Extension adding models construction from [ChatCallMixin].
extension ChatCallConversion on ChatCallMixin {
  /// Constructs a new [DtoChatCall] from this [ChatCallMixin].
  DtoChatCall toDto(ChatItemsCursor cursor) =>
      DtoChatCall(toModel(), cursor, ver);
}

/// Extension adding models construction from [ChatMessageMixin].
extension ChatMessageConversion on ChatMessageMixin {
  /// Constructs a new [DtoChatItem]s from this [ChatMessageMixin].
  DtoChatItem toDto(ChatItemsCursor cursor) {
    List<DtoChatItemQuote> items = repliesTo.map((e) => e.toDto()).toList();

    return DtoChatMessage(
      ChatMessage(
        id,
        chatId,
        author.toModel(),
        at,
        repliesTo: items.map((e) => e.value).toList(),
        text: text,
        editedAt: editedAt,
        attachments: attachments.map((e) => e.toModel()).toList(),
      ),
      cursor,
      ver,
      items.map((e) => e.cursor).toList(),
    );
  }
}

/// Extension adding models construction from [NestedChatMessageMixin].
extension NestedChatMessageConversion on NestedChatMessageMixin {
  /// Constructs a new [ChatMessage] from this [NestedChatMessageMixin].
  ChatMessage toModel() => ChatMessage(
    id,
    chatId,
    author.toModel(),
    at,
    repliesTo: [],
    text: text,
    editedAt: editedAt,
    attachments: attachments.map((e) => e.toModel()).toList(),
  );

  /// Constructs a new [DtoChatMessage] from this [NestedChatMessageMixin].
  DtoChatMessage toDto(ChatItemsCursor cursor) => DtoChatMessage(
    toModel(),
    cursor,
    ver,
    repliesTo.map((e) => e.original?.cursor).toList(),
  );
}

/// Extension adding models construction from [ChatForwardMixin].
extension ChatForwardConversion on ChatForwardMixin {
  /// Constructs the new [DtoChatItem]s from this [ChatForwardMixin].
  DtoChatItem toDto(ChatItemsCursor cursor) {
    final DtoChatItemQuote item = quote.toDto();
    return DtoChatForward(
      ChatForward(id, chatId, author.toModel(), at, quote: item.value),
      cursor,
      ver,
      item.cursor,
    );
  }
}

/// Extension adding models construction from [NestedChatForwardMixin].
extension NestedChatForwardConversion on NestedChatForwardMixin {
  /// Constructs the new [DtoChatForward]s from this [NestedChatForwardMixin].
  DtoChatForward toDto(ChatItemsCursor cursor) {
    final DtoChatItemQuote item = quote.toDto();

    return DtoChatForward(
      ChatForward(id, chatId, author.toModel(), at, quote: item.value),
      cursor,
      ver,
      item.cursor,
    );
  }
}

/// Extension adding models construction from [NestedChatForwardMixin$Quote].
extension NestedChatForwardItemConversion on NestedChatForwardMixin$Quote {
  /// Constructs a new [DtoChatItem]s from this [NestedChatForwardMixin$Quote].
  DtoChatItemQuote toDto() {
    if ($$typename == 'ChatMessageQuote') {
      final q = this as NestedChatForwardMixin$Quote$ChatMessageQuote;
      return DtoChatItemQuote(
        ChatMessageQuote(
          text: q.text,
          attachments: q.attachments.map((e) => e.toModel()).toList(),
          author: author.id,
          at: at,
        ),
        original?.cursor,
      );
    } else if ($$typename == 'ChatCallQuote') {
      return DtoChatItemQuote(
        ChatCallQuote(author: author.id, at: at),
        original?.cursor,
      );
    } else if ($$typename == 'ChatInfoQuote') {
      final q = this as NestedChatForwardMixin$Quote$ChatInfoQuote;
      return DtoChatItemQuote(
        ChatInfoQuote(action: q.action.toModel(), author: author.id, at: at),
        original?.cursor,
      );
    }

    throw Exception('$this is not implemented');
  }
}

/// Extension adding models construction from
/// [NestedChatForwardMixin$Quote$ChatMessageQuote$Attachments].
extension NestedChatForwardQuoteAttachmentsConversion
    on NestedChatForwardMixin$Quote$ChatMessageQuote$Attachments {
  /// Constructs a new [Attachment] from this
  /// [NestedChatForwardMixin$Quote$ChatMessageQuote$Attachments].
  Attachment toModel() => _attachment(this);
}

/// Extension adding models construction from
/// [NestedChatForwardMixin$Quote$ChatInfoQuote$Action].
extension NestedChatForwardChatInfoQuoteActionConversion
    on NestedChatForwardMixin$Quote$ChatInfoQuote$Action {
  /// Constructs a new [ChatInfo] from this
  /// [NestedChatForwardMixin$Quote$ChatInfoQuote$Action].
  ChatInfoAction toModel() {
    if ($$typename == 'ChatInfoActionAvatarUpdated') {
      final model =
          this as ChatInfoQuoteMixin$Action$ChatInfoActionAvatarUpdated;
      return ChatInfoActionAvatarUpdated(model.avatar?.toModel());
    } else if ($$typename == 'ChatInfoActionCreated') {
      final model = this as ChatInfoQuoteMixin$Action$ChatInfoActionCreated;
      return ChatInfoActionCreated(model.directLinkSlug);
    } else if ($$typename == 'ChatInfoActionMemberAdded') {
      final model = this as ChatInfoQuoteMixin$Action$ChatInfoActionMemberAdded;
      return ChatInfoActionMemberAdded(
        model.user.toModel(),
        model.directLinkSlug,
      );
    } else if ($$typename == 'ChatInfoActionMemberRemoved') {
      final model =
          this as ChatInfoQuoteMixin$Action$ChatInfoActionMemberRemoved;
      return ChatInfoActionMemberRemoved(model.user.toModel());
    } else if ($$typename == 'ChatInfoActionNameUpdated') {
      final model = this as ChatInfoQuoteMixin$Action$ChatInfoActionNameUpdated;
      return ChatInfoActionNameUpdated(model.name);
    }

    throw Exception('Unexpected ChatInfoAction: ${$$typename}');
  }
}

/// Extension adding models construction from
/// [GetMessages$Query$Chat$Items$Edges].
extension GetMessagesConversion on GetMessages$Query$Chat$Items$Edges {
  /// Constructs the new [DtoChatItem]s from this
  /// [GetMessages$Query$Chat$Items$Edges].
  DtoChatItem toDto() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatMixin$LastItem].
extension ChatLastItemConversion on ChatMixin$LastItem {
  /// Constructs the new [DtoChatItem]s from this [ChatMixin$LastItem].
  DtoChatItem toDto() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatMixin$LastReadItem].
extension ChatLastReadItemConversion on ChatMixin$LastReadItem {
  /// Constructs the new [DtoChatItem]s from this [ChatMixin$LastReadItem].
  DtoChatItem toDto() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatForwardMixin$Quote].
extension ChatForwardMixinItemConversion on ChatForwardMixin$Quote {
  /// Constructs the new [DtoChatItemQuote]s from this [ChatForwardMixin$Quote].
  DtoChatItemQuote toDto() => _chatItemQuote(this);
}

/// Extension adding models construction from [ChatMessageMixin$RepliesTo].
extension ChatMessageMixinRepliesToConversion on ChatMessageMixin$RepliesTo {
  /// Constructs the new [DtoChatItemQuote] from this
  /// [ChatMessageMixin$RepliesTo].
  DtoChatItemQuote toDto() => _chatItemQuote(this);
}

/// Extension adding models construction from
/// [ChatEventsVersionedMixin$Events$EventChatItemEdited$RepliesTo$Changed].
extension EventChatItemEditedRepliesToConversion
    on ChatEventsVersionedMixin$Events$EventChatItemEdited$RepliesTo$Changed {
  /// Constructs the new [DtoChatItemQuote]s from this
  /// [ChatEventsVersionedMixin$Events$EventChatItemEdited$RepliesTo$Changed].
  DtoChatItemQuote toDto() => _chatItemQuote(this);
}

/// Extension adding models construction from
/// [ChatEventsVersionedMixin$Events$EventChatItemPosted$Item].
extension EventChatItemPostedConversion
    on ChatEventsVersionedMixin$Events$EventChatItemPosted$Item {
  /// Constructs the new [DtoChatItem]s from this
  /// [ChatEventsVersionedMixin$Events$EventChatItemPosted$Item].
  DtoChatItem toDto() => _chatItem(node, cursor);
}

/// Extension adding models construction from
/// [ChatEventsVersionedMixin$Events$EventChatLastItemUpdated$LastItem].
extension EventChatLastItemUpdatedConversion
    on ChatEventsVersionedMixin$Events$EventChatLastItemUpdated$LastItem {
  /// Constructs the new [DtoChatItem]s from this
  /// [ChatEventsVersionedMixin$Events$EventChatLastItemUpdated$LastItem].
  DtoChatItem toDto() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatMessageQuoteMixin].
extension ChatMessageQuoteConversion on ChatMessageQuoteMixin {
  /// Constructs a new [ChatMessageQuote] from this [ChatMessageQuoteMixin].
  ChatMessageQuote toModel() => ChatMessageQuote(
    original: original == null
        ? null
        : _chatItem(original!.node, original!.cursor).value,
    author: author.id,
    at: at,
    text: text,
    attachments: attachments.map((e) => e.toModel()).toList(),
  );

  /// Constructs a new [DtoChatItemQuote] from this [ChatMessageQuoteMixin].
  DtoChatItemQuote toDto() => DtoChatItemQuote(
    toModel(),
    original == null
        ? null
        : _chatItem(original!.node, original!.cursor).cursor,
  );
}

/// Extension adding models construction from [ChatCallQuoteMixin].
extension ChatCallQuoteConversion on ChatCallQuoteMixin {
  /// Constructs a new [ChatCallQuote] from this [ChatCallQuoteMixin].
  ChatCallQuote toModel() => ChatCallQuote(
    original: original == null
        ? null
        : _chatItem(original!.node, original!.cursor).value,
    author: author.id,
    at: at,
  );

  /// Constructs a new [DtoChatItemQuote] from this [ChatCallQuoteMixin].
  DtoChatItemQuote toDto() => DtoChatItemQuote(
    toModel(),
    original == null
        ? null
        : _chatItem(original!.node, original!.cursor).cursor,
  );
}

/// Extension adding models construction from [ChatInfoQuoteMixin].
extension ChatInfoQuoteConversion on ChatInfoQuoteMixin {
  /// Constructs a new [ChatInfoQuote] from this [ChatInfoQuoteMixin].
  ChatInfoQuote toModel() => ChatInfoQuote(
    original: original == null
        ? null
        : _chatItem(original!.node, original!.cursor).value,
    author: author.id,
    at: at,
    action: action.toModel(),
  );

  /// Constructs a new [DtoChatItemQuote] from this [ChatInfoQuoteMixin].
  DtoChatItemQuote toDto() => DtoChatItemQuote(
    toModel(),
    original == null
        ? null
        : _chatItem(original!.node, original!.cursor).cursor,
  );
}

/// Extension adding models construction from [GetMessage$Query$ChatItem].
extension GetMessageConversion on GetMessage$Query$ChatItem {
  /// Constructs a new [DtoChatItem] from this [GetMessage$Query$ChatItem].
  DtoChatItem toDto() => _chatItem(node, cursor);
}

/// Extension adding models construction from [ChatInfoQuoteMixin$Action].
extension ChatInfoQuoteActionConversion on ChatInfoQuoteMixin$Action {
  /// Constructs a new [ChatInfo] from this [ChatInfoQuoteMixin$Action].
  ChatInfoAction toModel() {
    if ($$typename == 'ChatInfoActionAvatarUpdated') {
      final model =
          this as ChatInfoQuoteMixin$Action$ChatInfoActionAvatarUpdated;
      return ChatInfoActionAvatarUpdated(model.avatar?.toModel());
    } else if ($$typename == 'ChatInfoActionCreated') {
      final model = this as ChatInfoQuoteMixin$Action$ChatInfoActionCreated;
      return ChatInfoActionCreated(model.directLinkSlug);
    } else if ($$typename == 'ChatInfoActionMemberAdded') {
      final model = this as ChatInfoQuoteMixin$Action$ChatInfoActionMemberAdded;
      return ChatInfoActionMemberAdded(
        model.user.toModel(),
        model.directLinkSlug,
      );
    } else if ($$typename == 'ChatInfoActionMemberRemoved') {
      final model =
          this as ChatInfoQuoteMixin$Action$ChatInfoActionMemberRemoved;
      return ChatInfoActionMemberRemoved(model.user.toModel());
    } else if ($$typename == 'ChatInfoActionNameUpdated') {
      final model = this as ChatInfoQuoteMixin$Action$ChatInfoActionNameUpdated;
      return ChatInfoActionNameUpdated(model.name);
    }

    throw Exception('Unexpected ChatInfoAction: ${$$typename}');
  }
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
            topLeft: CropPoint(x: crop!.topLeft.x, y: crop!.topLeft.y),
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

/// Extension adding models construction from [WelcomeMessageMixin$Attachments].
extension WelcomeMessageAttachmentsConversion
    on WelcomeMessageMixin$Attachments {
  /// Constructs a new [Attachment] from this [WelcomeMessageMixin$Attachments].
  Attachment toModel() => _attachment(this);
}

/// Extension adding models construction from
/// [MyUserEventsVersionedMixin$Events$EventUserWelcomeMessageUpdated$Attachments$Changed].
extension EventMyUserWelcomeMessageUpdatedAttachmentsConversion
    on
        MyUserEventsVersionedMixin$Events$EventUserWelcomeMessageUpdated$Attachments$Changed {
  /// Constructs a new [Attachment] from this
  /// [MyUserEventsVersionedMixin$Events$EventUserWelcomeMessageUpdated$Attachments$Changed].
  Attachment toModel() => _attachment(this);
}

/// Extension adding models construction from
/// [UserEventsVersionedMixin$Events$EventUserWelcomeMessageUpdated$Attachments$Changed].
extension EventUserWelcomeMessageUpdatedAttachmentsConversion
    on
        UserEventsVersionedMixin$Events$EventUserWelcomeMessageUpdated$Attachments$Changed {
  /// Constructs a new [Attachment] from this
  /// [UserEventsVersionedMixin$Events$EventUserWelcomeMessageUpdated$Attachments$Changed].
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
  FileAttachment toModel() =>
      FileAttachment(id: id, original: original.toModel(), filename: filename);
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
          if (r.$$typename == 'ChatMessageQuote') {
            var replied =
                r
                    as GetAttachments$Query$ChatItem$Node$ChatMessage$RepliesTo$ChatMessageQuote;
            attachments.addAll(replied.attachments.map((e) => e.toModel()));
          }
        }
      }
    } else if (node.$$typename == 'ChatForward') {
      var message = node as GetAttachments$Query$ChatItem$Node$ChatForward;
      if (message.quote.$$typename == 'ChatMessageQuote') {
        var quote =
            message.quote
                as GetAttachments$Query$ChatItem$Node$ChatForward$Quote$ChatMessageQuote;
        attachments.addAll(quote.attachments.map((e) => e.toModel()));
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
/// [GetAttachments$Query$ChatItem$Node$ChatForward$Quote$ChatMessageQuote$Attachments].
extension GetAttachmentsChatForwardAttachmentConversion
    on
        GetAttachments$Query$ChatItem$Node$ChatForward$Quote$ChatMessageQuote$Attachments {
  /// Constructs a new [Attachment] from this
  /// [GetAttachments$Query$ChatItem$Node$ChatForward$Quote$ChatMessageQuote$Attachments].
  Attachment toModel() => _attachment(this);
}

/// Extension adding models construction from
/// [GetAttachments$Query$ChatItem$Node$ChatMessage$RepliesTo$ChatMessageQuote$Attachments].
extension GetAttachmentsChatMessageRepliesToAttachmentConversion
    on
        GetAttachments$Query$ChatItem$Node$ChatMessage$RepliesTo$ChatMessageQuote$Attachments {
  /// Constructs a new [Attachment] from this
  /// [GetAttachments$Query$ChatItem$Node$ChatMessage$RepliesTo$ChatMessageQuote$Attachments].
  Attachment toModel() => _attachment(this);
}

/// Extension adding models construction from
/// [ChatMessageQuoteMixin$Attachments].
extension ChatMessageQuoteMixinAttachmentsConversion
    on ChatMessageQuoteMixin$Attachments {
  /// Constructs a new [Attachment] from this
  /// [ChatMessageQuoteMixin$Attachments].
  Attachment toModel() => _attachment(this);
}

/// Extension adding models construction from
/// [ChatEventsVersionedMixin$Events$EventChatItemEdited$Attachments$Changed].
extension EventChatItemEditedAttachmentsConversion
    on ChatEventsVersionedMixin$Events$EventChatItemEdited$Attachments$Changed {
  /// Constructs a new [Attachment] from this
  /// [ChatEventsVersionedMixin$Events$EventChatItemEdited$Attachments$Changed].
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

    return MuteDuration.until(
      (this
              as ChatEventsVersionedMixin$Events$EventChatMuted$Duration$MuteUntilDuration)
          .until,
    );
  }
}

/// Extension adding models construction from a [ChatMemberMixin].
extension ChatMemberConversion on ChatMemberMixin {
  /// Constructs a new [ChatMember] from this [ChatMemberMixin].
  ChatMember toModel() => ChatMember(user.toModel(), joinedAt);

  /// Constructs a new [DtoChatMember] from this [ChatMemberMixin].
  DtoChatMember toDto(ChatMembersCursor? cursor) =>
      DtoChatMember(user.toModel(), joinedAt, cursor);
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

/// Constructs a new [DtoChatItem]s based on the [node] and [cursor].
DtoChatItem _chatItem(dynamic node, ChatItemsCursor cursor) {
  if (node is ChatInfoMixin) {
    return node.toDto(cursor);
  } else if (node is ChatCallMixin) {
    return node.toDto(cursor);
  } else if (node is ChatMessageMixin) {
    return node.toDto(cursor);
  } else if (node is NestedChatMessageMixin) {
    return node.toDto(cursor);
  } else if (node is ChatForwardMixin) {
    return node.toDto(cursor);
  } else if (node is NestedChatForwardMixin) {
    return node.toDto(cursor);
  }

  throw UnimplementedError('$node is not implemented');
}

/// Constructs a new [DtoChatItemQuote] based on the [node].
DtoChatItemQuote _chatItemQuote(dynamic node) {
  if (node is ChatMessageQuoteMixin) {
    return node.toDto();
  } else if (node is ChatInfoQuoteMixin) {
    return node.toDto();
  } else if (node is ChatCallQuoteMixin) {
    return node.toDto();
  }

  throw UnimplementedError('$node is not implemented');
}
