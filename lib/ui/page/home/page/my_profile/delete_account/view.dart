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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import 'controller.dart';

/// View for deleting the [MyUser]'s account.
///
/// Intended to be displayed with the [show] method.
class DeleteAccountView extends StatelessWidget {
  const DeleteAccountView({super.key});

  /// Displays a [DeleteAccountView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const DeleteAccountView());
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: DeleteAccountController(Get.find()),
      builder: (DeleteAccountController c) {
        return AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 250),
          sizeDuration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ModalPopupHeader(
                header: Center(
                  child: Text(
                    'label_delete_account'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Padding(
                padding: ModalPopup.padding(context),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: 'alert_account_will_be_deleted1'.l10n),
                      TextSpan(
                        text: c.myUser.value?.name?.val ??
                            c.myUser.value?.login?.val ??
                            c.myUser.value?.num.val ??
                            'dot'.l10n * 3,
                        style: const TextStyle(color: Colors.black),
                      ),
                      TextSpan(text: 'alert_account_will_be_deleted2'.l10n),
                    ],
                    style: thin?.copyWith(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.primary,
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
                    c.deleteAccount();
                    Navigator.of(context).pop();
                  },
                  color: Theme.of(context).colorScheme.secondary,
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
