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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// View of the [Routes.login] page.
class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: LoginController(Get.find()),
      builder: (LoginController c) => Obx(
        () {
          /// Application bar consisting of a "Back" button and a label.
          Widget appBar = SizedBox(
            height: 45,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: router.auth,
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_ios, color: Colors.grey),
                      Text(
                        'btn_back'.l10n,
                        style: context.textTheme.bodyText1!
                            .copyWith(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'label_sign_in'.l10n,
                  style: context.textTheme.bodyText1!
                      .copyWith(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(width: 5),
              ],
            ),
          );

          /// Wrapper around "Next" button.
          List<Widget> _nextButton({Key? key, VoidCallback? onPressed}) => [
                const SizedBox(height: 8),
                SizedBox(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Spacer(),
                      TextButton(
                        key: key,
                        onPressed: onPressed,
                        child: Text('btn_next'.l10n,
                            style: context.textTheme.caption!
                                .copyWith(color: Colors.grey, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ];

          const EdgeInsets inputPadding = EdgeInsets.fromLTRB(10, 10, 10, 0);

          return c.authStatus.value.isLoading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : IgnorePointer(
                  ignoring: c.authStatus.value.isSuccess,
                  child: Scaffold(
                    key: const Key('LoginView'),
                    body: SafeArea(
                      child: SingleChildScrollView(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 10),
                                appBar,
                                const Divider(thickness: 3),
                                const ListTile(),
                                Padding(
                                  padding: inputPadding,
                                  child: ReactiveTextField(
                                    key: const Key('UsernameField'),
                                    state: c.login,
                                    label: 'label_sign_in_input'.l10n,
                                    onChanged: () =>
                                        c.showPwdSection.value = false,
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: c.showPwdSection.value
                                      ? Padding(
                                          padding: inputPadding,
                                          child: ReactiveTextField(
                                            key:
                                                const ValueKey('PasswordField'),
                                            obscure: true,
                                            state: c.password,
                                            label: 'label_password'.l10n,
                                          ),
                                        )
                                      : Container(),
                                ),
                                ..._nextButton(
                                  key: const Key('LoginNextTile'),
                                  onPressed: () {
                                    if (c.showPwdSection.value) {
                                      c.password.submit();
                                    } else {
                                      c.login.submit();
                                    }
                                  },
                                ),
                                const Divider(thickness: 3),
                                ListTile(
                                  title: Text(
                                    '${'label_recover_account'.l10n}:',
                                    style:
                                        context.textTheme.bodyText2!.copyWith(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: inputPadding,
                                  child: ReactiveTextField(
                                    key: const ValueKey('RecoveryField'),
                                    state: c.recovery,
                                    label: 'label_sign_in_input'.l10n,
                                    enabled: (c.showCodeSection.value)
                                        ? false
                                        : true,
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: c.showCodeSection.value
                                      ? Padding(
                                          padding: inputPadding,
                                          child: ReactiveTextField(
                                            key: const Key('RecoveryCodeField'),
                                            state: c.recoveryCode,
                                            label: 'label_recovery_code'.l10n,
                                            type: TextInputType.number,
                                            enabled:
                                                (c.showNewPasswordSection.value)
                                                    ? false
                                                    : true,
                                          ),
                                        )
                                      : Container(),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: c.showNewPasswordSection.value
                                      ? Padding(
                                          padding: inputPadding,
                                          child: ReactiveTextField(
                                            key: const Key('PasswordField'),
                                            state: c.newPassword,
                                            label: 'label_new_password'.l10n,
                                            obscure: true,
                                          ),
                                        )
                                      : Container(),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: c.showNewPasswordSection.value
                                      ? Padding(
                                          padding: inputPadding,
                                          child: ReactiveTextField(
                                            key: const Key(
                                                'RepeatPasswordField'),
                                            state: c.repeatPassword,
                                            label: 'label_repeat_password'.l10n,
                                            obscure: true,
                                          ),
                                        )
                                      : Container(),
                                ),
                                ..._nextButton(
                                  key: const ValueKey('RecoveryNextTile'),
                                  onPressed: () {
                                    if (c.showNewPasswordSection.value) {
                                      c.resetUserPassword();
                                    } else if (!c.showCodeSection.value) {
                                      c.recovery.submit();
                                    } else if (c.showCodeSection.value) {
                                      c.recoveryCode.submit();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
        },
      ),
    );
  }
}
