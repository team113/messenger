// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
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
                ReactiveTextField(
                  key: const Key('PasswordField'),
                  state: c.password,
                  label: 'label_password'.l10n,
                  obscure: c.obscurePassword.value,
                  style: style.fonts.normal.regular.onBackground,
                  onSuffixPressed: c.obscurePassword.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgIcon(
                    c.obscurePassword.value
                        ? SvgIcons.visibleOff
                        : SvgIcons.visibleOn,
                  ),
                ),
                const SizedBox(height: 12),
                ReactiveTextField(
                  key: const Key('RepeatPasswordField'),
                  state: c.repeat,
                  label: 'label_repeat_password'.l10n,
                  obscure: c.obscureRepeat.value,
                  style: style.fonts.normal.regular.onBackground,
                  onSuffixPressed: c.obscureRepeat.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgIcon(
                    c.obscureRepeat.value
                        ? SvgIcons.visibleOff
                        : SvgIcons.visibleOn,
                  ),
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
                  child: RichText(
                    text: TextSpan(
                      style: style.fonts.medium.regular.secondary,
                      children: [
                        TextSpan(
                          text: 'alert_are_you_sure_want_to_log_out1'.l10n,
                        ),
                        TextSpan(
                          style: style.fonts.medium.regular.onBackground,
                          text:
                              c.myUser.value?.name?.val ??
                              c.myUser.value?.num.toString() ??
                              '',
                        ),
                        TextSpan(
                          text: 'alert_are_you_sure_want_to_log_out2'.l10n,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                if (!c.hasPassword.value) ...[
                  RichText(
                    text: TextSpan(
                      style: style.fonts.medium.regular.secondary,
                      children: [TextSpan(text: 'label_password_not_set'.l10n)],
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
                if (!c.canRecover) ...[
                  RichText(
                    text: TextSpan(
                      style: style.fonts.medium.regular.secondary,
                      children: [
                        TextSpan(text: 'label_email_or_phone_not_set'.l10n),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
                Obx(() {
                  if (!c.hasPassword.value && !c.canRecover) {
                    // Don't allow user to keep his profile, when no recovery
                    // methods are available or any password set, as they won't
                    // be able to sign in.
                    return const SizedBox();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RectangleButton(
                      key: const Key('KeepCredentialsSwitch'),
                      label: 'label_keep_credentials'.l10n,
                      toggleable: true,
                      radio: true,
                      selected: c.keep.value,
                      onPressed: c.keep.toggle,
                    ),
                  );
                }),
                if (c.hasPassword.value) ...[
                  OutlinedRoundedButton(
                    key: const Key('ConfirmLogoutButton'),
                    maxWidth: double.infinity,
                    onPressed: c.logout,
                    color: style.colors.primary,
                    child: Text(
                      'btn_logout'.l10n,
                      style: style.fonts.medium.regular.onPrimary,
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedRoundedButton(
                          key: const Key('ConfirmLogoutButton'),
                          maxWidth: double.infinity,
                          onPressed: c.logout,
                          color: style.colors.secondaryHighlight,
                          child: Text(
                            'btn_logout'.l10n,
                            style: style.fonts.medium.regular.onBackground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          key: const Key('SetPasswordButton'),
                          onPressed:
                              () =>
                                  c.stage.value =
                                      ConfirmLogoutViewStage.password,
                          title: 'btn_set_password'.l10n,
                        ),
                      ),
                    ],
                  ),
                ],
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: Scrollbar(
              key: Key('${c.stage.value?.name.capitalizeFirst}Stage'),
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
