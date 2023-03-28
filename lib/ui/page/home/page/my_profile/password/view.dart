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
import 'package:messenger/themes.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// View for updating the [MyUser]'s password.
///
/// Intended to be displayed with the [show] method.
class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});

  /// Displays a [ChangePasswordView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, {UserEmail? email}) {
    return ModalPopup.show(context: context, child: const ChangePasswordView());
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<Style>()!;
    final TextStyle? thin = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(color: style.onBackground);

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
                      child: Text(
                        c.stage.value == ChangePasswordFlowStage.set
                            ? 'label_password_set'.l10n
                            : 'label_password_changed'.l10n,
                        style: thin?.copyWith(
                          fontSize: 15,
                          color: Theme.of(context).extension<Style>()!.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    OutlinedRoundedButton(
                      key: const Key('Close'),
                      maxWidth: double.infinity,
                      title: Text(
                        'btn_close'.l10n,
                        style: thin?.copyWith(
                            color: Theme.of(context)
                                .extension<Style>()!
                                .onPrimary),
                      ),
                      onPressed: Navigator.of(context).pop,
                      color: Theme.of(context).extension<Style>()!.secondary,
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
                    Obx(() {
                      if (c.myUser.value?.hasPassword != true) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: Text(
                            'label_password_not_set_info'.l10n,
                            style: thin?.copyWith(
                              fontSize: 15,
                              color: style.primary,
                            ),
                          ),
                        );
                      }

                      return const SizedBox();
                    }),
                    Obx(() {
                      if (c.myUser.value?.hasPassword == true) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ReactiveTextField(
                            state: c.oldPassword,
                            label: 'label_current_password'.l10n,
                            fillColor: style.onPrimary,
                            obscure: c.obscurePassword.value,
                            onSuffixPressed: c.obscurePassword.toggle,
                            treatErrorAsStatus: false,
                            trailing: SvgLoader.asset(
                              'assets/icons/visible_${c.obscurePassword.value ? 'off' : 'on'}.svg',
                              width: 17.07,
                            ),
                          ),
                        );
                      }

                      return const SizedBox();
                    }),
                    ReactiveTextField(
                      key: const Key('NewPasswordField'),
                      state: c.newPassword,
                      label: 'label_new_password'.l10n,
                      fillColor: style.onPrimary,
                      obscure: c.obscureNewPassword.value,
                      onSuffixPressed: c.obscureNewPassword.toggle,
                      treatErrorAsStatus: false,
                      trailing: SvgLoader.asset(
                        'assets/icons/visible_${c.obscureNewPassword.value ? 'off' : 'on'}.svg',
                        width: 17.07,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ReactiveTextField(
                      key: const Key('RepeatPasswordField'),
                      state: c.repeatPassword,
                      label: 'label_repeat_password'.l10n,
                      fillColor: style.onPrimary,
                      obscure: c.obscureRepeatPassword.value,
                      onSuffixPressed: c.obscureRepeatPassword.toggle,
                      treatErrorAsStatus: false,
                      trailing: SvgLoader.asset(
                        'assets/icons/visible_${c.obscureRepeatPassword.value ? 'off' : 'on'}.svg',
                        width: 17.07,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Obx(() {
                      final bool enabled;
                      if (c.myUser.value?.hasPassword == true) {
                        enabled = !c.oldPassword.isEmpty.value &&
                            !c.newPassword.isEmpty.value &&
                            !c.repeatPassword.isEmpty.value;
                      } else {
                        enabled = !c.newPassword.isEmpty.value &&
                            !c.repeatPassword.isEmpty.value;
                      }

                      return OutlinedRoundedButton(
                        key: const Key('Proceed'),
                        maxWidth: double.infinity,
                        title: Text(
                          'btn_proceed'.l10n,
                          style: thin?.copyWith(
                            color: enabled
                                ? Theme.of(context)
                                    .extension<Style>()!
                                    .onPrimary
                                : Theme.of(context)
                                    .extension<Style>()!
                                    .onBackground,
                          ),
                        ),
                        onPressed: enabled ? c.changePassword : null,
                        color: Theme.of(context).extension<Style>()!.secondary,
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
                  header: Center(
                    child: Text(
                      c.myUser.value?.hasPassword == true &&
                              c.stage.value != ChangePasswordFlowStage.set
                          ? 'label_change_password'.l10n
                          : 'label_set_password'.l10n,
                      style: thin?.copyWith(fontSize: 18),
                    ),
                  ),
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
