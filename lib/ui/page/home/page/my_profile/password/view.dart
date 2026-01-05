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

import '/domain/model/my_user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// View for updating the [MyUser]'s password.
///
/// Intended to be displayed with the [show] method.
class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});

  /// Displays a [ChangePasswordView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const ChangePasswordView());
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: ChangePasswordController(Get.find()),
      builder: (ChangePasswordController c) {
        return Obx(() {
          final Widget child;

          switch (c.stage.value) {
            case ChangePasswordFlowStage.set:
            case ChangePasswordFlowStage.changed:
              child = Scrollbar(
                controller: c.scrollController,
                child: ListView(
                  controller: c.scrollController,
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: Text(
                          c.stage.value == ChangePasswordFlowStage.set
                              ? 'label_password_set'.l10n
                              : 'label_password_changed'.l10n,
                          style: style.fonts.small.regular.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    PrimaryButton(
                      key: const Key('Close'),
                      onPressed: Navigator.of(context).pop,
                      title: 'btn_ok'.l10n,
                    ),
                  ],
                ),
              );
              break;

            default:
              child = Scrollbar(
                controller: c.scrollController,
                child: ListView(
                  controller: c.scrollController,
                  shrinkWrap: true,
                  children: [
                    if (c.hasPassword)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ReactiveTextField.password(
                          state: c.oldPassword,
                          label: 'label_current_password'.l10n,
                          hint: 'label_your_password'.l10n,
                          obscured: c.obscurePassword,
                          treatErrorAsStatus: false,
                        ),
                      ),
                    ReactiveTextField.password(
                      key: const Key('NewPasswordField'),
                      state: c.newPassword,
                      label: 'label_new_password'.l10n,
                      hint: 'label_enter_password'.l10n,
                      obscured: c.obscureNewPassword,
                      treatErrorAsStatus: false,
                    ),
                    const SizedBox(height: 16),
                    ReactiveTextField.password(
                      key: const Key('RepeatPasswordField'),
                      state: c.repeatPassword,
                      label: 'label_confirm_password'.l10n,
                      hint: 'label_repeat_password'.l10n,
                      obscured: c.obscureRepeatPassword,
                      treatErrorAsStatus: false,
                    ),
                    const SizedBox(height: 25),
                    Obx(() {
                      final bool enabled;
                      if (c.repeatPassword.status.value.isLoading) {
                        enabled = false;
                      } else if (c.myUser.value?.hasPassword == true) {
                        enabled = !c.oldPassword.isEmpty.value;
                      } else {
                        enabled =
                            !c.newPassword.isEmpty.value &&
                            !c.repeatPassword.isEmpty.value;
                      }

                      return PrimaryButton(
                        key: const Key('Proceed'),
                        onPressed: enabled ? c.changePassword : null,
                        leading: enabled
                            ? const SvgIcon(SvgIcons.passwordWhite)
                            : const SvgIcon(SvgIcons.passwordGrey),
                        title: 'btn_save'.l10n,
                      );
                    }),
                  ],
                ),
              );
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModalPopupHeader(
                  text:
                      c.hasPassword &&
                          c.stage.value != ChangePasswordFlowStage.set
                      ? 'label_change_password'.l10n
                      : 'label_set_password'.l10n,
                ),
                const SizedBox(height: 13),
                Flexible(
                  child: Padding(
                    padding: ModalPopup.padding(context),
                    child: child,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }
}
