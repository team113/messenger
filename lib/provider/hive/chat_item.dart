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
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/file.dart';
import '/domain/model/native_file.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/model_type_id.dart';
import '/store/model/chat_item.dart';
import '/util/log.dart';
import 'base.dart';

part 'chat_item.g.dart';

/// [Hive] storage for [ChatItem]s.
class ChatItemHiveProvider extends HiveLazyProvider<DtoChatItem>
    implements IterableHiveProvider<DtoChatItem, ChatItemId> {
  ChatItemHiveProvider(this.id);

  /// ID of a [Chat] this provider is bound to.
  final ChatId id;

  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'messages_$id';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters($id)', '$runtimeType');

    Hive.maybeRegisterAdapter(AttachmentIdAdapter());
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
    Hive.maybeRegisterAdapter(ChatMessageQuoteAdapter());
    Hive.maybeRegisterAdapter(ChatMessageTextAdapter());
    Hive.maybeRegisterAdapter(FileAttachmentAdapter());
    Hive.maybeRegisterAdapter(DtoChatCallAdapter());
    Hive.maybeRegisterAdapter(DtoChatForwardAdapter());
    Hive.maybeRegisterAdapter(DtoChatInfoAdapter());
    Hive.maybeRegisterAdapter(DtoChatMessageAdapter());
    Hive.maybeRegisterAdapter(ImageAttachmentAdapter());
    Hive.maybeRegisterAdapter(LocalAttachmentAdapter());
    Hive.maybeRegisterAdapter(MediaTypeAdapter());
    Hive.maybeRegisterAdapter(NativeFileAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
    Hive.maybeRegisterAdapter(SendingStatusAdapter());
    Hive.maybeRegisterAdapter(ThumbHashAdapter());
  }

  @override
  Iterable<ChatItemId> get keys => keysSafe.map((e) => ChatItemId(e));

  @override
  Future<Iterable<DtoChatItem>> get values => valuesSafe;

  @override
  Future<void> put(DtoChatItem item) async {
    Log.trace('put($item)', '$runtimeType');
    await putSafe(item.value.id.toString(), item);
  }

  @override
  Future<DtoChatItem?> get(ChatItemId key) async {
    Log.trace('get($key)', '$runtimeType');
    return await getSafe(key.toString());
  }

  @override
  Future<void> remove(ChatItemId key) async {
    Log.trace('remove($key)', '$runtimeType');
    await deleteSafe(key.toString());
  }
}
