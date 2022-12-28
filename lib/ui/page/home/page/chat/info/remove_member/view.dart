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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';

import '/domain/model/chat.dart';
import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for forwarding the provided [quotes] into the selected [Chat]s.
///
/// Intended to be displayed with the [show] method.
class RemoveMemberView extends StatelessWidget {
  const RemoveMemberView(this.chatId, this.user, {Key? key}) : super(key: key);

  final ChatId chatId;
  final RxUser user;

  /// Displays a [RemoveMemberView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required ChatId chatId,
    required RxUser user,
  }) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobilePadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      child: RemoveMemberView(chatId, user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: RemoveMemberController(Get.find(), user: user, chatId: chatId),
      builder: (RemoveMemberController c) {
        return AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 250),
          sizeDuration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16 - 12),
              ModalPopupHeader(
                header: Center(
                  child: Text(
                    c.me == user.id ? 'Leave group'.l10n : 'Remove member'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 25 - 12),
              if (c.me == user.id)
                Padding(
                  padding: ModalPopup.padding(context),
                  child: RichText(
                    text: TextSpan(
                      children: const [TextSpan(text: 'Вы покидаете группу.')],
                      style: thin?.copyWith(
                        fontSize: 15,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: ModalPopup.padding(context),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: 'alert_user_will_be_removed1'.l10n),
                        TextSpan(
                          text: c.user.user.value.name?.val ??
                              c.user.user.value.num.val,
                          style: const TextStyle(color: Colors.black),
                        ),
                        TextSpan(text: 'alert_user_will_be_removed2'.l10n),
                      ],
                      style: thin?.copyWith(
                        fontSize: 15,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 25),
              Padding(
                padding: ModalPopup.padding(context),
                child: OutlinedRoundedButton(
                  key: const Key('Proceed'),
                  maxWidth: double.infinity,
                  title: Text(
                    'btn_proceed'.l10n,
                    style: thin?.copyWith(color: Colors.white),
                  ),
                  onPressed: () {
                    c.removeChatMember();
                    Navigator.of(context).pop();
                  },
                  color: const Color(0xFF63B4FF),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
