// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/file.dart';
import '/domain/model/gallery_item.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/native_file.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model_type_id.dart';
import '/store/model/chat_item.dart';
import '/store/model/user.dart';
import 'base.dart';

part 'chat_item.g.dart';

/// [Hive] storage for [ChatItem]s.
class ChatItemHiveProvider extends HiveLazyProvider<HiveChatItem> {
  ChatItemHiveProvider(this.id);

  /// ID of a [Chat] this provider is bound to.
  final ChatId id;

  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'messages_$id';

  @override
  Iterable<dynamic> get keys => super.keys.toList().reversed;

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(AttachmentIdAdapter());
    Hive.maybeRegisterAdapter(BlacklistReasonAdapter());
    Hive.maybeRegisterAdapter(BlacklistRecordAdapter());
    Hive.maybeRegisterAdapter(ChatAdapter());
    Hive.maybeRegisterAdapter(ChatCallAdapter());
    Hive.maybeRegisterAdapter(ChatCallMemberAdapter());
    Hive.maybeRegisterAdapter(ChatCallQuoteAdapter());
    Hive.maybeRegisterAdapter(ChatForwardAdapter());
    Hive.maybeRegisterAdapter(ChatIdAdapter());
    Hive.maybeRegisterAdapter(ChatInfoActionAvatarUpdatedAdapter());
    Hive.maybeRegisterAdapter(ChatInfoActionCreatedAdapter());
    Hive.maybeRegisterAdapter(ChatInfoActionMemberAddedAdapter());
    Hive.maybeRegisterAdapter(ChatInfoActionMemberRemovedAdapter());
    Hive.maybeRegisterAdapter(ChatInfoActionNameUpdatedAdapter());
    Hive.maybeRegisterAdapter(ChatInfoAdapter());
    Hive.maybeRegisterAdapter(ChatInfoQuoteAdapter());
    Hive.maybeRegisterAdapter(ChatItemIdAdapter());
    Hive.maybeRegisterAdapter(ChatItemVersionAdapter());
    Hive.maybeRegisterAdapter(ChatItemsCursorAdapter());
    Hive.maybeRegisterAdapter(ChatMemberAdapter());
    Hive.maybeRegisterAdapter(ChatMembersDialedAllAdapter());
    Hive.maybeRegisterAdapter(ChatMembersDialedConcreteAdapter());
    Hive.maybeRegisterAdapter(ChatMessageAdapter());
    Hive.maybeRegisterAdapter(ChatNameAdapter());
    Hive.maybeRegisterAdapter(ChatAvatarAdapter());
    Hive.maybeRegisterAdapter(ChatMessageQuoteAdapter());
    Hive.maybeRegisterAdapter(ChatMessageTextAdapter());
    Hive.maybeRegisterAdapter(FileAttachmentAdapter());
    Hive.maybeRegisterAdapter(GalleryItemIdAdapter());
    Hive.maybeRegisterAdapter(HiveChatCallAdapter());
    Hive.maybeRegisterAdapter(HiveChatForwardAdapter());
    Hive.maybeRegisterAdapter(HiveChatInfoAdapter());
    Hive.maybeRegisterAdapter(HiveChatMessageAdapter());
    Hive.maybeRegisterAdapter(ImageAttachmentAdapter());
    Hive.maybeRegisterAdapter(ImageGalleryItemAdapter());
    Hive.maybeRegisterAdapter(LocalAttachmentAdapter());
    Hive.maybeRegisterAdapter(MediaTypeAdapter());
    Hive.maybeRegisterAdapter(NativeFileAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
    Hive.maybeRegisterAdapter(SendingStatusAdapter());
    Hive.maybeRegisterAdapter(StorageFileAdapter());
    Hive.maybeRegisterAdapter(UserAdapter());
    Hive.maybeRegisterAdapter(UserAvatarAdapter());
    Hive.maybeRegisterAdapter(UserBioAdapter());
    Hive.maybeRegisterAdapter(UserCallCoverAdapter());
    Hive.maybeRegisterAdapter(UserIdAdapter());
    Hive.maybeRegisterAdapter(UserNameAdapter());
    Hive.maybeRegisterAdapter(UserNumAdapter());
    Hive.maybeRegisterAdapter(UserTextStatusAdapter());
    Hive.maybeRegisterAdapter(UserVersionAdapter());
  }

  /// Returns a list of [ChatItem]s from [Hive].
  Future<Iterable<HiveChatItem>> get messages => valuesSafe;

  /// Puts the provided [ChatItem] to [Hive].
  Future<void> put(HiveChatItem item) => putSafe(item.value.key, item);

  /// Adds the provided [ChatItem] to [Hive].
  ///
  /// [ChatItem] will be added if it is within the bounds of the stored items.
  Future<void> add(HiveChatItem item) async {
    if (box.keys.isNotEmpty &&
        (box.keys.first as String).compareTo(item.value.key) == 1 &&
        (box.keys.last as String).compareTo(item.value.key) == -1) {
      await put(item);
    }
  }

  /// Returns a [ChatItem] from [Hive] by its [timestamp].
  Future<HiveChatItem?> get(String timestamp) => getSafe(timestamp);

  /// Removes a [ChatItem] from [Hive] by the provided [timestamp].
  Future<void> remove(String timestamp) => deleteSafe(timestamp);
}

/// Persisted in [Hive] storage [ChatItem]'s [value].
abstract class HiveChatItem extends HiveObject {
  HiveChatItem(this.value, this.cursor, this.ver);

  /// Persisted [ChatItem] model.
  @HiveField(0)
  ChatItem value;

  /// Cursor of a [ChatItem] this [HiveChatItem] represents.
  @HiveField(1)
  ChatItemsCursor? cursor;

  /// Version of a [ChatItem]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  @HiveField(2)
  final ChatItemVersion ver;

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) =>
      other is HiveChatItem && value.id == other.value.id;
}

/// Persisted in [Hive] storage [ChatInfo]'s [value].
@HiveType(typeId: ModelTypeId.hiveChatInfo)
class HiveChatInfo extends HiveChatItem {
  HiveChatInfo(
    super.value,
    super.cursor,
    super.ver,
  );
}

/// Persisted in [Hive] storage [ChatCall]'s [value].
@HiveType(typeId: ModelTypeId.hiveChatCall)
class HiveChatCall extends HiveChatItem {
  HiveChatCall(
    super.value,
    super.cursor,
    super.ver,
  );
}

/// Persisted in [Hive] storage [ChatMessage]'s [value].
@HiveType(typeId: ModelTypeId.hiveChatMessage)
class HiveChatMessage extends HiveChatItem {
  HiveChatMessage(
    super.value,
    super.cursor,
    super.ver,
    this.repliesToCursor,
  );

  /// Constructs a [HiveChatMessage] in a [SendingStatus.sending] state.
  factory HiveChatMessage.sending({
    required ChatId chatId,
    required UserId me,
    ChatMessageText? text,
    List<ChatItemQuote> repliesTo = const [],
    List<Attachment> attachments = const [],
    ChatItemId? existingId,
    PreciseDateTime? existingDateTime,
  }) =>
      HiveChatMessage(
        ChatMessage(
          existingId ?? ChatItemId.local(),
          chatId,
          me,
          existingDateTime ?? PreciseDateTime.now(),
          text: text,
          repliesTo: repliesTo,
          attachments: attachments,
          status: SendingStatus.sending,
        ),
        null,
        ChatItemVersion('0'),
        [],
      );

  /// Cursors of the [ChatMessage.repliesTo] list.
  @HiveField(3)
  List<ChatItemsCursor?>? repliesToCursor;
}

/// Persisted in [Hive] storage [ChatForward]'s [value].
@HiveType(typeId: ModelTypeId.hiveChatForward)
class HiveChatForward extends HiveChatItem {
  HiveChatForward(
    super.value,
    super.cursor,
    super.ver,
    this.quoteCursor,
  );

  /// Cursor of a [ChatForward.quote].
  @HiveField(3)
  ChatItemsCursor? quoteCursor;
}

/// Persisted in [Hive] storage [ChatItemQuote]'s [value].
class HiveChatItemQuote {
  HiveChatItemQuote(this.value, this.cursor);

  /// [ChatItemQuote] itself.
  @HiveField(0)
  final ChatItemQuote value;

  /// Cursor of a [ChatItemQuote.original].
  @HiveField(1)
  ChatItemsCursor? cursor;
}
