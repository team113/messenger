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
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/widget/text_field.dart';

class ContactSupportController extends GetxController {
  ContactSupportController(
    this.transaction,
    this._chatService,
    this._userService,
  );

  final Transaction transaction;
  final TextFieldState name = TextFieldState();

  final UserService _userService;
  final ChatService _chatService;

  Future<void> support() async {
    final user = await _userService
        .get(const UserId('92b37f75-aeb3-4559-9176-dbbc88bf5d52'));

    RxChat? chat = user?.dialog.value;
    chat ??= await _chatService.get(
      ChatId.local(const UserId('92b37f75-aeb3-4559-9176-dbbc88bf5d52')),
    );

    if (chat != null) {
      router.chat(chat.id, push: true);
      await _chatService.sendChatMessage(
        chat.id,
        text: ChatMessageText(
          'Transaction ID: ${transaction.id}.\nPayer\'s name: ${name.text}',
        ),
      );
    }
  }
}
