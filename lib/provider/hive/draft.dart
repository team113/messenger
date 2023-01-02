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
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/crop_area.dart';
import '/domain/model/file.dart';
import '/domain/model/gallery_item.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/native_file.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/store/model/chat_item.dart';
import '/store/model/chat.dart';
import 'base.dart';
import 'chat_item.dart';

/// [Hive] storage for [ChatMessage]s being [RxChat.draft]s.
class DraftHiveProvider extends HiveBaseProvider<ChatMessage> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'draft';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(AttachmentIdAdapter());
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
    Hive.maybeRegisterAdapter(HiveChatCallAdapter());
    Hive.maybeRegisterAdapter(HiveChatForwardAdapter());
    Hive.maybeRegisterAdapter(HiveChatMemberInfoAdapter());
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
  }

  /// Returns a list of [ChatMessage]s from [Hive].
  Iterable<ChatMessage> get drafts => valuesSafe;

  /// Puts the provided [ChatMessage] to [Hive].
  Future<void> put(ChatId id, ChatMessage draft) => putSafe(id.val, draft);

  /// Returns a [ChatMessage] from [Hive] by the provided [id].
  ChatMessage? get(ChatId id) => getSafe(id.val);

  /// Removes a [ChatMessage] from [Hive] by the provided [id].
  Future<void> remove(ChatId id) => deleteSafe(id.val);
}
