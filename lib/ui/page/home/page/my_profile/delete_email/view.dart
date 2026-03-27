// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View for deleting an [UserEmail].
///
/// Intended to be displayed with the [show] method.
class DeleteEmailView extends StatelessWidget {
  const DeleteEmailView({super.key, required this.email});

  /// [UserEmail] to delete.
  final UserEmail email;

  /// Displays a [DeleteEmailView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, {required UserEmail email}) {
    return ModalPopup.show(
      context: context,
      child: DeleteEmailView(email: email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: DeleteEmailController(Get.find(), Get.find(), email: email),
      builder: (DeleteEmailController c) {
        return Obx(() {
          final List<Widget> children;

          switch (c.page.value) {
            case DeleteEmailPage.delete:
              final bool hasPassword = c.myUser.value?.hasPassword != false;

              children = [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    c.email.val,
                    textAlign: TextAlign.center,
                    style: style.fonts.normal.regular.onBackground,
                  ),
                ),
                Text(
                  hasPassword
                      ? 'label_enter_password_or_one_time_code'.l10n
                      : 'label_enter_one_time_code'.l10n,
                  style: style.fonts.small.regular.secondary,
                ),
                const SizedBox(height: 24),
                ReactiveTextField.password(
                  key: const Key('PasswordField'),
                  state: c.passwordOrCode,
                  obscured: c.obscurePasswordOrCode,
                  treatErrorAsStatus: false,
                  label: hasPassword
                      ? 'label_password_or_one_time_code'.l10n
                      : 'label_one_time_password'.l10n,
                  hint: hasPassword
                      ? 'label_enter_password_or_code'.l10n
                      : 'label_enter_code'.l10n,
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled =
                      !c.passwordOrCode.isEmpty.value &&
                      c.passwordOrCode.error.value == null;

                  return Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          key: const Key('Resend'),
                          onPressed: c.resendEmailTimeout.value == 0
                              ? c.sendConfirmationCode
                              : null,
                          title: c.resendEmailTimeout.value == 0
                              ? 'label_resend'.l10n
                              : 'label_resend_timeout'.l10nfmt({
                                  'timeout': c.resendEmailTimeout.value,
                                }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          key: const Key('Proceed'),
                          danger: true,
                          title: 'btn_delete'.l10n,
                          onPressed: enabled ? c.passwordOrCode.submit : null,
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 16),
              ];
              break;

            case DeleteEmailPage.success:
              children = [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'label_email_deleted'.l10n,
                    textAlign: TextAlign.center,
                    style: style.fonts.small.regular.secondary,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  key: const Key('Proceed'),
                  onPressed: context.popModal,
                  title: 'btn_ok'.l10n,
                ),
                const SizedBox(height: 16),
              ];
              break;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ModalPopupHeader(text: 'label_delete_email'.l10n),
              const SizedBox(height: 13),
              Flexible(
                child: Padding(
                  padding: ModalPopup.padding(context),
                  child: Scrollbar(
                    controller: c.scrollController,
                    child: AnimatedSizeAndFade(
                      sizeDuration: const Duration(milliseconds: 250),
                      fadeDuration: const Duration(milliseconds: 250),
                      child: ListView(
                        key: Key(c.page.value.name),
                        controller: c.scrollController,
                        shrinkWrap: true,
                        children: children,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }
}
