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

import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/get.dart';
import '/util/message_popup.dart';
import 'confirm_delete/view.dart';
import 'controller.dart';

/// [Routes.erase] page.
class EraseView extends StatelessWidget {
  const EraseView({super.key});

  /// Displays a [EraseView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const EraseView());
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('EraseView'),
      init: EraseController(Get.find(), Get.findOrNull<MyUserService>()),
      builder: (EraseController c) {
        return Scaffold(
          appBar: CustomAppBar(
            leading: const [StyledBackButton()],
            title: Text('label_personal_data_deletion'.l10n),
            actions: const [SizedBox(width: 32)],
          ),
          body: Center(
            child: SingleChildScrollView(
              key: const Key('EraseScrollable'),
              child: Block(
                title: 'label_warning_uppercase'.l10n,
                titleStyle: style.fonts.large.regular.onBackground.copyWith(
                  color: style.colors.danger,
                ),
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              'label_personal_data_deletion_description1'.l10n,
                        ),
                        TextSpan(
                          text:
                              'label_personal_data_deletion_description2'.l10n,
                          style: style.fonts.small.regular.onBackground,
                        ),
                        TextSpan(
                          text:
                              'label_personal_data_deletion_description3'.l10n,
                        ),
                        TextSpan(
                          text:
                              'label_personal_data_deletion_description4'.l10n,
                          style: style.fonts.small.regular.onBackground,
                        ),
                        TextSpan(
                          text:
                              'label_personal_data_deletion_description5'.l10n,
                        ),
                      ],
                    ),
                    style: style.fonts.small.regular.secondary,
                  ),
                  SizedBox(height: 16),
                  _deletion(context, c),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Returns the [Block] containing the delete account button.
  Widget _deletion(BuildContext context, EraseController c) {
    return Obx(() {
      final List<Widget> children;

      if (c.authStatus.value.isLoading) {
        children = const [Center(child: CircularProgressIndicator())];
      } else if (c.authStatus.value.isEmpty) {
        children = [
          const SizedBox(height: 25),
          Text('label_sign_in'.l10n),
          const SizedBox(height: 25),
          ReactiveTextField(
            key: const Key('UsernameField'),
            state: c.login,
            label: 'label_identifier'.l10n,
            hint: 'label_sign_in_input'.l10n,
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          const SizedBox(height: 16),
          ReactiveTextField.password(
            key: const Key('PasswordField'),
            state: c.password,
            label: 'label_password'.l10n,
            hint: 'label_your_password'.l10n,
            obscured: c.obscurePassword,
            treatErrorAsStatus: false,
          ),
          const SizedBox(height: 25),
          Obx(() {
            final bool enabled =
                !c.login.isEmpty.value &&
                c.login.error.value == null &&
                !c.password.isEmpty.value &&
                c.password.error.value == null;

            return PrimaryButton(
              key: Key('ProceedButton'),
              title: 'btn_proceed'.l10n,
              onPressed: enabled ? c.signIn : null,
            );
          }),
        ];
      } else {
        children = [
          Paddings.dense(
            PrimaryButton(
              key: const Key('ConfirmDelete'),
              title: 'btn_delete_account'.l10n,
              onPressed: () => _deleteAccount(context, c),
              danger: true,
            ),
          ),
        ];
      }

      return AnimatedSizeAndFade(
        fadeDuration: const Duration(milliseconds: 250),
        sizeDuration: const Duration(milliseconds: 250),
        child: Column(
          key: Key(
            '${c.authStatus.value.isLoading}${c.authStatus.value.isEmpty}',
          ),
          children: children,
        ),
      );
    });
  }

  /// Opens a confirmation popup deleting the [MyUser]'s account.
  Future<void> _deleteAccount(BuildContext context, EraseController c) async {
    final style = Theme.of(context).style;

    if (c.myUser?.value?.emails.confirmed.isNotEmpty == true ||
        c.myUser?.value?.hasPassword == true) {
      await ConfirmDeleteView.show(context);
    } else {
      final bool? result = await MessagePopup.alert(
        'label_delete_account'.l10n,
        description: [
          TextSpan(
            text: 'alert_account_will_be_deleted1'.l10n,
            style: style.fonts.small.regular.secondary,
          ),
          TextSpan(
            text:
                c.myUser?.value?.name?.val ??
                c.myUser?.value?.login?.val ??
                c.myUser?.value?.num.toString() ??
                'dot'.l10n * 3,
            style: style.fonts.small.regular.onBackground,
          ),
          TextSpan(
            text: 'alert_account_will_be_deleted2'.l10n,
            style: style.fonts.small.regular.secondary,
          ),
        ],
        button: (context) => MessagePopup.deleteButton(
          context,
          key: Key('Proceed'),
          icon: SvgIcons.none,
          label: 'btn_confirm'.l10n,
        ),
      );

      if (result == true) {
        await c.deleteAccount();
      }
    }
  }
}
