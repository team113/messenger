// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:async';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/account.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/cupertino_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/page/user/controller.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/page/login/qr_code/view.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/page/login/widget/sign_button.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/phone_field.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/platform_utils.dart';

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';

/// ...
///
/// Intended to be displayed with the [show] method.
class AccountsView extends StatelessWidget {
  const AccountsView({
    super.key,
    this.initial = AccountsViewStage.accounts,
  });

  final AccountsViewStage initial;

  /// Displays an [AccountsView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    AccountsViewStage initial = AccountsViewStage.accounts,
  }) {
    return ModalPopup.show(
      context: context,
      background: Theme.of(context).style.colors.background,
      child: AccountsView(initial: initial),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('AccountsView'),
      init: AccountsController(Get.find(), Get.find(), Get.find()),
      builder: (AccountsController c) {
        return Obx(() {
          Widget Function(Widget, List<Widget>) builder = (header, children) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                const SizedBox(height: 13),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      ...children,
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          };

          final Widget header;
          List<Widget> children;

          switch (c.stage.value) {
            case AccountsViewStage.signInWithPassword:
              header = ModalPopupHeader(
                text: 'label_sign_in_with_password'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.signIn,
              );

              children = [
                const SizedBox(height: 12),
                ReactiveTextField(
                  key: const Key('UsernameField'),
                  state: c.login,
                  label: 'label_sign_in_input'.l10n,
                ),
                const SizedBox(height: 16),
                ReactiveTextField(
                  key: const ValueKey('PasswordField'),
                  state: c.password,
                  label: 'label_password'.l10n,
                  obscure: c.obscurePassword.value,
                  onSuffixPressed: c.obscurePassword.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgIcon(
                    c.obscurePassword.value
                        ? SvgIcons.visibleOff
                        : SvgIcons.visibleOn,
                  ),
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled =
                      !c.login.isEmpty.value && !c.password.isEmpty.value;

                  return PrimaryButton(
                    key: const Key('LoginButton'),
                    title: 'btn_sign_in'.l10n,
                    onPressed: enabled ? c.password.submit : null,
                  );
                }),
              ];

              children = children
                  .map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: Center(child: e),
                    ),
                  )
                  .toList();
              break;

            case AccountsViewStage.signInWithQrScan:
            case AccountsViewStage.signInWithQrShow:
              builder = (_, __) {
                return QrCodeView(
                  onBack: () => c.stage.value = AccountsViewStage.signIn,
                );
              };

              header = const SizedBox();
              children = [];
              break;

            case AccountsViewStage.signIn:
              header = ModalPopupHeader(
                text: 'label_sign_in'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.add,
              );

              children = [
                SignButton(
                  title: 'btn_password'.l10n,
                  onPressed: () =>
                      c.stage.value = AccountsViewStage.signInWithPassword,
                  icon: const SvgIcon(SvgIcons.password),
                  padding: const EdgeInsets.only(left: 1),
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  title: 'btn_email'.l10n,
                  icon: const SvgIcon(SvgIcons.email),
                  onPressed: () =>
                      c.stage.value = AccountsViewStage.signInWithEmail,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  onPressed: () =>
                      c.stage.value = AccountsViewStage.signInWithPhone,
                  title: 'btn_phone_number'.l10n,
                  icon: const SvgIcon(SvgIcons.phone),
                  padding: const EdgeInsets.only(left: 2),
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  title: 'btn_qr_code'.l10n,
                  onPressed: () => c.stage.value = PlatformUtils.isMobile
                      ? AccountsViewStage.signInWithQrShow
                      : AccountsViewStage.signInWithQrScan,
                  icon: const SvgIcon(SvgIcons.qrCode),
                  padding: const EdgeInsets.only(left: 1),
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  title: 'Google',
                  icon: const SvgIcon(SvgIcons.google),
                  padding: const EdgeInsets.only(left: 1),
                  onPressed: c.continueWithGoogle,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  title: 'Apple',
                  icon: const SvgIcon(SvgIcons.apple),
                  padding: const EdgeInsets.only(left: 1.5, bottom: 1),
                  onPressed: c.continueWithApple,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  title: 'GitHub',
                  icon: const SvgIcon(SvgIcons.github),
                  onPressed: c.continueWithGitHub,
                ),
                const SizedBox(height: 25 / 2),
              ];

              children = children
                  .map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: Center(child: e),
                    ),
                  )
                  .toList();
              break;

            case AccountsViewStage.oauth:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = c.fallbackStage,
              );

              final (String, SvgData?) provider = switch (c.oAuthProvider) {
                OAuthProvider.apple => ('Apple', SvgIcons.appleBig),
                OAuthProvider.google => ('Google', SvgIcons.googleBig),
                OAuthProvider.github => ('GitHub', SvgIcons.githubBig),
                _ => ('', null),
              };

              children = [
                const SizedBox(height: 12),
                if (provider.$2 != null) SvgIcon(provider.$2!),
                const SizedBox(height: 25 + 5),
                Center(
                  child: Text(
                    'label_waiting_response_from'
                        .l10nfmt({'from': provider.$1}),
                    style: style.fonts.medium.regular.onBackground,
                    textAlign: TextAlign.center,
                  ),
                ),
              ];

              children = children
                  .map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: Center(child: e),
                    ),
                  )
                  .toList();
              break;

            case AccountsViewStage.signInWithPhone:
              header = ModalPopupHeader(
                text: 'label_sign_in'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.signIn,
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
                      onPressed: enabled ? c.phone.submit : null,
                      color: style.colors.primary,
                      maxWidth: double.infinity,
                      child: Text(
                        'btn_proceed'.l10n,
                        style: style.fonts.medium.regular.onBackground.copyWith(
                          color: enabled
                              ? style.colors.onPrimary
                              : style.fonts.medium.regular.onBackground.color,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 25 / 2),
              ];

              children = children
                  .map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: Center(child: e),
                    ),
                  )
                  .toList();
              break;

            case AccountsViewStage.signInWithPhoneCode:
              header = ModalPopupHeader(
                text: 'label_sign_in'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.signIn,
              );
              children = [
                Text.rich(
                  'label_sign_up_code_phone_sent'.l10nfmt({
                    'text': c.phone.phone?.international,
                  }).parseLinks([], style.fonts.medium.regular.primary),
                  style: style.fonts.medium.regular.onBackground,
                ),
                const SizedBox(height: 16),
                Text(
                  'label_did_not_receive_code'.l10n,
                  style: style.fonts.medium.regular.onBackground,
                ),
                WidgetButton(
                  onPressed: () {},
                  child: Text(
                    'btn_resend_code'.l10n,
                    style: style.fonts.medium.regular.primary,
                  ),
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('EmailCodeField'),
                  state: c.phoneCode,
                  label: 'label_confirmation_code'.l10n,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled = !c.phoneCode.isEmpty.value;

                  return PrimaryButton(
                    key: const Key('Proceed'),
                    title: 'btn_send'.l10n,
                    onPressed: enabled ? c.phoneCode.submit : null,
                  );
                }),
              ];

              children = children
                  .map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: Center(child: e),
                    ),
                  )
                  .toList();
              break;

            case AccountsViewStage.signUpWithPhoneCode:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.add,
              );
              children = [
                const SizedBox(height: 50 - 12 - 13),
              ];
              break;

            case AccountsViewStage.signUpWithEmailCode:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.add,
              );
              children = [
                Text.rich(
                  'label_sign_up_code_email_sent'
                      .l10nfmt({'text': c.email.text}).parseLinks(
                    [],
                    style.fonts.medium.regular.primary,
                  ),
                  style: style.fonts.medium.regular.onBackground,
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'label_did_not_receive_code'.l10n,
                    style: style.fonts.medium.regular.onBackground,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: WidgetButton(
                    onPressed: () {},
                    child: Text(
                      'btn_resend_code'.l10n,
                      style: style.fonts.medium.regular.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('EmailCodeField'),
                  state: c.emailCode,
                  label: 'label_confirmation_code'.l10n,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled = !c.emailCode.isEmpty.value;
                  return PrimaryButton(
                    key: const Key('Proceed'),
                    title: 'btn_send'.l10n,
                    onPressed: enabled ? c.emailCode.submit : null,
                  );
                }),
              ];

              children = children
                  .map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: Center(child: e),
                    ),
                  )
                  .toList();
              break;

            case AccountsViewStage.signInWithEmailCode:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.add,
              );
              children = [
                const SizedBox(height: 50 - 12 - 13),
              ];
              break;

            case AccountsViewStage.signInWithEmail:
              header = ModalPopupHeader(
                text: 'label_sign_in'.l10n,
                onBack: () {
                  c.stage.value = AccountsViewStage.signIn;
                  c.email.unsubmit();
                },
              );
              children = [
                ReactiveTextField(
                  state: c.email,
                  label: 'label_email'.l10n,
                  hint: 'example@domain.com',
                  style: style.fonts.normal.regular.onBackground,
                  treatErrorAsStatus: false,
                ),
                const SizedBox(height: 25),
                Center(
                  child: Obx(() {
                    final bool enabled = !c.email.isEmpty.value;

                    return OutlinedRoundedButton(
                      onPressed: enabled ? c.email.submit : null,
                      color: style.colors.primary,
                      maxWidth: double.infinity,
                      child: Text(
                        'btn_proceed'.l10n,
                        style: style.fonts.medium.regular.onBackground.copyWith(
                          color: enabled
                              ? style.colors.onPrimary
                              : style.fonts.medium.regular.onBackground.color,
                        ),
                      ),
                    );
                  }),
                ),
              ];

              children = children
                  .map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: Center(child: e),
                    ),
                  )
                  .toList();
              break;

            case AccountsViewStage.oauthNoUser:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.signUp,
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
                  style: style.fonts.medium.regular.onBackground,
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  title: 'btn_create'.l10n,
                  onPressed: () =>
                      c.registerWithCredentials(c.credential!, true),
                ),
              ];

              children = children
                  .map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: Center(child: e),
                    ),
                  )
                  .toList();
              break;

            case AccountsViewStage.oauthOccupied:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.signUp,
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
                  style: style.fonts.medium.regular.onBackground,
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
                        style: style.fonts.small.regular.onBackground.copyWith(
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

              children = children
                  .map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: Center(child: e),
                    ),
                  )
                  .toList();
              break;

            case AccountsViewStage.signUpWithEmail:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () {
                  c.stage.value = AccountsViewStage.signUp;
                  c.email.unsubmit();
                },
              );
              children = [
                ReactiveTextField(
                  state: c.email,
                  label: 'label_email'.l10n,
                  hint: 'example@domain.com',
                  style: style.fonts.normal.regular.onBackground,
                  treatErrorAsStatus: false,
                ),
                const SizedBox(height: 25),
                Center(
                  child: Obx(() {
                    final bool enabled = !c.email.isEmpty.value;

                    return OutlinedRoundedButton(
                      onPressed: enabled ? c.email.submit : null,
                      color: style.colors.primary,
                      maxWidth: double.infinity,
                      child: Text(
                        'btn_proceed'.l10n,
                        style: style.fonts.medium.regular.onBackground.copyWith(
                          color: enabled
                              ? style.colors.onPrimary
                              : style.fonts.medium.regular.onBackground.color,
                        ),
                      ),
                    );
                  }),
                ),
              ];

              children = children
                  .map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: Center(child: e),
                    ),
                  )
                  .toList();
              break;

            case AccountsViewStage.signUpWithPhone:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.signUp,
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
                      onPressed: enabled ? c.phone.submit : null,
                      color: style.colors.primary,
                      maxWidth: double.infinity,
                      child: Text(
                        'btn_proceed'.l10n,
                        style: style.fonts.medium.regular.onBackground.copyWith(
                          color: enabled
                              ? style.colors.onPrimary
                              : style.fonts.medium.regular.onBackground.color,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 25 / 2),
              ];

              children = children
                  .map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: Center(child: e),
                    ),
                  )
                  .toList();
              break;

            case AccountsViewStage.signUp:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.add,
              );
              children = [
                SignButton(
                  title: 'btn_email'.l10n,
                  icon: const SvgIcon(SvgIcons.email),
                  onPressed: () =>
                      c.stage.value = AccountsViewStage.signUpWithEmail,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  title: 'btn_phone_number'.l10n,
                  icon: const SvgIcon(SvgIcons.phone),
                  padding: const EdgeInsets.only(left: 2),
                  onPressed: () =>
                      c.stage.value = AccountsViewStage.signUpWithPhone,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  title: 'Google'.l10n,
                  icon: const SvgIcon(SvgIcons.google),
                  padding: const EdgeInsets.only(left: 1),
                  onPressed: c.continueWithGoogle,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  title: 'Apple'.l10n,
                  icon: const SvgIcon(SvgIcons.apple),
                  padding: const EdgeInsets.only(left: 1.5, bottom: 1),
                  onPressed: c.continueWithApple,
                ),
                const SizedBox(height: 25 / 2),
                SignButton(
                  title: 'GitHub'.l10n,
                  icon: const SvgIcon(SvgIcons.github),
                  onPressed: c.continueWithGitHub,
                ),
                const SizedBox(height: 25 / 2),
                Center(
                  child: StyledCupertinoButton(
                    label: 'btn_terms_and_conditions'.l10n,
                    onPressed: () {},
                  ),
                ),
              ];

              children = children
                  .map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: Center(child: e),
                    ),
                  )
                  .toList();
              break;

            case AccountsViewStage.add:
              header = ModalPopupHeader(
                text: 'Add account'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.accounts,
              );

              children = [
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Center(
                    child: OutlinedRoundedButton(
                      key: const Key('SignUpButton'),
                      maxWidth: 290,
                      height: 46,
                      leading: Transform.translate(
                        offset: const Offset(3, 0),
                        child: const SvgIcon(SvgIcons.register),
                      ),
                      // onPressed: () {

                      // },
                      onPressed: () => c.stage.value = AccountsViewStage.signUp,
                      child: Text('btn_sign_up'.l10n),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Center(
                    child: OutlinedRoundedButton(
                      key: const Key('SignInButton'),
                      maxWidth: 290,
                      height: 46,
                      leading: Transform.translate(
                        offset: const Offset(4, 0),
                        child: const SvgIcon(SvgIcons.enter),
                      ),
                      onPressed: () => c.stage.value = AccountsViewStage.signIn,
                      child: Text('btn_sign_in'.l10n),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Center(
                    child: OutlinedRoundedButton(
                      key: const Key('StartButton'),
                      maxWidth: 290,
                      height: 46,
                      leading: Transform.translate(
                        offset: const Offset(4, 0),
                        child: const SvgIcon(SvgIcons.guest),
                      ),
                      onPressed: () {
                        router.accounts.value++;
                        Navigator.of(context).pop();
                        c.switchTo(null);
                      },
                      child: Text('btn_guest'.l10n),
                    ),
                  ),
                ),
              ];
              break;

            case AccountsViewStage.accounts:
              header = ModalPopupHeader(text: 'Your accounts'.l10n);

              final List<Widget> tiles = [];

              if (c.status.value.isLoading) {
                tiles.add(const Center(child: CircularProgressIndicator()));
              } else {
                for (var e in c.accounts) {
                  tiles.add(
                    Padding(
                      padding: ModalPopup.padding(context),
                      child: ContactTile(
                        myUser: e.myUser,
                        user: e.user,
                        onTap: () {
                          Navigator.of(context).pop();
                          if (c.myUser.value?.id != e.myUser.id) {
                            c.switchTo(e.account);
                          }
                        },
                        trailing: [
                          AnimatedButton(
                            decorator: (child) => Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
                              child: child,
                            ),
                            onPressed: () async {
                              final result = await MessagePopup.alert(
                                'btn_logout'.l10n,
                                description: [
                                  TextSpan(
                                    style: style.fonts.medium.regular.secondary,
                                    children: [
                                      TextSpan(
                                        text:
                                            'alert_are_you_sure_want_to_log_out1'
                                                .l10n,
                                      ),
                                      TextSpan(
                                        style: style
                                            .fonts.medium.regular.onBackground,
                                        text: e.myUser.name?.val ??
                                            e.myUser.num.toString(),
                                      ),
                                      TextSpan(
                                        text:
                                            'alert_are_you_sure_want_to_log_out2'
                                                .l10n,
                                      ),
                                      if (!e.myUser.hasPassword) ...[
                                        const TextSpan(text: '\n\n'),
                                        TextSpan(
                                          text:
                                              'Пароль не задан. Доступ к аккаунту может быть утерян безвозвратно.'
                                                  .l10n,
                                        ),
                                      ],
                                      if (e
                                          .myUser.emails.confirmed.isEmpty) ...[
                                        const TextSpan(text: '\n\n'),
                                        TextSpan(
                                          text:
                                              'E-mail или номер телефона не задан. Восстановление доступа к аккаунту невозможно.'
                                                  .l10n,
                                        ),
                                      ],
                                    ],
                                  )
                                ],
                              );

                              if (result == true) {
                                c.delete(e.account);
                              }
                            },
                            child: c.myUser.value?.id == e.myUser.id
                                ? const SvgIcon(SvgIcons.logoutWhite)
                                : const SvgIcon(SvgIcons.logout),
                          ),
                        ],
                        selected: c.myUser.value?.id == e.myUser.id,
                        subtitle: [
                          const SizedBox(height: 5),
                          if (c.myUser.value?.id == e.myUser.id)
                            Text(
                              'Active',
                              style: style.fonts.small.regular.onPrimary,
                            )
                          else
                            Obx(() {
                              return Text(
                                '${e.user.user.value.getStatus()}',
                                style: style.fonts.small.regular.secondary,
                              );
                            })
                        ],
                      ),
                    ),
                  );
                }
              }

              children = [
                ...tiles,
                const SizedBox(height: 10),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: PrimaryButton(
                    onPressed: () => c.stage.value = AccountsViewStage.add,
                    title: 'Add account'.l10n,
                  ),
                ),
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: Key('${c.stage.value.name.capitalizeFirst}Stage'),
              child: builder(header, children),
            ),
          );
        });
      },
    );
  }
}
