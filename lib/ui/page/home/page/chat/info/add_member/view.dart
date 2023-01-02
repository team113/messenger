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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/l10n/l10n.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// [Chat.members] addition view.
///
/// Intended to be displayed with the [show] method.
class AddChatMemberView extends StatelessWidget {
  const AddChatMemberView({super.key, required this.chatId});

  /// ID of the [Chat] to add [ChatMember]s to.
  final ChatId chatId;

  /// Displays an [AddChatMemberView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, {required ChatId chatId}) {
    return ModalPopup.show(
      context: context,
      mobilePadding: const EdgeInsets.all(0),
      child: AddChatMemberView(chatId: chatId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: AddChatMemberController(
        chatId,
        Get.find(),
        pop: Navigator.of(context).pop,
      ),
      builder: (AddChatMemberController c) {
        return Obx(() {
          if (c.chat.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SearchView(
            categories: const [
              SearchCategory.recent,
              SearchCategory.contact,
              SearchCategory.user,
            ],
            title: 'label_add_participants'.l10n,
            submit: 'btn_add'.l10n,
            onSubmit: c.addMembers,
            enabled: c.status.value.isEmpty,
            chat: c.chat.value,
          );
        });
      },
    );
  }
}
