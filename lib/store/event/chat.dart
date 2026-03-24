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

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/attachment.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/store/model/chat_item.dart';
import '/store/model/chat.dart';

/// Possible kinds of a [ChatEvent].
enum ChatEventKind {
  archived,
  callAnswerTimeoutPassed,
  callConversationStarted,
  callDeclined,
  callFinished,
  callMemberJoined,
  callMemberLeft,
  callMoved,
  callStarted,
  cleared,
  delivered,
  favorited,
  hidden,
  itemDeleted,
  itemHidden,
  itemPosted,
  itemEdited,
  lastItemUpdated,
  muted,
  read,
  redialed,
  totalItemsCountUpdated,
  typingStarted,
  typingStopped,
  unarchived,
  unfavorited,
  unmuted,
  unreadItemsCountUpdated,
}

/// Tag representing a [ChatEvents] kind.
enum ChatEventsKind { initialized, chat, event }

/// [Chat] event union.
abstract class ChatEvents {
  const ChatEvents();

  /// [ChatEventsKind] of this event.
  ChatEventsKind get kind;
}

/// Indicator notifying about a GraphQL subscription being successfully
/// initialized.
class ChatEventsInitialized extends ChatEvents {
  const ChatEventsInitialized();

  @override
  ChatEventsKind get kind => ChatEventsKind.initialized;
}

/// Initial state of the [Chat].
class ChatEventsChat extends ChatEvents {
  const ChatEventsChat(this.chat);

  /// Initial state itself.
  final DtoChat chat;

  @override
  ChatEventsKind get kind => ChatEventsKind.chat;
}

/// [ChatEventsVersioned] happening in the [Chat].
class ChatEventsEvent extends ChatEvents {
  const ChatEventsEvent(this.event);

  /// [ChatEventsVersioned] itself.
  final ChatEventsVersioned event;

  @override
  ChatEventsKind get kind => ChatEventsKind.event;
}

/// [ChatEvent]s along with the corresponding [ChatVersion].
class ChatEventsVersioned {
  const ChatEventsVersioned(this.events, this.ver);

  /// [ChatEvent]s themselves.
  final List<ChatEvent> events;

  /// Version of the [Chat]'s state updated by these [ChatEvent]s.
  final ChatVersion ver;
}

/// Events happening in a [Chat].
abstract class ChatEvent {
  const ChatEvent(this.chatId);

  /// ID of the [Chat] this [ChatEvent] is related to.
  final ChatId chatId;

  /// Returns [ChatEventKind] of this [ChatEvent].
  ChatEventKind get kind;
}

/// Event of a [ChatCall] being moved from its [Chat]-dialog to a newly created
/// [Chat]-group.
class ChatCallMovedEvent extends ChatEvent {
  const ChatCallMovedEvent(
    super.chatId,
    this.callId,
    this.call,
    this.newChatId,
    this.newChat,
    this.newCallId,
    this.newCall,
    this.user,
    this.at,
  );

  /// ID of the moved [ChatCall] in the [Chat]-dialog.
  final ChatItemId callId;

  /// Moved [ChatCall] in the [Chat]-dialog.
  final ChatCall call;

  /// ID of the newly created [Chat]-group the [ChatCall] was moved to.
  final ChatId newChatId;

  /// Newly created [Chat]-group the [ChatCall] was moved to.
  final Chat newChat;

  /// ID of the moved [ChatCall] in the newly created [Chat]-group.
  final ChatItemId newCallId;

  /// Moved [ChatCall] in the newly created [Chat]-group.
  final ChatCall newCall;

  /// [User] who moved the [ChatCall].
  final User user;

  /// [PreciseDateTime] when the [ChatCall] was moved.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.callMoved;
}

/// Event of a [User] being redialed in a [ChatCall].
class ChatCallMemberRedialedEvent extends ChatEvent {
  const ChatCallMemberRedialedEvent(
    super.chatId,
    this.at,
    this.callId,
    this.call,
    this.user,
    this.byUser,
  );

  /// ID of the [ChatCall] the [User] is redialed in.
  final ChatItemId callId;

  /// [DateTime] when the [ChatMember] was redialed in the [ChatCall].
  final PreciseDateTime at;

  /// [ChatCall] the [User] is redialed in.
  final ChatCall call;

  /// [User] representing the [ChatMember] who was redialed in the [ChatCall].
  final User user;

  /// [User] representing the [ChatMember] who redialed the [User] in the
  /// [ChatCall].
  final User byUser;

  @override
  ChatEventKind get kind => ChatEventKind.redialed;
}

/// Event of a [Chat] being cleared by the authenticated [MyUser].
class ChatClearedEvent extends ChatEvent {
  const ChatClearedEvent(super.chatId, this.at);

  /// [PreciseDateTime] when the [Chat] was cleared.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.cleared;
}

/// Event of a [ChatItem] being hidden by the authenticated [MyUser].
class ChatItemHiddenEvent extends ChatEvent {
  const ChatItemHiddenEvent(super.chatId, this.itemId);

  /// ID of the hidden [ChatItem].
  final ChatItemId itemId;

  @override
  ChatEventKind get kind => ChatEventKind.itemHidden;
}

/// Event of a [Chat] being muted by the authenticated [MyUser].
class ChatMutedEvent extends ChatEvent {
  const ChatMutedEvent(super.chatId, this.duration);

  /// Duration the [Chat] should be muted until.
  final MuteDuration duration;

  @override
  ChatEventKind get kind => ChatEventKind.muted;
}

/// Event of a [ChatMember] started typing in a [Chat].
class ChatTypingStartedEvent extends ChatEvent {
  const ChatTypingStartedEvent(super.chatId, this.user);

  /// [User] who started typing.
  final User user;

  @override
  ChatEventKind get kind => ChatEventKind.typingStarted;
}

/// Event of a [Chat] being unmuted by the authenticated [MyUser].
class EventChatUnmuted extends ChatEvent {
  const EventChatUnmuted(super.chatId);

  @override
  ChatEventKind get kind => ChatEventKind.unmuted;
}

/// Event of a [ChatMember] stopped typing in a [Chat].
class ChatTypingStoppedEvent extends ChatEvent {
  const ChatTypingStoppedEvent(super.chatId, this.user);

  /// [User] who stopped typing.
  final User user;

  @override
  ChatEventKind get kind => ChatEventKind.typingStopped;
}

/// Event of a [Chat] being hidden by the authenticated [MyUser].
class ChatHiddenEvent extends ChatEvent {
  const ChatHiddenEvent(super.chatId, this.at);

  /// [PreciseDateTime] when the [Chat] was hidden.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.hidden;
}

/// Event of a [Chat] being archived by the authenticated [MyUser].
class ChatArchivedEvent extends ChatEvent {
  const ChatArchivedEvent(super.chatId, this.at);

  /// [PreciseDateTime] when the [Chat] was archived.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.archived;
}

/// Event of a [Chat] being unarchived by the authenticated [MyUser].
class ChatUnarchivedEvent extends ChatEvent {
  const ChatUnarchivedEvent(super.chatId, this.at);

  /// [PreciseDateTime] when the [Chat] was unarchived.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.unarchived;
}

/// Event of a [ChatItem] being deleted by some [User].
class ChatItemDeletedEvent extends ChatEvent {
  const ChatItemDeletedEvent(super.chatId, this.itemId);

  /// ID of the deleted [ChatItem].
  final ChatItemId itemId;

  @override
  ChatEventKind get kind => ChatEventKind.itemDeleted;
}

/// Event of a [ChatItem] being edited by its author.
class ChatItemEditedEvent extends ChatEvent {
  const ChatItemEditedEvent(
    super.chatId,
    this.itemId,
    this.text,
    this.attachments,
    this.quotes,
  );

  /// ID of the edited [ChatItem].
  final ChatItemId itemId;

  /// Edited [ChatItem]'s text.
  final EditedMessageText? text;

  /// Edited [Attachment]s of the [ChatItem].
  final List<Attachment>? attachments;

  /// [DtoChatItemQuote]s the edited [ChatItem] replies to.
  final List<DtoChatItemQuote>? quotes;

  @override
  ChatEventKind get kind => ChatEventKind.itemEdited;
}

/// Event of a [ChatCall] being started.
class ChatCallStartedEvent extends ChatEvent {
  const ChatCallStartedEvent(super.chatId, this.call);

  /// Started [ChatCall].
  final ChatCall call;

  @override
  ChatEventKind get kind => ChatEventKind.callStarted;
}

/// Event of a [Chat] unread items count being updated.
class ChatUnreadItemsCountUpdatedEvent extends ChatEvent {
  const ChatUnreadItemsCountUpdatedEvent(super.chatId, this.count);

  /// Updated unread [ChatItem]s count.
  final int count;

  @override
  ChatEventKind get kind => ChatEventKind.unreadItemsCountUpdated;
}

/// Event of a [ChatCall] being finished.
class ChatCallFinishedEvent extends ChatEvent {
  const ChatCallFinishedEvent(super.chatId, this.call, this.reason);

  /// Finished [ChatCall].
  final ChatCall call;

  /// Reason of why the [call] was finished.
  final ChatCallFinishReason reason;

  @override
  ChatEventKind get kind => ChatEventKind.callFinished;
}

/// Event of a [User] leaving a [ChatCall].
class ChatCallMemberLeftEvent extends ChatEvent {
  const ChatCallMemberLeftEvent(super.chatId, this.user, this.at);

  /// User who left the [ChatCall].
  final User user;

  /// [PreciseDateTime] when the [User] left the [ChatCall].
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.callMemberLeft;
}

/// Event of a [User] joined a [ChatCall].
class ChatCallMemberJoinedEvent extends ChatEvent {
  const ChatCallMemberJoinedEvent(super.chatId, this.call, this.user, this.at);

  /// Joined [ChatCall].
  final ChatCall call;

  /// [User] who joined the [ChatCall].
  final User user;

  /// [PreciseDateTime] when the [User] joined the [ChatCall].
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.callMemberJoined;
}

/// Event of a [Chat] last item being updated.
class ChatLastItemUpdatedEvent extends ChatEvent {
  const ChatLastItemUpdatedEvent(super.chatId, this.lastItem);

  /// Updated last [ChatItem].
  final DtoChatItem? lastItem;

  @override
  ChatEventKind get kind => ChatEventKind.lastItemUpdated;
}

/// Event of last [ChatItem]s posted by the authenticated [MyUser] being
/// delivered to other [User]s in a [Chat].
class ChatDeliveredEvent extends ChatEvent {
  const ChatDeliveredEvent(super.chatId, this.until);

  /// [PreciseDateTime] until which the [ChatItem]s in [Chat] were delivered.
  final PreciseDateTime until;

  @override
  ChatEventKind get kind => ChatEventKind.delivered;
}

/// Event of a [Chat] being read by a [User].
class ChatReadEvent extends ChatEvent {
  const ChatReadEvent(super.chatId, this.byUser, this.at);

  /// [User] who read the [Chat].
  final User byUser;

  /// [PreciseDateTime] when the [Chat] was read by the [User].
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.read;
}

/// Event of a [ChatCall] being declined by a [ChatMember].
class ChatCallDeclinedEvent extends ChatEvent {
  const ChatCallDeclinedEvent(
    super.chatId,
    this.callId,
    this.call,
    this.user,
    this.at,
  );

  /// ID of the [ChatCall] being declined.
  final ChatItemId callId;

  /// Declined [ChatCall].
  final ChatCall call;

  /// [User] who declined the [ChatCall].
  final User user;

  /// [PreciseDateTime] when the [ChatCall] was declined.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.callDeclined;
}

/// Event of a new [ChatItem] being posted in a [Chat].
class ChatItemPostedEvent extends ChatEvent {
  const ChatItemPostedEvent(super.chatId, this.item);

  /// New [ChatItem].
  final DtoChatItem item;

  @override
  ChatEventKind get kind => ChatEventKind.itemPosted;
}

/// Event of a [Chat] total items count being updated.
class ChatTotalItemsCountUpdatedEvent extends ChatEvent {
  const ChatTotalItemsCountUpdatedEvent(super.chatId, this.count);

  /// Updated total [ChatItem]s count.
  final int count;

  @override
  ChatEventKind get kind => ChatEventKind.totalItemsCountUpdated;
}

/// Events happening in the the favorite [Chat]s list.
abstract class FavoriteChatsEvent extends ChatEvent {
  const FavoriteChatsEvent(super.chatId, this.at);

  /// [PreciseDateTime] when this [FavoriteChatsEvent] happened.
  final PreciseDateTime at;
}

/// Event of a [Chat] being added to the favorites list of the authenticated
/// [MyUser].
class ChatFavoritedEvent extends FavoriteChatsEvent {
  const ChatFavoritedEvent(super.chatId, super.at, this.position);

  /// Position of the [Chat] in the favorites list.
  final ChatFavoritePosition position;

  @override
  ChatEventKind get kind => ChatEventKind.favorited;
}

/// Event of a [Chat] being removed from the favorites list of the authenticated
/// [MyUser].
class ChatUnfavoritedEvent extends FavoriteChatsEvent {
  const ChatUnfavoritedEvent(super.chatId, super.at);

  @override
  ChatEventKind get kind => ChatEventKind.unfavorited;
}

/// Event of an audio/video conversation being started in a [ChatCall], meaning
/// that enough [ChatCallMember]s joined the `Medea` room after ringing had been
/// finished.
class ChatCallConversationStartedEvent extends ChatEvent {
  const ChatCallConversationStartedEvent(
    super.chatId,
    this.callId,
    this.at,
    this.call,
  );

  /// ID of the [ChatCall] the conversation started in.
  final ChatItemId callId;

  /// [PreciseDateTime] when the conversation started.
  final PreciseDateTime at;

  /// [ChatCall] the conversation started in.
  final ChatCall call;

  @override
  ChatEventKind get kind => ChatEventKind.callConversationStarted;
}

/// Event of an answer timeout being reached in a [ChatCall].
class ChatCallAnswerTimeoutPassedEvent extends ChatEvent {
  const ChatCallAnswerTimeoutPassedEvent(super.chatId, this.callId);

  /// ID of the [ChatCall] the conversation started in.
  final ChatItemId callId;

  @override
  ChatEventKind get kind => ChatEventKind.callAnswerTimeoutPassed;
}

/// Edited [ChatMessageText].
class EditedMessageText {
  const EditedMessageText(this.newText);

  /// New [ChatMessageText].
  ///
  /// `null` means that the previous [ChatMessageText] should be deleted.
  final ChatMessageText? newText;
}
