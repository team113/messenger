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
import '/l10n/l10n.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for muting specified [Chat].
class MuteChatView extends StatelessWidget {
  const MuteChatView({
    Key? key,
    this.onMute,
    required this.chatId,
  }) : super(key: key);

  /// ID of the [Chat] the would be muted.
  final ChatId chatId;

  /// Callback called, when chat must be muted.
  final Function(Duration? duration)? onMute;

  /// Displays a [MuteChatView] wrapped in a [ModalPopup].
  static void show(
    BuildContext context, {
    Function(Duration? duration)? onMute,
    required ChatId chatId,
  }) =>
      ModalPopup.show<MuteChatView?>(
        context: context,
        child: MuteChatView(
          chatId: chatId,
          onMute: onMute,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: MuteChatController(
        Get.find(),
        chatId: chatId,
        pop: Navigator.of(context).pop,
      ),
      builder: (MuteChatController c) => ConfirmDialog(
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
  }
}
