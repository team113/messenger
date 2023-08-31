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
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/auth/widget/cupertino_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/phone_field.dart';
import 'package:messenger/util/platform_utils.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import 'controller.dart';
import 'qr_code/view.dart';
import 'widget/primary_button.dart';
import 'widget/sign_button.dart';

/// View for logging in or recovering access on.
///
/// Intended to be displayed with the [show] method.
class LoginView extends StatelessWidget {
  const LoginView({
    super.key,
    this.stage = LoginViewStage.signUp,
    this.onAuth,
  });

  final LoginViewStage stage;
  final void Function()? onAuth;

  /// Displays a [LoginView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    LoginViewStage stage = LoginViewStage.signUp,
    void Function()? onAuth,
  }) {
    return ModalPopup.show(
      context: context,
      child: LoginView(stage: stage, onAuth: onAuth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('LoginView'),
      init: LoginController(Get.find(), stage: stage, onAuth: onAuth),
      builder: (LoginController c) {
        return Obx(() {
          Widget Function(Widget, List<Widget>) builder = (header, children) {
            return ListView(
              controller: c.scrollController,
              shrinkWrap: true,
              children: [
                header,
                const SizedBox(height: 12),
                ...children.map(
                  (e) => Padding(
                    padding: ModalPopup.padding(context),
                    child: e,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          };

          final Widget header;
          final List<Widget> children;

          switch (c.stage.value) {
            case LoginViewStage.choice:
              // header = ModalPopupHeader(text: 'Записаться на интервью'.l10n);
              header = ModalPopupHeader(text: 'label_sign_in'.l10n);

              children = [
                SignButton(
                  text: 'btn_sign_up'.l10n,
                  asset: 'register3',
                  assetWidth: 23,
                  assetHeight: 23,
                  onPressed: () {
                    c.stage.value = LoginViewStage.signUp;
                    c.backStage = LoginViewStage.choice;
                  },
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  text: 'btn_sign_in'.l10n,
                  asset: 'enter1',
                  assetWidth: 19.42,
                  assetHeight: 24,
                  onPressed: () {
                    c.stage.value = LoginViewStage.signIn;
                    c.backStage = LoginViewStage.choice;
                  },
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  text: 'btn_one_time_account'.l10n,
                  dense: true,
                  asset: 'one_time19',
                  assetWidth: 19.88,
                  assetHeight: 26,
                  onPressed: () {
                    router.noIntroduction = false;
                    c.oneTime();
                  },
                ),
                const SizedBox(height: 25 / 2),
              ];
              break;

            case LoginViewStage.oauthNoUser:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signUp,
                text: 'label_sign_up'.l10n,
              );

              final String provider = switch (c.oAuthProvider) {
                OAuthProvider.apple => 'Apple',
                OAuthProvider.google => 'Google',
                OAuthProvider.github => 'GitHub',
                _ => '',
              };

              children = [
                Text(
                  'label_sign_in_oauth_already_occupied'.l10nfmt({
                    'provider': provider,
                    'text': c.credential?.user?.email ??
                        c.credential?.user?.phoneNumber,
                  }),
                  style: style.fonts.titleLarge,
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  title: 'btn_create'.l10n,
                  onPressed: () =>
                      c.registerWithCredentials(c.credential!, true),
                ),
              ];
              break;

            case LoginViewStage.oauthOccupied:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signUp,
                text: 'label_sign_up'.l10n,
              );

              final String provider = switch (c.oAuthProvider) {
                OAuthProvider.apple => 'Apple',
                OAuthProvider.google => 'Google',
                OAuthProvider.github => 'GitHub',
                _ => '',
              };

              children = [
                Text(
                  'label_sign_up_oauth_already_occupied'.l10nfmt({
                    'provider': provider,
                    'text': c.credential?.user?.email ??
                        c.credential?.user?.phoneNumber,
                  }),
                  style: style.fonts.titleLarge,
                ),
                const SizedBox(height: 25),
                ContactTile(
                  title: 'Name', // name ?? login ?? email/phone used to login
                  myUser: MyUser(
                    id: const UserId('123412'),
                    num: UserNum('1234123412341234'),
                    emails: MyUserEmails(confirmed: []),
                    phones: MyUserPhones(confirmed: []),
                    presenceIndex: 0,
                    online: false,
                  ),
                  darken: 0.03,
                  subtitle: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        'Gapopa ID: 1234 1234 1234 1234',
                        style: style.fonts.labelMedium.copyWith(
                          color: style.colors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('SignIn'),
                  title: 'btn_sign_in'.l10n,
                  onPressed: () {},
                ),
              ];
              break;

            case LoginViewStage.oauth:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = c.fallbackStage,
              );

              final (String, String) provider = switch (c.oAuthProvider) {
                OAuthProvider.apple => ('Apple', 'apple'),
                OAuthProvider.google => ('Google', 'google_logo'),
                OAuthProvider.github => ('GitHub', 'github'),
                _ => ('', ''),
              };

              children = [
                const SizedBox(height: 12),
                SvgImage.asset('assets/icons/${provider.$2}.svg', height: 100),
                const SizedBox(height: 25 + 5),
                Center(
                  child: Text(
                    'label_waiting_response_from'
                        .l10nfmt({'from': provider.$1}),
                    style: style.fonts.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ];
              break;

            case LoginViewStage.noPassword:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signIn,
                text: 'Sign in without password'.l10n,
              );

              children = [
                // const SizedBox(height: 12),
                Text(
                  'label_recover_account_description'.l10n,
                  style: style.fonts.titleLarge.copyWith(
                    color: style.colors.secondary,
                  ),
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('RecoveryField'),
                  state: c.login,
                  label: 'E-mail or phone number'.l10n,
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('Proceed'),
                  title: 'btn_proceed'.l10n,
                  onPressed:
                      c.login.isEmpty.value ? null : c.signInWithoutPassword,
                ),
                // const SizedBox(height: 16),
              ];
              break;

            case LoginViewStage.noPasswordCode:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signInWithCode,
                text: 'label_sign_in_with_code'.l10n,
              );

              children = [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'label_sign_in_code_sent1'.l10n,
                        style: style.fonts.titleLarge.copyWith(
                          color: style.colors.secondary,
                        ),
                      ),
                      TextSpan(
                        text: c.login.text,
                        style: style.fonts.titleLarge.copyWith(
                          color: style.colors.onBackground,
                        ),
                      ),
                      TextSpan(
                        text: 'label_sign_in_code_sent2'.l10n,
                        style: style.fonts.titleLarge.copyWith(
                          color: style.colors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('RecoveryCodeField'),
                  state: c.recoveryCode,
                  label: 'label_confirmation_code'.l10n,
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
                // const SizedBox(height: 16),
              ];
              break;

            case LoginViewStage.recovery:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signIn,
                text: 'label_recover_account'.l10n,
              );

              children = [
                const SizedBox(height: 12),
                Text(
                  'label_recover_account_description'.l10n,
                  style: style.fonts.titleLarge.copyWith(
                    color: style.colors.secondary,
                  ),
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('RecoveryField'),
                  state: c.recovery,
                  label: 'E-mail or phone number'.l10n,
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('Proceed'),
                  title: 'btn_proceed'.l10n,
                  onPressed:
                      c.recovery.isEmpty.value ? null : c.recovery.submit,
                ),
                // const SizedBox(height: 16),
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
                  style: style.fonts.titleLarge.copyWith(
                    color: style.colors.secondary,
                  ),
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
                // const SizedBox(height: 16),
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
                  style: style.fonts.titleLarge.copyWith(
                    color: style.colors.secondary,
                  ),
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('PasswordField'),
                  state: c.newPassword,
                  label: 'label_new_password'.l10n,
                  obscure: c.obscureNewPassword.value,
                  onSuffixPressed: c.obscureNewPassword.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgImage.asset(
                    'assets/icons/visible_${c.obscureNewPassword.value ? 'off' : 'on'}.svg',
                    width: 17.07,
                  ),
                ),
                const SizedBox(height: 16),
                ReactiveTextField(
                  key: const Key('RepeatPasswordField'),
                  state: c.repeatPassword,
                  label: 'label_repeat_password'.l10n,
                  obscure: c.obscureRepeatPassword.value,
                  onSuffixPressed: c.obscureRepeatPassword.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgImage.asset(
                    'assets/icons/visible_${c.obscureRepeatPassword.value ? 'off' : 'on'}.svg',
                    width: 17.07,
                  ),
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('Proceed'),
                  title: 'btn_proceed'.l10n,
                  onPressed: c.newPassword.isEmpty.value ||
                          c.repeatPassword.isEmpty.value
                      ? null
                      : c.resetUserPassword,
                ),
                // const SizedBox(height: 16),
              ];
              break;

            case LoginViewStage.signUpWithPhoneOccupied:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signUpWithPhone,
                text: 'label_sign_up'.l10n,
              );

              children = [
                Text.rich(
                  'label_sign_up_phone_already_occupied'
                      .l10nfmt({'text': c.email.text}).parseLinks([], context),
                  style: style.fonts.titleLarge,
                ),
                const SizedBox(height: 25),
                ContactTile(
                  title: 'Name', // name ?? login ?? email/phone used to login
                  myUser: MyUser(
                    id: const UserId('123412'),
                    num: UserNum('1234123412341234'),
                    emails: MyUserEmails(confirmed: []),
                    phones: MyUserPhones(confirmed: []),
                    presenceIndex: 0,
                    online: false,
                  ),
                  darken: 0.03,
                  subtitle: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        'Gapopa ID: 1234 1234 1234 1234',
                        style: style.fonts.labelMedium.copyWith(
                          color: style.colors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('SignIn'),
                  title: 'btn_sign_in'.l10n,
                  onPressed: () {},
                ),
              ];
              break;

            case LoginViewStage.signUpWithPhoneCode:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signUpWithPhone,
                text: 'label_sign_up'.l10n,
              );

              children = [
                Text.rich(
                  'label_sign_up_code_phone_sent'.l10nfmt({
                    'text': c.phone.phone?.international,
                  }).parseLinks([], context),
                  style: style.fonts.titleLarge,
                ),
                const SizedBox(height: 16),
                Obx(() {
                  return Text(
                    c.resendPhoneTimeout.value == 0
                        ? 'label_didnt_receive_code'.l10n
                        : 'label_code_sent_again'.l10n,
                    style: style.fonts.titleLarge,
                  );
                }),
                Obx(() {
                  final bool enabled = c.resendPhoneTimeout.value == 0;

                  return WidgetButton(
                    onPressed: enabled ? c.resendPhone : null,
                    child: Text(
                      enabled
                          ? 'btn_resend_code'.l10n
                          : 'label_wait_seconds'
                              .l10nfmt({'for': c.resendPhoneTimeout.value}),
                      style: style.fonts.titleLarge.copyWith(
                        color: enabled ? style.colors.primary : null,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('EmailCodeField'),
                  state: c.phoneCode,
                  label: 'label_confirmation_code'.l10n,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled =
                      !c.phoneCode.isEmpty.value && c.codeTimeout.value == 0;

                  return PrimaryButton(
                    key: const Key('Proceed'),
                    title: c.codeTimeout.value == 0
                        ? 'btn_send'.l10n
                        : 'label_wait_seconds'
                            .l10nfmt({'for': c.codeTimeout.value}),
                    dense: c.codeTimeout.value != 0,
                    onPressed: enabled ? c.phoneCode.submit : null,
                  );
                }),
              ];
              break;

            case LoginViewStage.signUpWithPhone:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = LoginViewStage.signUp,
              );

              children = [
                ReactivePhoneField(
                  state: c.phone,
                  label: 'label_phone_number'.l10n,
                ),
                const SizedBox(height: 25),
                Center(
                  child: Obx(() {
                    final bool enabled = !c.phone.isEmpty.value;

                    return OutlinedRoundedButton(
                      title: Text(
                        'btn_proceed'.l10n,
                        style: style.fonts.titleLarge.copyWith(
                          color: enabled
                              ? style.colors.onPrimary
                              : style.fonts.titleLarge.color,
                        ),
                      ),
                      onPressed: enabled ? c.phone.submit : null,
                      color: style.colors.primary,
                      maxWidth: double.infinity,
                    );
                  }),
                ),
                const SizedBox(height: 25 / 2),
              ];
              break;

            case LoginViewStage.signUpWithEmailOccupied:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signUpWithEmail,
                text: 'label_sign_up'.l10n,
              );

              children = [
                Text.rich(
                  'label_sign_up_email_already_occupied'
                      .l10nfmt({'text': c.email.text}).parseLinks([], context),
                  style: style.fonts.titleLarge,
                ),
                const SizedBox(height: 25),
                ContactTile(
                  title: 'Name', // name ?? login ?? email/phone used to login
                  myUser: MyUser(
                    id: const UserId('123412'),
                    num: UserNum('1234123412341234'),
                    emails: MyUserEmails(confirmed: []),
                    phones: MyUserPhones(confirmed: []),
                    presenceIndex: 0,
                    online: false,
                  ),
                  darken: 0.03,
                  subtitle: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        'Gapopa ID: 1234 1234 1234 1234',
                        style: style.fonts.labelMedium.copyWith(
                          color: style.colors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('SignIn'),
                  title: 'btn_sign_in'.l10n,
                  onPressed: () {},
                ),
              ];
              break;

            case LoginViewStage.signUpWithEmailCode:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signUpWithEmail,
                text: 'label_sign_up'.l10n,
              );

              children = [
                Text.rich(
                  'label_sign_up_code_email_sent'
                      .l10nfmt({'text': c.email.text}).parseLinks([], context),
                  style: style.fonts.titleLarge,
                ),
                const SizedBox(height: 16),
                Obx(() {
                  return Text(
                    c.resendEmailTimeout.value == 0
                        ? 'label_didnt_receive_code'.l10n
                        : 'label_code_sent_again'.l10n,
                    style: style.fonts.titleLarge,
                  );
                }),
                Obx(() {
                  final bool enabled = c.resendEmailTimeout.value == 0;

                  return WidgetButton(
                    onPressed: enabled ? c.resendEmail : null,
                    child: Text(
                      enabled
                          ? 'btn_resend_code'.l10n
                          : 'label_wait_seconds'
                              .l10nfmt({'for': c.resendEmailTimeout.value}),
                      style: style.fonts.titleLarge.copyWith(
                        color: enabled ? style.colors.primary : null,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('EmailCodeField'),
                  state: c.emailCode,
                  label: 'label_confirmation_code'.l10n,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled =
                      !c.emailCode.isEmpty.value && c.codeTimeout.value == 0;

                  return PrimaryButton(
                    key: const Key('Proceed'),
                    title: c.codeTimeout.value == 0
                        ? 'btn_send'.l10n
                        : 'label_wait_seconds'
                            .l10nfmt({'for': c.codeTimeout.value}),
                    dense: c.codeTimeout.value != 0,
                    onPressed: enabled ? c.emailCode.submit : null,
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
                  hint: 'example@domain.com',
                  style: style.fonts.bodyMedium,
                  treatErrorAsStatus: false,
                ),
                const SizedBox(height: 25),
                Center(
                  child: Obx(() {
                    final bool enabled = !c.email.isEmpty.value;

                    return OutlinedRoundedButton(
                      title: Text(
                        'btn_proceed'.l10n,
                        style: style.fonts.titleLarge.copyWith(
                          color: enabled
                              ? style.colors.onPrimary
                              : style.fonts.titleLarge.color,
                        ),
                      ),
                      onPressed: enabled ? c.email.submit : null,
                      color: style.colors.primary,
                      maxWidth: double.infinity,
                    );
                  }),
                ),
              ];
              break;

            case LoginViewStage.signUp:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: c.backStage == null
                    ? null
                    : () => c.stage.value = c.backStage!,
              );

              children = [
                SignButton(
                  text: 'btn_email'.l10n,
                  asset: 'email',
                  assetWidth: 21.93,
                  assetHeight: 22.5,
                  onPressed: () =>
                      c.stage.value = LoginViewStage.signUpWithEmail,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  text: 'btn_phone_number'.l10n,
                  asset: 'phone6',
                  assetWidth: 17.61,
                  assetHeight: 25,
                  padding: const EdgeInsets.only(left: 2),
                  onPressed: () =>
                      c.stage.value = LoginViewStage.signUpWithPhone,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  text: 'Google'.l10n,
                  asset: 'google_logo1',
                  assetWidth: 21.56,
                  assetHeight: 22,
                  padding: const EdgeInsets.only(left: 1),
                  onPressed: c.continueWithGoogle,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  text: 'Apple'.l10n,
                  asset: 'apple7',
                  assetWidth: 21.07,
                  assetHeight: 27,
                  padding: const EdgeInsets.only(left: 1.5, bottom: 1),
                  onPressed: c.continueWithApple,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  text: 'GitHub'.l10n,
                  asset: 'github1',
                  assetHeight: 26,
                  assetWidth: 26,
                  onPressed: c.continueWithGitHub,
                ),
                const SizedBox(height: 25 / 2),
                Center(
                  child: StyledCupertinoButton(
                    // color: style.colors.secondary,
                    label: 'btn_terms_and_conditions'.l10n,
                    onPressed: () {},
                  ),
                ),
              ];
              break;

            case LoginViewStage.signInWithQrScan:
            case LoginViewStage.signInWithQrShow:
              builder = (_, __) {
                return QrCodeView(
                  onBack: () => c.stage.value = LoginViewStage.signIn,
                );
              };

              header = const SizedBox();
              children = [];
              break;

            case LoginViewStage.signInWithCode:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signIn,
                text: 'label_sign_in_with_code'.l10n,
              );

              children = [
                Text(
                  'label_one_time_code_sent_description'.l10n,
                  style: style.fonts.titleLarge,
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('RecoveryField'),
                  state: c.login,
                  label: 'label_email_or_phone'.l10n,
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('Proceed'),
                  title: 'btn_proceed'.l10n,
                  onPressed:
                      c.login.isEmpty.value ? null : c.signInWithoutPassword,
                ),
                // const SizedBox(height: 16),
              ];
              break;

            case LoginViewStage.signInWithPhoneOccupied:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signInWithPhone,
                text: 'label_sign_in'.l10n,
              );

              children = [
                Text.rich(
                  'label_sign_in_phone_already_occupied'.l10nfmt({
                    'text': c.phone.phone?.international
                  }).parseLinks([], context),
                  style: style.fonts.titleLarge,
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  title: 'btn_create'.l10n,
                  onPressed: c.registerOccupied,
                ),
              ];
              break;

            case LoginViewStage.signInWithPhoneCode:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signInWithPhone,
                text: 'label_sign_in'.l10n,
              );

              children = [
                Text.rich(
                  'label_sign_up_code_phone_sent'.l10nfmt({
                    'text': c.phone.phone?.international,
                  }).parseLinks([], context),
                  style: style.fonts.titleLarge,
                ),
                const SizedBox(height: 16),
                Obx(() {
                  return Text(
                    c.resendPhoneTimeout.value == 0
                        ? 'label_didnt_receive_code'.l10n
                        : 'label_code_sent_again'.l10n,
                    style: style.fonts.titleLarge,
                  );
                }),
                Obx(() {
                  final bool enabled = c.resendPhoneTimeout.value == 0;

                  return WidgetButton(
                    onPressed: enabled ? c.resendPhone : null,
                    child: Text(
                      enabled
                          ? 'btn_resend_code'.l10n
                          : 'label_wait_seconds'
                              .l10nfmt({'for': c.resendPhoneTimeout.value}),
                      style: style.fonts.titleLarge.copyWith(
                        color: enabled ? style.colors.primary : null,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('EmailCodeField'),
                  state: c.phoneCode,
                  label: 'label_confirmation_code'.l10n,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled =
                      !c.phoneCode.isEmpty.value && c.codeTimeout.value == 0;

                  return PrimaryButton(
                    key: const Key('Proceed'),
                    title: c.codeTimeout.value == 0
                        ? 'btn_send'.l10n
                        : 'label_wait_seconds'
                            .l10nfmt({'for': c.codeTimeout.value}),
                    dense: c.codeTimeout.value != 0,
                    onPressed: enabled ? c.phoneCode.submit : null,
                  );
                }),
              ];
              break;

            case LoginViewStage.signInWithPhone:
              header = ModalPopupHeader(
                text: 'label_sign_in'.l10n,
                onBack: () => c.stage.value = LoginViewStage.signIn,
              );

              children = [
                ReactivePhoneField(
                  state: c.phone,
                  label: 'label_phone_number'.l10n,
                ),
                const SizedBox(height: 25),
                Center(
                  child: Obx(() {
                    final bool enabled = !c.phone.isEmpty.value;

                    return OutlinedRoundedButton(
                      title: Text(
                        'btn_proceed'.l10n,
                        style: style.fonts.titleLarge.copyWith(
                          color: enabled
                              ? style.colors.onPrimary
                              : style.fonts.titleLarge.color,
                        ),
                      ),
                      onPressed: enabled ? c.phone.submit : null,
                      color: style.colors.primary,
                      maxWidth: double.infinity,
                    );
                  }),
                ),
                const SizedBox(height: 25 / 2),
              ];
              break;

            case LoginViewStage.signInWithEmailOccupied:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signInWithEmail,
                text: 'label_sign_in'.l10n,
              );

              children = [
                Text.rich(
                  'label_sign_in_email_already_occupied'
                      .l10nfmt({'text': c.email.text}).parseLinks([], context),
                  style: style.fonts.titleLarge,
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  title: 'btn_create'.l10n,
                  onPressed: c.registerOccupied,
                ),
              ];
              break;

            case LoginViewStage.signInWithEmailCode:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = LoginViewStage.signInWithEmail,
                text: 'label_sign_in'.l10n,
              );

              children = [
                Text.rich(
                  'label_sign_up_code_email_sent'
                      .l10nfmt({'text': c.email.text}).parseLinks([], context),
                  style: style.fonts.titleLarge,
                ),
                const SizedBox(height: 16),
                Obx(() {
                  return Text(
                    c.resendEmailTimeout.value == 0
                        ? 'label_didnt_receive_code'.l10n
                        : 'label_code_sent_again'.l10n,
                    style: style.fonts.titleLarge,
                  );
                }),
                Obx(() {
                  final bool enabled = c.resendEmailTimeout.value == 0;

                  return WidgetButton(
                    onPressed: enabled ? c.resendEmail : null,
                    child: Text(
                      enabled
                          ? 'btn_resend_code'.l10n
                          : 'label_wait_seconds'
                              .l10nfmt({'for': c.resendEmailTimeout.value}),
                      style: style.fonts.titleLarge.copyWith(
                        color: enabled ? style.colors.primary : null,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('EmailCodeField'),
                  state: c.emailCode,
                  label: 'label_confirmation_code'.l10n,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled =
                      !c.emailCode.isEmpty.value && c.codeTimeout.value == 0;

                  return PrimaryButton(
                    key: const Key('Proceed'),
                    title: c.codeTimeout.value == 0
                        ? 'btn_send'.l10n
                        : 'label_wait_seconds'
                            .l10nfmt({'for': c.codeTimeout.value}),
                    dense: c.codeTimeout.value != 0,
                    onPressed: enabled ? c.emailCode.submit : null,
                  );
                }),
              ];
              break;

            case LoginViewStage.signInWithEmail:
              header = ModalPopupHeader(
                text: 'label_sign_in'.l10n,
                onBack: () {
                  c.stage.value = LoginViewStage.signIn;
                  c.email.unsubmit();
                },
              );

              children = [
                ReactiveTextField(
                  state: c.email,
                  label: 'label_email'.l10n,
                  hint: 'example@domain.com',
                  style: style.fonts.bodyMedium,
                  treatErrorAsStatus: false,
                ),
                const SizedBox(height: 25),
                Center(
                  child: Obx(() {
                    final bool enabled = !c.email.isEmpty.value;

                    return OutlinedRoundedButton(
                      title: Text(
                        'btn_proceed'.l10n,
                        style: style.fonts.titleLarge.copyWith(
                          color: enabled
                              ? style.colors.onPrimary
                              : style.fonts.titleLarge.color,
                        ),
                      ),
                      onPressed: enabled ? c.email.submit : null,
                      color: style.colors.primary,
                      maxWidth: double.infinity,
                    );
                  }),
                ),
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
                  label: 'label_sign_in_input'.l10n,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReactiveTextField(
                      key: const ValueKey('PasswordField'),
                      state: c.password,
                      label: 'label_password'.l10n,
                      obscure: c.obscurePassword.value,
                      onSuffixPressed: c.obscurePassword.toggle,
                      treatErrorAsStatus: false,
                      trailing: SvgImage.asset(
                        'assets/icons/visible_${c.obscurePassword.value ? 'off' : 'on'}.svg',
                        width: 17.07,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled = !c.login.isEmpty.value &&
                      !c.password.isEmpty.value &&
                      c.signInTimeout.value == 0;

                  return PrimaryButton(
                    key: const Key('LoginButton'),
                    title: c.signInTimeout.value == 0
                        ? 'btn_sign_in'.l10n
                        : 'label_wait_seconds'
                            .l10nfmt({'for': c.signInTimeout.value}),
                    onPressed: enabled ? c.password.submit : null,
                  );
                }),
              ];
              break;

            case LoginViewStage.signIn:
              header = ModalPopupHeader(
                text: 'label_sign_in'.l10n,
                onBack: c.backStage == null
                    ? null
                    : () => c.stage.value = c.backStage!,
              );

              children = [
                SignButton(
                  text: 'btn_password'.l10n,
                  onPressed: () =>
                      c.stage.value = LoginViewStage.signInWithPassword,
                  asset: 'password2',
                  assetWidth: 19,
                  assetHeight: 21,
                  padding: const EdgeInsets.only(left: 1),
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  text: 'btn_email'.l10n,
                  asset: 'email',
                  assetWidth: 21.93,
                  assetHeight: 22.5,
                  onPressed: () =>
                      c.stage.value = LoginViewStage.signInWithEmail,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  onPressed: () =>
                      c.stage.value = LoginViewStage.signInWithPhone,
                  text: 'btn_phone_number'.l10n,
                  asset: 'phone6',
                  assetWidth: 17.61,
                  assetHeight: 25,
                  padding: const EdgeInsets.only(left: 2),
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  text: 'btn_qr_code'.l10n,
                  onPressed: () => c.stage.value = PlatformUtils.isMobile
                      ? LoginViewStage.signInWithQrShow
                      : LoginViewStage.signInWithQrScan,
                  asset: 'qr_code2',
                  assetWidth: 20,
                  assetHeight: 20,
                  padding: const EdgeInsets.only(left: 1),
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  text: 'Google',
                  asset: 'google_logo1',
                  assetWidth: 21.56,
                  assetHeight: 22,
                  padding: const EdgeInsets.only(left: 1),
                  onPressed: c.continueWithGoogle,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  text: 'Apple',
                  asset: 'apple7',
                  assetWidth: 21.07,
                  assetHeight: 27,
                  padding: const EdgeInsets.only(left: 1.5, bottom: 1),
                  onPressed: c.continueWithApple,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  text: 'GitHub',
                  asset: 'github1',
                  assetHeight: 26,
                  assetWidth: 26,
                  onPressed: c.continueWithGitHub,
                ),
                const SizedBox(height: 25 / 2),
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
              key: Key('${c.stage.value}'),
              controller: c.scrollController,
              child: builder(header, children),
            ),
          );
        });
      },
    );
  }
}
