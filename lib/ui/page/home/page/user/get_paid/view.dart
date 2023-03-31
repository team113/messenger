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

import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View showing details about a [MyUser.chatDirectLink].
///
/// Intended to be displayed with the [show] method.
class GetPaidView2 extends StatelessWidget {
  const GetPaidView2({super.key});

  /// Displays a [LinkDetailsView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const GetPaidView2());
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black);

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
                'label_get_paid_for_incoming'.l10n,
                style: thin?.copyWith(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 0),
          Padding(
            padding: ModalPopup.padding(context),
            child: RichText(
              text: TextSpan(
                children: const [
                  TextSpan(
                    text:
                        'Вы можете принимать плату от Ваших собеседников за отправленные Вам сообщения и совершенные звонки.',
                  ),
                ],
                style: thin?.copyWith(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}
