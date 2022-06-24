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

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model_type_id.dart';
import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/crop_area.dart';
import '/domain/model/gallery_item.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/native_file.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/store/model/chat_item.dart';
import '/store/model/chat.dart';
import 'base.dart';
import 'chat_item.dart';

part 'chat.g.dart';

/// [Hive] storage for [Chat]s.
class ChatHiveProvider extends HiveBaseProvider<HiveChat> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'chat';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(AttachmentIdAdapter());
    Hive.maybeRegisterAdapter(ChatAdapter());
    Hive.maybeRegisterAdapter(ChatAvatarAdapter());
    Hive.maybeRegisterAdapter(ChatCallAdapter());
    Hive.maybeRegisterAdapter(ChatCallMemberAdapter());
    Hive.maybeRegisterAdapter(ChatCallRoomJoinLinkAdapter());
    Hive.maybeRegisterAdapter(ChatDirectLinkAdapter());
    Hive.maybeRegisterAdapter(ChatForwardAdapter());
    Hive.maybeRegisterAdapter(ChatIdAdapter());
    Hive.maybeRegisterAdapter(ChatItemsCursorAdapter());
    Hive.maybeRegisterAdapter(ChatItemIdAdapter());
    Hive.maybeRegisterAdapter(ChatItemVersionAdapter());
    Hive.maybeRegisterAdapter(ChatMemberAdapter());
    Hive.maybeRegisterAdapter(ChatMemberInfoAdapter());
    Hive.maybeRegisterAdapter(ChatMessageAdapter());
    Hive.maybeRegisterAdapter(ChatMessageTextAdapter());
    Hive.maybeRegisterAdapter(ChatNameAdapter());
    Hive.maybeRegisterAdapter(ChatVersionAdapter());
    Hive.maybeRegisterAdapter(CropAreaAdapter());
    Hive.maybeRegisterAdapter(FileAttachmentAdapter());
    Hive.maybeRegisterAdapter(GalleryItemIdAdapter());
    Hive.maybeRegisterAdapter(HiveChatAdapter());
    Hive.maybeRegisterAdapter(HiveChatCallAdapter());
    Hive.maybeRegisterAdapter(HiveChatForwardAdapter());
    Hive.maybeRegisterAdapter(HiveChatMemberInfoAdapter());
    Hive.maybeRegisterAdapter(HiveChatMessageAdapter());
    Hive.maybeRegisterAdapter(ImageAttachmentAdapter());
    Hive.maybeRegisterAdapter(ImageGalleryItemAdapter());
    Hive.maybeRegisterAdapter(LastChatReadAdapter());
    Hive.maybeRegisterAdapter(LocalAttachmentAdapter());
    Hive.maybeRegisterAdapter(MediaTypeAdapter());
    Hive.maybeRegisterAdapter(MuteDurationAdapter());
    Hive.maybeRegisterAdapter(NativeFileAdapter());
    Hive.maybeRegisterAdapter(OriginalAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
    Hive.maybeRegisterAdapter(SendingStatusAdapter());
    Hive.maybeRegisterAdapter(UserAdapter());
  }

  /// Returns a list of [Chat]s from [Hive].
  Iterable<HiveChat> get chats => valuesSafe;

  /// Puts the provided [Chat] to [Hive].
  Future<void> put(HiveChat chat) => putSafe(chat.value.id.val, chat);

  /// Returns a [Chat] from [Hive] by its [id].
  HiveChat? get(ChatId id) => getSafe(id.val);

  /// Removes a [Chat] from [Hive] by the provided [id].
  Future<void> remove(ChatId id) => deleteSafe(id.val);
}

/// Persisted in [Hive] storage [Chat]'s [value].
@HiveType(typeId: ModelTypeId.hiveChat)
class HiveChat extends HiveObject {
  HiveChat(
    this.value,
    this.ver,
    this.lastItemCursor,
    this.lastReadItemCursor,
  );

  /// Persisted [Chat] model.
  @HiveField(0)
  Chat value;

  /// Version of this [Chat]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  @HiveField(1)
  ChatVersion ver;

  /// Cursor of a [Chat.lastItem].
  @HiveField(2)
  ChatItemsCursor? lastItemCursor;

  /// Cursor of a [Chat.lastReadItem].
  @HiveField(3)
  ChatItemsCursor? lastReadItemCursor;
}
