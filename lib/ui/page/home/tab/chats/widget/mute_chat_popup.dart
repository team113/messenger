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

import '/domain/model/chat.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/widget/modal_popup.dart';
import '/util/obs/obs.dart';

class MuteChatPopup {
  static void show(
    BuildContext context, {
    Function(Duration? duration)? onMute,
    required ChatId chatId,
  }) async {
    // [Chat]s service.
    final ChatService chatService = Get.find();

    // Subscription for [ChatService.chats] changes.
    final chatsSubscription = chatService.chats.changes.listen((event) {
      if (event.op == OperationKind.removed && chatId == event.key) {
        Navigator.of(context).pop();
      }
    });

    await ModalPopup.show<ConfirmDialog?>(
      context: context,
      child: ConfirmDialog(
        title: 'label_mute_chat_for'.l10n,
        variants: const [
          Duration(minutes: 15),
          Duration(minutes: 30),
          Duration(hours: 1),
          Duration(hours: 6),
          Duration(hours: 12),
          Duration(days: 1),
          Duration(days: 7),
          null,
        ]
            .map(
              (e) => ConfirmDialogVariant(
                onProceed: () => onMute?.call(e),
                child: Text(
                  'label_mute_for'.l10nfmt({
                    'days': e?.inDays ?? 0,
                    'hours': e?.inHours ?? 0,
                    'minutes': e?.inMinutes ?? 0,
                  }),
                  key: e == null ? const Key('MuteForever') : null,
                ),
              ),
            )
            .toList(),
      ),
    );

    chatsSubscription.cancel();
  }
}
