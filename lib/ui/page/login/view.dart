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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import 'controller.dart';
import 'terms_of_use/view.dart';
import 'widget/sign_button.dart';

/// View for logging in or recovering access on.
///
/// Intended to be displayed with the [show] method.
class LoginView extends StatelessWidget {
  const LoginView({
    super.key,
    this.initial = LoginViewStage.signUp,
    this.myUser,
    this.onSuccess,
  });

  /// Initial [LoginViewStage] this [LoginView] should open.
  final LoginViewStage initial;

  /// Callback, called when this [LoginView] successfully signs into an account.
  ///
  /// If not specified, the [RouteLinks.home] redirect is invoked.
  final void Function({bool? signedUp})? onSuccess;

  /// [MyUser], whose data should be prefilled in the fields.
  final MyUser? myUser;

  /// Displays a [LoginView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    LoginViewStage initial = LoginViewStage.signUp,
    MyUser? myUser,
    void Function({bool? signedUp})? onSuccess,
  }) {
    return ModalPopup.show(
      context: context,
      child: LoginView(initial: initial, myUser: myUser, onSuccess: onSuccess),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('LoginView'),
      init: LoginController(
        Get.find(),
        initial: initial,
        myUser: myUser,
        onSuccess: onSuccess,
      ),
      builder: (LoginController c) {
        return Obx(() {
          final Widget header;
          final List<Widget> children;

          switch (c.stage.value) {
            case LoginViewStage.recovery:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signIn,
                text: 'label_recover_account'.l10n,
              );

              children = [
                Text(
                  'label_recover_account_description'.l10n,
                  style: style.fonts.small.regular.secondary,
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('RecoveryField'),
                  state: c.recovery,
                  label: 'label_identifier'.l10n,
                  hint: 'label_sign_in_input'.l10n,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  spellCheck: false,
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('Proceed'),
                  title: 'btn_proceed'.l10n,
                  onPressed: c.recovery.isEmpty.value
                      ? null
                      : c.recovery.submit,
                ),
              ];
              break;

            case LoginViewStage.recoveryCode:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signIn,
                text: 'label_recover_account'.l10n,
              );

              children = [
                Text(
                  'label_recovery_code_sent'.l10n,
                  style: style.fonts.normal.regular.secondary,
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('RecoveryCodeField'),
                  state: c.recoveryCode,
                  label: 'label_recovery_code'.l10n,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('Proceed'),
                  title: 'btn_proceed'.l10n,
                  onPressed: c.recoveryCode.isEmpty.value
                      ? null
                      : c.recoveryCode.submit,
                ),
              ];
              break;

            case LoginViewStage.recoveryPassword:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signIn,
                text: 'label_recover_account'.l10n,
              );

              children = [
                Text(
                  'label_recovery_enter_new_password'.l10n,
                  style: style.fonts.normal.regular.secondary,
                ),
                const SizedBox(height: 25),
                ReactiveTextField.password(
                  key: const Key('PasswordField'),
                  state: c.newPassword,
                  label: 'label_new_password'.l10n,
                  hint: 'label_enter_password'.l10n,
                  obscured: c.obscureNewPassword,
                  treatErrorAsStatus: false,
                  autocomplete: AutocompleteKind.newPassword,
                ),
                const SizedBox(height: 16),
                ReactiveTextField.password(
                  key: const Key('RepeatPasswordField'),
                  state: c.repeatPassword,
                  label: 'label_confirm_password'.l10n,
                  hint: 'label_repeat_password'.l10n,
                  obscured: c.obscureRepeatPassword,
                  treatErrorAsStatus: false,
                  autocomplete: AutocompleteKind.newPassword,
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled =
                      !c.newPassword.isEmpty.value &&
                      !c.repeatPassword.isEmpty.value;

                  return PrimaryButton(
                    key: const Key('Proceed'),
                    title: 'btn_proceed'.l10n,
                    onPressed: enabled ? c.resetUserPassword : null,
                  );
                }),
              ];
              break;

            case LoginViewStage.signUpWithPassword:
              header = ModalPopupHeader(
                text: 'label_sign_up_with_password'.l10n,
                onBack: () => c.stage.value = LoginViewStage.signUp,
              );

              children = [
                const SizedBox(height: 12),
                ReactiveTextField(
                  key: const Key('UsernameField'),
                  state: c.login,
                  label: 'label_login'.l10n,
                  hint: 'alphanumeric-login_123',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  spellCheck: false,
                  autocomplete: AutocompleteKind.username,
                ),
                const SizedBox(height: 16),
                ReactiveTextField.password(
                  key: const ValueKey('PasswordField'),
                  state: c.password,
                  label: 'label_password'.l10n,
                  hint: 'label_enter_password'.l10n,
                  obscured: c.obscurePassword,
                  treatErrorAsStatus: false,
                  autocomplete: AutocompleteKind.newPassword,
                ),
                const SizedBox(height: 16),
                ReactiveTextField.password(
                  key: const ValueKey('RepeatPasswordField'),
                  state: c.repeatPassword,
                  label: 'label_confirm_password'.l10n,
                  hint: 'label_repeat_password'.l10n,
                  obscured: c.obscureRepeatPassword,
                  treatErrorAsStatus: false,
                  autocomplete: AutocompleteKind.newPassword,
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled =
                      !c.login.isEmpty.value &&
                      !c.password.isEmpty.value &&
                      !c.repeatPassword.isEmpty.value &&
                      !c.authStatus.value.isLoading;

                  return PrimaryButton(
                    key: const Key('RegisterButton'),
                    title: 'btn_sign_up'.l10n,
                    onPressed: enabled ? c.repeatPassword.submit : null,
                  );
                }),
              ];
              break;

            case LoginViewStage.signUpWithEmail:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () {
                  c.stage.value = LoginViewStage.signUp;
                  c.email.unsubmit();
                },
              );

              children = [
                ReactiveTextField(
                  state: c.email,
                  label: 'label_email'.l10n,
                  hint: 'label_email_example'.l10n,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  style: style.fonts.normal.regular.onBackground,
                  treatErrorAsStatus: false,
                  spellCheck: false,
                ),
                const SizedBox(height: 25),
                Center(
                  child: Obx(() {
                    final bool enabled = !c.email.isEmpty.value;

                    return PrimaryButton(
                      onPressed: enabled ? c.email.submit : null,
                      title: 'btn_send_one_time_code'.l10n,
                      leading: SvgIcon(
                        enabled ? SvgIcons.emailWhite : SvgIcons.emailGrey,
                      ),
                    );
                  }),
                ),
              ];
              break;

            case LoginViewStage.signUp:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: c.returnTo == null
                    ? null
                    : () => c.stage.value = c.returnTo!,
              );

              children = [
                SignButton(
                  key: const Key('LoginAndPassword'),
                  title: 'btn_login_and_password'.l10n,
                  icon: const SvgIcon(SvgIcons.password),
                  onPressed: () =>
                      c.stage.value = LoginViewStage.signUpWithPassword,
                ),
                const SizedBox(height: 16),
                SignButton(
                  key: const Key('Email'),
                  title: 'btn_email'.l10n,
                  icon: const SvgIcon(SvgIcons.email),
                  onPressed: () =>
                      c.stage.value = LoginViewStage.signUpWithEmail,
                ),
                const SizedBox(height: 16),
                _terms(context),
              ];
              break;

            case LoginViewStage.signUpWithEmailCode:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signUpWithEmail,
                text: 'label_sign_up'.l10n,
              );

              children = [
                Center(child: Text(c.email.text)),
                SizedBox(height: 20),
                Text(
                  'label_add_email_confirmation_sent'.l10n,
                  style: style.fonts.small.regular.secondary,
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('EmailCodeField'),
                  state: c.emailCode,
                  label: 'label_one_time_password'.l10n,
                  type: TextInputType.number,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hint: 'label_enter_code'.l10n,
                  obscure: c.obscureCode.value,
                  onSuffixPressed: c.obscureCode.toggle,
                  trailing: Center(
                    child: SvgIcon(
                      c.obscureCode.value
                          ? SvgIcons.visibleOff
                          : SvgIcons.visibleOn,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool canResend =
                      c.codeTimeout.value == 0 && c.authStatus.value.isEmpty;

                  final bool enabled =
                      !c.emailCode.isEmpty.value && c.authStatus.value.isEmpty;

                  return Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          key: const Key('Resend'),
                          onPressed: canResend ? c.resendEmail : null,
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
                          onPressed: enabled ? c.emailCode.submit : null,
                          title: 'btn_sign_up'.l10n,
                        ),
                      ),
                    ],
                  );
                }),
              ];
              break;

            case LoginViewStage.signInWithPassword:
              header = ModalPopupHeader(
                text: 'label_sign_in_with_password'.l10n,
                onBack: () => c.stage.value = LoginViewStage.signIn,
              );

              children = [
                const SizedBox(height: 12),
                ReactiveTextField(
                  key: const Key('UsernameField'),
                  state: c.login,
                  label: 'label_identifier'.l10n,
                  hint: 'label_sign_in_input'.l10n,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  spellCheck: false,
                  autocomplete: AutocompleteKind.username,
                ),
                const SizedBox(height: 16),
                ReactiveTextField.password(
                  key: const ValueKey('PasswordField'),
                  state: c.password,
                  label: 'label_password'.l10n,
                  hint: 'label_your_password'.l10n,
                  obscured: c.obscurePassword,
                  treatErrorAsStatus: false,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(21, 8, 8, 8),
                  child: WidgetButton(
                    key: Key('ForgotPassword'),
                    onPressed: () {
                      c.recovery.clear();
                      c.recoveryCode.clear();
                      c.newPassword.clear();
                      c.repeatPassword.clear();
                      c.recovery.text = c.login.text;
                      c.recovered.value = false;
                      c.stage.value = LoginViewStage.recovery;
                    },
                    child: Text(
                      'btn_forgot_password'.l10n,
                      style: style.fonts.small.regular.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled =
                      !c.login.isEmpty.value &&
                      !c.password.isEmpty.value &&
                      c.signInTimeout.value == 0 &&
                      !c.authStatus.value.isLoading;

                  return PrimaryButton(
                    key: const Key('LoginButton'),
                    title: c.signInTimeout.value == 0
                        ? 'btn_sign_in'.l10n
                        : 'label_wait_seconds'.l10nfmt({
                            'for': c.signInTimeout.value,
                          }),
                    onPressed: enabled ? c.password.submit : null,
                  );
                }),
              ];
              break;

            case LoginViewStage.signInWithEmail:
              header = ModalPopupHeader(
                text: 'label_sign_in_with_one_time_code'.l10n,
                onBack: () {
                  c.stage.value = LoginViewStage.signIn;
                  c.email.unsubmit();
                },
              );

              children = [
                ReactiveTextField(
                  state: c.identifier,
                  label: 'label_identifier'.l10n,
                  hint: 'label_sign_in_input'.l10n,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  style: style.fonts.normal.regular.onBackground,
                  treatErrorAsStatus: false,
                  spellCheck: false,
                ),
                const SizedBox(height: 25),
                Center(
                  child: Obx(() {
                    final bool enabled = !c.identifier.isEmpty.value;

                    return PrimaryButton(
                      onPressed: enabled ? c.identifier.submit : null,
                      title: 'btn_send_one_time_code'.l10n,
                      leading: SvgIcon(
                        enabled ? SvgIcons.emailWhite : SvgIcons.emailGrey,
                      ),
                    );
                  }),
                ),
              ];
              break;

            case LoginViewStage.signInWithEmailCode:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signInWithEmail,
                text: 'label_sign_in_with_one_time_code'.l10n,
              );

              children = [
                Center(child: Text(c.identifier.text)),
                SizedBox(height: 20),
                Text(
                  'label_add_email_confirmation_sent'.l10n,
                  style: style.fonts.small.regular.secondary,
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('EmailCodeField'),
                  state: c.emailCode,
                  label: 'label_one_time_password'.l10n,
                  type: TextInputType.number,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hint: 'label_enter_code'.l10n,
                  obscure: c.obscureCode.value,
                  onSuffixPressed: c.obscureCode.toggle,
                  trailing: Center(
                    child: SvgIcon(
                      c.obscureCode.value
                          ? SvgIcons.visibleOff
                          : SvgIcons.visibleOn,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled =
                      c.resendEmailTimeout.value == 0 &&
                      c.authStatus.value.isEmpty;

                  return Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          key: const Key('Resend'),
                          onPressed: enabled ? c.resendEmail : null,
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
                          onPressed:
                              !c.emailCode.isEmpty.value &&
                                  c.authStatus.value.isEmpty
                              ? c.emailCode.submit
                              : null,
                          title: 'btn_sign_in'.l10n,
                        ),
                      ),
                    ],
                  );
                }),
              ];
              break;

            case LoginViewStage.signIn:
              header = ModalPopupHeader(
                text: 'label_sign_in'.l10n,
                onBack: c.returnTo == null
                    ? null
                    : () => c.stage.value = c.returnTo!,
              );

              children = [
                SignButton(
                  key: const Key('PasswordButton'),
                  title: 'btn_password'.l10n,
                  onPressed: () =>
                      c.stage.value = LoginViewStage.signInWithPassword,
                  icon: const SvgIcon(SvgIcons.password),
                  padding: const EdgeInsets.only(left: 1),
                ),
                const SizedBox(height: 16),
                SignButton(
                  key: const Key('EmailButton'),
                  title: 'btn_email'.l10n,
                  subtitle: 'label_one_time_password'.l10n,
                  onPressed: () =>
                      c.stage.value = LoginViewStage.signInWithEmail,
                  icon: const SvgIcon(SvgIcons.email),
                ),
                const SizedBox(height: 16),
              ];
              break;

            case LoginViewStage.signUpOrSignIn:
              header = ModalPopupHeader(text: 'label_sign_in'.l10n);

              children = [
                Obx(() {
                  return SignButton(
                    key: const Key('StartButton'),
                    icon: const SvgIcon(SvgIcons.guest),
                    padding: const EdgeInsets.only(left: 4),
                    onPressed: c.authStatus.value.isEmpty ? c.register : () {},
                    title: 'btn_guest'.l10n,
                  );
                }),
                const SizedBox(height: 15),
                SignButton(
                  key: const Key('RegisterButton'),
                  icon: const SvgIcon(SvgIcons.register),
                  padding: const EdgeInsets.only(left: 3),
                  onPressed: () {
                    c.returnTo = c.stage.value;
                    c.stage.value = LoginViewStage.signUp;
                  },
                  title: 'btn_sign_up'.l10n,
                ),
                const SizedBox(height: 15),
                SignButton(
                  key: const Key('SignInButton'),
                  icon: const SvgIcon(SvgIcons.enter),
                  padding: const EdgeInsets.only(left: 4),
                  onPressed: () {
                    c.returnTo = c.stage.value;
                    c.stage.value = LoginViewStage.signIn;
                  },
                  title: 'btn_sign_in'.l10n,
                ),
                const SizedBox(height: 15),
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            fadeInCurve: Curves.easeOut,
            fadeOutCurve: Curves.easeOut,
            sizeCurve: Curves.easeOut,
            child: Scrollbar(
              key: Key(c.stage.value.name.capitalized),
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
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  /// Builds the legal disclaimer information.
  Widget _terms(BuildContext context) {
    final style = Theme.of(context).style;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'alert_by_proceeding_you_accept_terms1'.l10n,
            style: style.fonts.small.regular.secondary,
          ),
          TextSpan(
            text: 'alert_by_proceeding_you_accept_terms2'.l10n,
            style: style.fonts.small.regular.primary,
            recognizer: TapGestureRecognizer()
              ..onTap = () => TermsOfUseView.show(context),
          ),
          TextSpan(
            text: 'alert_by_proceeding_you_accept_terms3'.l10n,
            style: style.fonts.small.regular.secondary,
          ),
        ],
      ),
    );
  }
}
