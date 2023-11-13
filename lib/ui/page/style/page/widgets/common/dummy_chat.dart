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

import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/util/obs/rxlist.dart';
import '/util/obs/rxmap.dart';

/// A dummy implementation of [RxChat].
///
/// Used to show [RxChat] related [Widget]s.
class DummyRxChat extends RxChat {
  DummyRxChat() : chat = Rx(Chat(ChatId.local(const UserId('me'))));

  @override
  final Rx<Chat> chat;

  @override
  Future<void> addMessage(ChatMessageText text) async {}

  @override
  Future<void> around() async {}

  @override
  Rx<Avatar?> get avatar => Rx(null);

  @override
  UserCallCover? get callCover => null;

  @override
  int compareTo(RxChat other) => 0;

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
  RxObsMap<UserId, RxUser> get members => RxObsMap();

  @override
  RxObsList<Rx<ChatItem>> get messages => RxObsList();

  @override
  Future<void> next() async {}

  @override
  RxBool get nextLoading => RxBool(false);

  @override
  Future<void> previous() async {}

  @override
  RxBool get previousLoading => RxBool(false);

  @override
  RxList<LastChatRead> get reads => RxList();

  @override
  Future<void> remove(ChatItemId itemId) async {}

  @override
  void setDraft({
    ChatMessageText? text,
    List<Attachment> attachments = const [],
    List<ChatItem> repliesTo = const [],
  }) {}

  @override
  Rx<RxStatus> get status => Rx(RxStatus.empty());

  @override
  RxString get title => RxString('Title');

  @override
  RxList<User> get typingUsers => RxList();

  @override
  RxInt get unreadCount => RxInt(0);

  @override
  Future<void> updateAttachments(ChatItem item) async {}

  @override
  Stream<void> get updates => const Stream.empty();
}
