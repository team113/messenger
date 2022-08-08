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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/ui/page/home/page/chat/forward/controller.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/widget/modal_popup.dart';

/// View of the forward messages modal.
class ChatForwardView extends StatelessWidget {
  const ChatForwardView({
    Key? key,
    required this.fromId,
    required this.forwardItem,
  }) : super(key: key);

  final ChatId fromId;

  final ChatItemQuote forwardItem;

  static Future<T?> show<T>(
    BuildContext context,
    ChatId fromId,
    ChatItemQuote forwardItem,
  ) {
    return ModalPopup.show(
        context: context,
        child: ChatForwardView(
          fromId: fromId,
          forwardItem: forwardItem,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: ChatForwardController(
          Get.find(),
          fromId,
          forwardItem,
        ),
        builder: (ChatForwardController c) {
          return ListView(
            children: c.chats.map((c) => ListTile()).toList(),
          );
        });
  }

  /// Returns a [ListTile] with the information of the provided [User].
  Widget _chat(RxChat chat) => ListTile(
        leading: AvatarWidget.fromRxChat(chat),
        title: Text(chat.title.value),
        trailing: trailingIcon == null
            ? null
            : IconButton(
                onPressed: () {
                  onTrailingTap?.call(user.user.value);
                  c.addToRecent(user);
                },
                icon: trailingIcon!,
              ),
        onTap: () {
          onUserTap?.call(user.user.value);
          c.addToRecent(user);
          searchController.clear();
          searchController.close();
        },
      );
}
