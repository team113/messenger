// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/crop_area.dart';
import '/domain/model/file.dart';
import '/domain/model/native_file.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/store/model/chat_call.dart';
import '/store/model/chat_item.dart';
import '/store/model/chat.dart';
import '/util/log.dart';
import 'base.dart';

/// [Hive] storage for [ChatMessage]s being [RxChat.draft]s.
class DraftHiveProvider extends HiveBaseProvider<ChatMessage> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'draft';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');

    Hive.maybeRegisterAdapter(AttachmentIdAdapter());
    Hive.maybeRegisterAdapter(BlocklistRecordAdapter());
    Hive.maybeRegisterAdapter(ChatCallAdapter());
    Hive.maybeRegisterAdapter(ChatCallMemberAdapter());
    Hive.maybeRegisterAdapter(ChatCallQuoteAdapter());
    Hive.maybeRegisterAdapter(ChatCallRoomJoinLinkAdapter());
    Hive.maybeRegisterAdapter(ChatDirectLinkAdapter());
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
    Hive.maybeRegisterAdapter(ChatMessageAdapter());
    Hive.maybeRegisterAdapter(ChatMessageQuoteAdapter());
    Hive.maybeRegisterAdapter(ChatMessageTextAdapter());
    Hive.maybeRegisterAdapter(ChatNameAdapter());
    Hive.maybeRegisterAdapter(ChatVersionAdapter());
    Hive.maybeRegisterAdapter(CropAreaAdapter());
    Hive.maybeRegisterAdapter(FileAttachmentAdapter());
    Hive.maybeRegisterAdapter(DtoChatCallAdapter());
    Hive.maybeRegisterAdapter(DtoChatForwardAdapter());
    Hive.maybeRegisterAdapter(DtoChatInfoAdapter());
    Hive.maybeRegisterAdapter(DtoChatMessageAdapter());
    Hive.maybeRegisterAdapter(ImageAttachmentAdapter());
    Hive.maybeRegisterAdapter(ImageFileAdapter());
    Hive.maybeRegisterAdapter(LocalAttachmentAdapter());
    Hive.maybeRegisterAdapter(MediaTypeAdapter());
    Hive.maybeRegisterAdapter(NativeFileAdapter());
    Hive.maybeRegisterAdapter(PlainFileAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
    Hive.maybeRegisterAdapter(SendingStatusAdapter());
    Hive.maybeRegisterAdapter(ThumbHashAdapter());
    Hive.maybeRegisterAdapter(UserAdapter());
    Hive.maybeRegisterAdapter(UserAvatarAdapter());
    Hive.maybeRegisterAdapter(UserBioAdapter());
    Hive.maybeRegisterAdapter(UserCallCoverAdapter());
    Hive.maybeRegisterAdapter(UserIdAdapter());
    Hive.maybeRegisterAdapter(UserNameAdapter());
    Hive.maybeRegisterAdapter(UserNumAdapter());
    Hive.maybeRegisterAdapter(UserTextStatusAdapter());
  }

  /// Returns a list of [ChatMessage]s from [Hive].
  Iterable<ChatMessage> get drafts => valuesSafe;

  /// Puts the provided [ChatMessage] to [Hive].
  Future<void> put(ChatId id, ChatMessage draft) async {
    Log.trace('put($id, $draft)', '$runtimeType');
    await putSafe(id.val, draft);
  }

  /// Returns a [ChatMessage] from [Hive] by the provided [id].
  ChatMessage? get(ChatId id) {
    Log.trace('get($id)', '$runtimeType');
    return getSafe(id.val);
  }

  /// Removes a [ChatMessage] from [Hive] by the provided [id].
  Future<void> remove(ChatId id) async {
    Log.trace('remove($id)', '$runtimeType');
    await deleteSafe(id.val);
  }

  /// Moves the [ChatMessage] at the [oldKey] to the [newKey].
  Future<void> move(ChatId oldKey, ChatId newKey) async {
    Log.trace('move($oldKey, $newKey)', '$runtimeType');

    final ChatMessage? value = get(oldKey);
    if (value != null) {
      remove(oldKey);
      put(newKey, value);
    }
  }
}
