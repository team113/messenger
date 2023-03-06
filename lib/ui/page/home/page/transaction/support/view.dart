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
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/text_field.dart';

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View showing details about a [MyUser.chatDirectLink].
///
/// Intended to be displayed with the [show] method.
class ContactSupportView extends StatelessWidget {
  const ContactSupportView({super.key});

  /// Displays a [ContactSupportView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const ContactSupportView());
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black);

    return GetBuilder(
      init: ContactSupportController(),
      builder: (ContactSupportController c) {
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
                    'Financial support'.l10n,
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
                      TextSpan(
                        text: 'label_support'.l10n,
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
              Padding(
                padding: ModalPopup.padding(context),
                child: ReactiveTextField(
                  state: c.name,
                  label: 'Payer name'.l10n,
                ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: ModalPopup.padding(context),
                child: Obx(() {
                  return OutlinedRoundedButton(
                    key: const Key('Proceed'),
                    maxWidth: double.infinity,
                    title: Text(
                      'btn_proceed'.l10n,
                      style: thin?.copyWith(
                        color:
                            c.name.isEmpty.value ? Colors.black : Colors.white,
                      ),
                    ),
                    onPressed: c.name.isEmpty.value ? null : () {},
                    color: Theme.of(context).colorScheme.secondary,
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
