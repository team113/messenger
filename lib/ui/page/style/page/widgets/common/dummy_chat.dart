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

import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/paginated.dart';
import '/store/paginated.dart';
import '/util/obs/obs.dart';

/// Dummy implementation of [RxChat].
///
/// Used to show [RxChat] related [Widget]s.
class DummyRxChat extends RxChat {
  DummyRxChat() : chat = Rx(Chat(ChatId.local(const UserId('me'))));

  @override
  final Rx<Chat> chat;

  @override
  Rx<Avatar?> get avatar => Rx(null);

  @override
  UserCallCover? get callCover => null;

  @override
  Rx<ChatMessage?> get draft => Rx(null);

  @override
  Rx<ChatItem>? get firstUnread => null;

  @override
  RxBool get hasNext => RxBool(false);

  @override
  RxBool get hasPrevious => RxBool(false);

  @override
  ChatItem? get lastItem => null;

  @override
  UserId? get me => null;

  @override
  Paginated<UserId, RxChatMember> get members => PaginatedImpl();

  @override
  RxObsList<Rx<ChatItem>> get messages => RxObsList();

  @override
  RxBool get nextLoading => RxBool(false);

  @override
  RxBool get previousLoading => RxBool(false);

  @override
  RxBool get inCall => RxBool(false);

  @override
  RxList<LastChatRead> get reads => RxList();

  @override
  Rx<RxStatus> get status => Rx(RxStatus.empty());

  @override
  RxList<User> get typingUsers => RxList();

  @override
  RxInt get unreadCount => RxInt(0);

  @override
  Stream<void> get updates => const Stream.empty();

  @override
  Future<void> updateAttachments(ChatItem item) async {}

  @override
  Future<void> updateAvatar() async {}

  @override
  Future<void> ensureDraft() async {}

  @override
  Future<void> setDraft({
    ChatMessageText? text,
    List<Attachment> attachments = const [],
    List<ChatItem> repliesTo = const [],
  }) async {}

  @override
  Future<void> next() async {}

  @override
  Future<void> previous() async {}

  @override
  Future<void> remove(ChatItemId itemId) async {}

  @override
  Future<Paginated<ChatItemId, Rx<ChatItem>>?> around({
    ChatItemId? item,
    ChatItemId? reply,
    ChatItemId? forward,
    ChatMessageText? withText,
  }) async => null;

  @override
  Future<Paginated<ChatItemId, Rx<ChatItem>>?> single(ChatItemId item) async =>
      null;

  @override
  int compareTo(RxChat other) => 0;

  @override
  Paginated<ChatItemId, Rx<ChatItem>> attachments({ChatItemId? item}) {
    return PaginatedImpl();
  }
}
