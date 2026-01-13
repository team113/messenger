// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/checkbox_button.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// View for alerting about password not being set.
///
/// Intended to be displayed with the [show] method.
class ConfirmLogoutView extends StatelessWidget {
  const ConfirmLogoutView({super.key});

  /// Displays a [ConfirmLogoutView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const ConfirmLogoutView());
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('ConfirmLogoutView'),
      init: ConfirmLogoutController(Get.find(), Get.find()),
      builder: (ConfirmLogoutController c) {
        return Obx(() {
          final Widget header;
          final List<Widget> children;

          switch (c.stage.value) {
            case ConfirmLogoutViewStage.password:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = null,
                text: 'btn_set_password'.l10n,
              );

              children = [
                ReactiveTextField.password(
                  key: const Key('PasswordField'),
                  state: c.password,
                  label: 'label_password'.l10n,
                  hint: 'label_enter_password'.l10n,
                  obscured: c.obscurePassword,
                  style: style.fonts.normal.regular.onBackground,
                  treatErrorAsStatus: false,
                  autocomplete: AutocompleteKind.newPassword,
                ),
                const SizedBox(height: 12),
                ReactiveTextField.password(
                  key: const Key('RepeatPasswordField'),
                  state: c.repeat,
                  label: 'label_confirm_password'.l10n,
                  hint: 'label_repeat_password'.l10n,
                  obscured: c.obscureRepeat,
                  style: style.fonts.normal.regular.onBackground,
                  treatErrorAsStatus: false,
                  autocomplete: AutocompleteKind.newPassword,
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled =
                      !c.repeat.status.value.isLoading &&
                      !c.password.isEmpty.value &&
                      !c.repeat.isEmpty.value;

                  return PrimaryButton(
                    key: const Key('ChangePasswordButton'),
                    onPressed: enabled ? c.setPassword : null,
                    title: 'btn_proceed'.l10n,
                  );
                }),
              ];
              break;

            case ConfirmLogoutViewStage.success:
              header = ModalPopupHeader(text: 'btn_set_password'.l10n);

              children = [
                Text(
                  'label_password_set'.l10n,
                  style: style.fonts.medium.regular.secondary,
                ),
                const SizedBox(height: 25),
                Center(
                  child: PrimaryButton(
                    key: const Key('CloseButton'),
                    onPressed: Navigator.of(context).pop,
                    title: 'btn_close'.l10n,
                  ),
                ),
              ];
              break;

            default:
              header = ModalPopupHeader(text: 'btn_logout'.l10n);

              children = [
                Center(
                  child: Text(
                    '${c.myUser.value?.name ?? c.myUser.value?.num}',
                    style: style.fonts.normal.regular.onBackground,
                  ),
                ),
                const SizedBox(height: 16),
                if (!c.hasPassword.value) ...[
                  RichText(
                    text: TextSpan(
                      style: style.fonts.small.regular.secondary,
                      children: [
                        TextSpan(
                          text: 'label_password_not_set1'.l10n,
                          style: style.fonts.small.regular.onBackground,
                        ),
                        TextSpan(text: 'label_password_not_set2'.l10n),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (!c.canRecover) ...[
                  RichText(
                    text: TextSpan(
                      style: style.fonts.small.regular.secondary,
                      children: [
                        TextSpan(text: 'label_email_or_phone_not_set1'.l10n),
                        TextSpan(
                          text: 'label_email_or_phone_not_set2'.l10n,
                          style: style.fonts.small.regular.onBackground,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (c.canRecover || c.hasPassword.value)
                  Obx(() {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: RowCheckboxButton(
                        key: const Key('KeepCredentialsSwitch'),
                        label: 'btn_save_my_credentials_for_one_click'.l10n,
                        value: c.keep.value,
                        onPressed: (e) => c.keep.value = e,
                      ),
                    );
                  })
                else
                  SizedBox(height: 8),

                if (!c.hasPassword.value) ...[
                  PrimaryButton(
                    key: const Key('SetPasswordButton'),
                    onPressed: () =>
                        c.stage.value = ConfirmLogoutViewStage.password,
                    title: 'btn_set_password'.l10n,
                    leading: SvgIcon(SvgIcons.passwordWhite),
                  ),
                  const SizedBox(height: 10),
                ],
                PrimaryButton(
                  key: const Key('ConfirmLogoutButton'),
                  onPressed: () {
                    c.logout();
                    Navigator.of(context).pop();
                  },
                  danger: true,
                  title: 'btn_logout'.l10n,
                  leading: SvgIcon(SvgIcons.logoutWhite),
                ),
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: Scrollbar(
              key: Key('${c.stage.value?.name.capitalized}Stage'),
              controller: c.scrollController,
              child: ListView(
                controller: c.scrollController,
                shrinkWrap: true,
                children: [
                  header,
                  const SizedBox(height: 12),
                  ...children.map(
                    (e) =>
                        Padding(padding: ModalPopup.padding(context), child: e),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
