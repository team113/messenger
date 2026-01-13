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
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/auth/account_is_not_accessible/view.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/page/home/widget/num.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/page/login/terms_of_use/view.dart';
import '/ui/page/login/widget/sign_button.dart';
import '/ui/widget/line_divider.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/animated_pulsing.dart';

/// View of a introduction overlay with sign in and sign up options.
class IntroductionView extends StatelessWidget {
  const IntroductionView({super.key, required this.child});

  /// [Widget] to display under this overlay.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: IntroductionController(Get.find(), Get.find(), Get.find()),
      builder: (IntroductionController c) {
        return Stack(
          children: [
            child,
            Obx(() {
              if (c.opacity.value != 1) {
                return const SizedBox();
              }

              return _overlay(context, c);
            }),
          ],
        );
      },
    );
  }

  /// Builds the overlay with the [_panel] positioned properly.
  Widget _overlay(BuildContext context, IntroductionController c) {
    final style = Theme.of(context).style;

    return Stack(
      key: c.stackKey,
      children: [
        Positioned.fill(
          child: Container(
            color: style.colors.onBackgroundOpacity27,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        if (context.isNarrow)
          Positioned(
            top: context.isNarrow ? null : null,
            bottom: context.isNarrow ? 64 : 4,
            left: 0,
            right: context.isNarrow ? 0 : null,
            child: KeyedSubtree(
              key: c.positionedKey,
              child: _panel(context, c),
            ),
          )
        else
          Positioned.fill(
            top: 0,
            right: 0,
            bottom: 0,
            left: 0,
            child: Center(child: _panel(context, c)),
          ),
      ],
    );
  }

  /// Builds the panel itself.
  Widget _panel(BuildContext context, IntroductionController c) {
    final style = Theme.of(context).style;

    final Widget buttons = FittedBox(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Flex(
          direction: Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: OutlinedRoundedButton(
                key: const Key('GuestButton'),
                maxWidth: 210,
                height: 46,
                onPressed: () async {
                  c.register();
                  c.page.value = IntroductionStage.guestCreated;
                },
                leading: Transform.translate(
                  offset: const Offset(4, 0),
                  child: const SvgIcon(SvgIcons.guest),
                ),
                child: Text('btn_guest'.l10n),
              ),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: OutlinedRoundedButton(
                key: const Key('SignInButton'),
                onPressed: () => c.page.value = IntroductionStage.signIn,
                maxWidth: 210,
                height: 46,
                leading: Transform.translate(
                  offset: const Offset(4, 0),
                  child: const SvgIcon(SvgIcons.enter),
                ),
                child: Text('btn_sign_in'.l10n, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );

    return ConstrainedBox(
      key: c.opacity.value == 1 ? const Key('IntroductionView') : null,
      constraints: BoxConstraints(
        maxWidth: context.isNarrow ? double.infinity : 450,
        minHeight: 0,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        decoration: BoxDecoration(
          borderRadius: style.cardRadius,
          boxShadow: const [
            CustomBoxShadow(
              blurRadius: 8,
              color: Color(0x22000000),
              blurStyle: BlurStyle.outer,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            border: Border.all(
              color: style.colors.background.darken(0.05),
              width: 1,
            ),
            color: style.colors.background,
          ),
          width: double.infinity,
          child: Stack(
            children: [
              Obx(() {
                final Widget? header;
                final List<Widget> children;
                EdgeInsets padding = ModalPopup.padding(context);

                switch (c.page.value) {
                  case null:
                    header = null;
                    children = [
                      const SizedBox(height: 21),
                      Center(
                        child: Text(
                          'Messenger by Tapopa',
                          style: style.fonts.big.regular.onBackground,
                        ),
                      ),
                      const SizedBox(height: 21),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Align(
                          alignment: Alignment.center,
                          child: Obx(() {
                            final Widget child;

                            if (c.chat.value == null && c.fetching.value) {
                              child = ConstrainedBox(
                                key: const Key('Loading'),
                                constraints: const BoxConstraints(
                                  maxWidth: 350,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: style.colors.onPrimary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: AnimatedPulsing(
                                      child: Text(
                                        'label_loading'.l10n,
                                        style: style
                                            .fonts
                                            .big
                                            .regular
                                            .onBackground,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              child = buttons;
                            }

                            return SizedBox(
                              height: 48,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: child,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            WidgetButton(
                              onPressed: () async {
                                await TermsOfUseView.show(router.context!);
                              },
                              child: Text(
                                'label_terms_and_privacy_policy'.l10n,
                                style: style.fonts.smallest.regular.onBackground
                                    .copyWith(color: style.colors.primary),
                              ),
                            ),
                            SizedBox(width: 4),
                            Container(
                              color: style.colors.secondaryLight,
                              width: 1,
                              height: 8,
                            ),
                            SizedBox(width: 4),
                            WidgetButton(
                              onPressed: () {
                                c.previousPage = c.page.value;
                                c.page.value = IntroductionStage.language;
                              },
                              child: Text(
                                'label_language_entry'.l10nfmt({
                                  'code': L10n.chosen.value?.locale.languageCode
                                      .toUpperCase(),
                                  'name': L10n.chosen.value?.name,
                                }),
                                style: style.fonts.smallest.regular.onBackground
                                    .copyWith(color: style.colors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ];
                    break;

                  case IntroductionStage.signIn:
                  case IntroductionStage.signInAs:
                    header = ModalPopupHeader(
                      text: 'label_sign_in'.l10n,
                      onBack: () {
                        c.page.value = null;

                        if (c.signInAs != null) {
                          c.login.clear();
                          c.email.clear();
                          c.page.value = IntroductionStage.signIn;
                          c.signInAs = null;
                        }
                      },
                      close: false,
                    );

                    padding = EdgeInsets.zero;

                    final profiles = c.profiles
                        .where((e) => e.id != c.userId)
                        .toList();

                    children = [
                      const SizedBox(height: 8),
                      if (profiles.isNotEmpty && c.signInAs == null) ...[
                        _profiles(context, c),
                        const SizedBox(height: 24),
                      ] else if (c.signInAs != null) ...[
                        Center(
                          child: Text(
                            '${c.signInAs?.name?.val ?? c.signInAs?.num}',
                            style: style.fonts.small.regular.onBackground,
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                      Padding(
                        padding: ModalPopup.padding(context),
                        child: SignButton(
                          key: const Key('PasswordButton'),
                          title: 'btn_password'.l10n,
                          subtitle: 'label_sign_in_input'.l10n,
                          onPressed: () => c.page.value =
                              IntroductionStage.signInWithPassword,
                          icon: const SvgIcon(SvgIcons.password),
                          padding: const EdgeInsets.only(left: 1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: ModalPopup.padding(context),
                        child: SignButton(
                          key: const Key('EmailButton'),
                          title: 'label_one_time_password'.l10n,
                          subtitle: 'label_email'.l10n,
                          onPressed: () =>
                              c.page.value = IntroductionStage.signInWithEmail,
                          icon: const SvgIcon(SvgIcons.email),
                        ),
                      ),
                      if (c.signInAs == null) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: ModalPopup.padding(context),
                          child: SignButton(
                            key: const Key('CreateAccountButton'),
                            title: 'btn_create_account'.l10n,
                            subtitle: 'label_sign_up_hint'.l10n,
                            onPressed: () => c.page.value =
                                IntroductionStage.accountCreating,
                            icon: const SvgIcon(SvgIcons.newAccount),
                            padding: const EdgeInsets.only(left: 1),
                          ),
                        ),
                      ],
                      const SizedBox(height: 26),
                    ];
                    break;

                  case IntroductionStage.signInWithPassword:
                    header = ModalPopupHeader(
                      text: 'label_sign_in_with_password'.l10n,
                      onBack: () => c.page.value = IntroductionStage.signIn,
                      close: false,
                    );
                    children = [
                      const SizedBox(height: 12 + 16),
                      ReactiveTextField(
                        key: const Key('UsernameField'),
                        state: c.login,
                        label: 'label_identifier'.l10n,
                        hint: 'label_sign_in_input'.l10n,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      const SizedBox(height: 16),
                      ReactiveTextField(
                        key: const ValueKey('PasswordField'),
                        state: c.password,
                        label: 'label_password'.l10n,
                        hint: 'label_your_password'.l10n,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        obscure: c.obscurePassword.value,
                        onSuffixPressed: c.obscurePassword.toggle,
                        treatErrorAsStatus: false,
                        trailing: Center(
                          child: SvgIcon(
                            c.obscurePassword.value
                                ? SvgIcons.visibleOff
                                : SvgIcons.visibleOn,
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
                          leading: SvgIcon(
                            enabled ? SvgIcons.enterWhite : SvgIcons.enterGrey,
                            height: 20,
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Center(
                        child: WidgetButton(
                          key: const Key('ForgotPassword'),
                          onPressed: () {
                            c.recoveryIdentifier.clear();
                            c.recoveryCode.clear();
                            c.recoveryPassword.clear();
                            c.recoveryRepeatPassword.clear();
                            c.recoveryIdentifier.text = c.login.text;
                            c.page.value = IntroductionStage.recovery;
                          },
                          child: Text(
                            'btn_forgot_password'.l10n,
                            style: style.fonts.small.regular.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ];
                    break;

                  case IntroductionStage.signInWithEmail:
                    header = ModalPopupHeader(
                      text: 'label_sign_in_with_one_time_code'.l10n,
                      onBack: () => c.page.value = IntroductionStage.signIn,
                      close: false,
                    );
                    children = [
                      const SizedBox(height: 16),
                      ReactiveTextField(
                        state: c.email,
                        label: 'label_identifier'.l10n,
                        hint: 'label_sign_in_input'.l10n,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        style: style.fonts.normal.regular.onBackground,
                        treatErrorAsStatus: false,
                      ),
                      const SizedBox(height: 25),
                      Center(
                        child: Obx(() {
                          final bool enabled = !c.email.isEmpty.value;

                          return PrimaryButton(
                            onPressed: enabled ? c.email.submit : null,
                            title: 'btn_send_one_time_code'.l10n,
                            leading: SvgIcon(
                              enabled
                                  ? SvgIcons.emailWhite
                                  : SvgIcons.emailGrey,
                              height: 20,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                    ];
                    break;

                  case IntroductionStage.signInWithEmailCode:
                    header = ModalPopupHeader(
                      text: 'label_sign_in_with_one_time_code'.l10n,
                      onBack: () =>
                          c.page.value = IntroductionStage.signInWithEmail,
                      close: false,
                    );

                    children = [
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          c.email.text,
                          style: style.fonts.normal.regular.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'label_add_email_confirmation_sent'.l10n,
                        style: style.fonts.small.regular.secondary,
                      ),
                      const SizedBox(height: 25),
                      ReactiveTextField(
                        key: const Key('EmailCodeField'),
                        state: c.emailCode,
                        label: 'label_one_time_password'.l10n,
                        hint: 'label_enter_code'.l10n,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        type: TextInputType.number,
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
                            !c.emailCode.isEmpty.value &&
                            c.codeTimeout.value == 0 &&
                            !c.authStatus.value.isLoading;

                        return Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                key: const Key('Resend'),
                                onPressed: c.resendEmailTimeout.value == 0
                                    ? c.resendEmail
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
                                title: c.codeTimeout.value == 0
                                    ? 'btn_sign_in'.l10n
                                    : 'label_wait_seconds'.l10nfmt({
                                        'for': c.codeTimeout.value,
                                      }),
                                onPressed: enabled ? c.emailCode.submit : null,
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 26),
                    ];
                    break;

                  case IntroductionStage.recovery:
                    header = ModalPopupHeader(
                      onBack: () =>
                          c.page.value = IntroductionStage.signInWithPassword,
                      close: false,
                      text: 'label_recover_account'.l10n,
                    );

                    children = [
                      ReactiveTextField(
                        key: const Key('RecoveryField'),
                        state: c.recoveryIdentifier,
                        label: 'label_identifier'.l10n,
                        hint: 'label_sign_in_input'.l10n,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      const SizedBox(height: 25),
                      PrimaryButton(
                        key: const Key('Proceed'),
                        title: 'btn_proceed'.l10n,
                        onPressed: c.recoveryIdentifier.isEmpty.value
                            ? null
                            : c.recoveryIdentifier.submit,
                      ),
                      const SizedBox(height: 16),
                    ];
                    break;

                  case IntroductionStage.recoveryCode:
                    header = ModalPopupHeader(
                      onBack: () =>
                          c.page.value = IntroductionStage.signInWithPassword,
                      close: false,
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
                      const SizedBox(height: 16),
                    ];
                    break;

                  case IntroductionStage.recoveryPassword:
                    header = ModalPopupHeader(
                      onBack: () =>
                          c.page.value = IntroductionStage.signInWithPassword,
                      close: false,
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
                        state: c.recoveryPassword,
                        label: 'label_new_password'.l10n,
                        hint: 'label_enter_password'.l10n,
                        obscured: c.obscureNewPassword,
                        treatErrorAsStatus: false,
                      ),
                      const SizedBox(height: 16),
                      ReactiveTextField.password(
                        key: const Key('RepeatPasswordField'),
                        state: c.recoveryRepeatPassword,
                        label: 'label_confirm_password'.l10n,
                        hint: 'label_repeat_password'.l10n,
                        obscured: c.obscureRepeatPassword,
                        treatErrorAsStatus: false,
                      ),
                      const SizedBox(height: 25),
                      Obx(() {
                        final bool enabled =
                            !c.recoveryPassword.isEmpty.value &&
                            !c.recoveryRepeatPassword.isEmpty.value;

                        return PrimaryButton(
                          key: const Key('Proceed'),
                          title: 'btn_proceed'.l10n,
                          onPressed: enabled ? c.resetUserPassword : null,
                        );
                      }),
                      const SizedBox(height: 16),
                    ];
                    break;

                  case IntroductionStage.accountCreating:
                    header = ModalPopupHeader(
                      text: 'label_sign_up'.l10n,
                      onBack: () => c.page.value = IntroductionStage.signIn,
                      close: false,
                    );
                    children = [
                      const SizedBox(height: 25),
                      ReactiveTextField(
                        key: const ValueKey('NameField'),
                        state: c.signUpName,
                        label: 'label_name_optional'.l10n,
                        hint: 'label_name_hint'.l10n,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      const SizedBox(height: 20),
                      ReactiveTextField(
                        key: const ValueKey('LoginField'),
                        state: c.signUpLogin,
                        label: 'label_login_optional'.l10n,
                        hint: 'label_login_example'.l10n,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      const SizedBox(height: 20),
                      ReactiveTextField(
                        key: const ValueKey('EmailField'),
                        state: c.signUpEmail,
                        label: 'label_email_optional'.l10n,
                        hint: 'label_email_example'.l10n,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      const SizedBox(height: 20),
                      ReactiveTextField(
                        key: const ValueKey('PasswordField'),
                        state: c.password,
                        label: 'label_password_optional'.l10n,
                        hint: 'label_your_password'.l10n,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        obscure: c.obscurePassword.value,
                        onSuffixPressed: c.obscurePassword.toggle,
                        treatErrorAsStatus: false,
                        trailing: Center(
                          child: SvgIcon(
                            c.obscurePassword.value
                                ? SvgIcons.visibleOff
                                : SvgIcons.visibleOn,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ReactiveTextField(
                        key: const ValueKey('RepeatPasswordField'),
                        state: c.repeatPassword,
                        label: 'label_repeat_password_optional'.l10n,
                        hint: 'label_your_password'.l10n,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        obscure: c.obscureRepeatPassword.value,
                        onSuffixPressed: c.obscureRepeatPassword.toggle,
                        treatErrorAsStatus: false,
                        trailing: Center(
                          child: SvgIcon(
                            c.obscureRepeatPassword.value
                                ? SvgIcons.visibleOff
                                : SvgIcons.visibleOn,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Obx(() {
                        final bool enabled =
                            c.signUpName.error.value == null &&
                            c.signUpLogin.error.value == null &&
                            c.signUpEmail.error.value == null &&
                            c.password.error.value == null &&
                            c.repeatPassword.error.value == null;

                        return PrimaryButton(
                          key: const Key('ProceedButton'),
                          onPressed: enabled
                              ? () {
                                  c.createAccount();
                                  c.page.value =
                                      IntroductionStage.accountCreated;
                                }
                              : null,
                          title: 'btn_create_account'.l10n,
                          leading: SvgIcon(SvgIcons.addUserWhite),
                        );
                      }),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  'alert_by_proceeding_you_accept_terms1'.l10n,
                            ),
                            TextSpan(
                              text:
                                  'alert_by_proceeding_you_accept_terms2'.l10n,
                              style: style.fonts.small.regular.primary,
                              recognizer: TapGestureRecognizer()..onTap = () {},
                            ),
                            TextSpan(
                              text:
                                  'alert_by_proceeding_you_accept_terms3'.l10n,
                            ),
                          ],
                        ),
                        style: style.fonts.small.regular.secondary,
                      ),
                      const SizedBox(height: 25),
                    ];
                    break;

                  case IntroductionStage.accountCreated:
                    header = ModalPopupHeader(
                      text:
                          c.myUser.value == null ||
                              c.myUser.value?.id.isLocal == true
                          ? 'label_account_creating_dots'.l10n
                          : 'label_account_creating_done'.l10n,
                      close: false,
                    );
                    children = [
                      const SizedBox(height: 12),
                      _num(c, context),
                      SizedBox(height: 16),
                      ContactTile(
                        myUser: c.myUser.value,
                        subtitle: [
                          SizedBox(height: 6),
                          Text(
                            'Welcome to Tapopa',
                            style: style.fonts.normal.regular.secondary,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      Text(
                        'label_account_created_description'.l10n,
                        style: style.fonts.small.regular.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  'alert_by_proceeding_you_accept_terms1'.l10n,
                              style: style.fonts.small.regular.secondary,
                            ),
                            TextSpan(
                              text:
                                  'alert_by_proceeding_you_accept_terms2'.l10n,
                              style: style.fonts.small.regular.primary,
                              recognizer: TapGestureRecognizer()..onTap = () {},
                            ),
                            TextSpan(
                              text:
                                  'alert_by_proceeding_you_accept_terms3'.l10n,
                              style: style.fonts.small.regular.secondary,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                      PrimaryButton(
                        key: const Key('ProceedButton'),
                        onPressed: c.dismiss,
                        title: 'btn_ok'.l10n,
                      ),
                      const SizedBox(height: 25),
                    ];
                    break;

                  case IntroductionStage.language:
                    header = ModalPopupHeader(
                      text: 'label_language'.l10n,
                      onBack: () => c.page.value = c.previousPage,
                      close: false,
                    );
                    children = [
                      const SizedBox(height: 8),
                      ...L10n.languages.map((e) {
                        return Padding(
                          padding: ModalPopup.padding(
                            context,
                          ).add(const EdgeInsets.only(bottom: 8)),
                          child: Obx(() {
                            final bool selected = L10n.chosen.value == e;

                            return RectangleButton(
                              key: Key('Language_${e.locale.languageCode}'),
                              selected: selected,
                              onPressed: () {
                                L10n.set(e);
                              },
                              child: Row(
                                children: [
                                  Text(e.locale.languageCode.toUpperCase()),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 1,
                                    height: 14,
                                    color: selected
                                        ? style.colors.onPrimary
                                        : style
                                              .colors
                                              .secondaryHighlightDarkest,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(e.name),
                                ],
                              ),
                            );
                          }),
                        );
                      }),
                      const SizedBox(height: 16),
                    ];
                    break;

                  case IntroductionStage.guestCreated:
                    header = ModalPopupHeader(
                      text: 'label_guest_account_created'.l10n,
                      close: false,
                    );

                    children = [
                      _name(c, context),
                      const SizedBox(height: 20),
                      _num(c, context),
                      const SizedBox(height: 16),
                      Text(
                        'label_introduction_for_one_time'.l10n,
                        style: style.fonts.small.regular.secondary,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        key: const Key('ProceedButton'),
                        onPressed: c.dismiss,
                        title: 'btn_proceed'.l10n,
                      ),
                      const SizedBox(height: 16),
                      Center(child: _terms(context)),
                      const SizedBox(height: 8),
                    ];
                    break;
                }

                return AnimatedSizeAndFade(
                  sizeDuration: const Duration(milliseconds: 250),
                  fadeDuration: const Duration(milliseconds: 250),
                  child: Column(
                    key: Key('${c.page.value?.name.capitalized}Screen'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header ?? const SizedBox(height: 0),
                      Flexible(
                        child: ListView(
                          padding: padding,
                          shrinkWrap: true,
                          children: children,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the [ReactiveTextField] for [UserName].
  Widget _name(IntroductionController c, BuildContext context) {
    return ReactiveTextField(
      key: Key('NameField'),
      state: c.name,
      label: 'label_your_name'.l10n,
      hint: 'label_name_hint'.l10n,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      formatters: [LengthLimitingTextInputFormatter(100)],
    );
  }

  /// Builds the [UserNumCopyable].
  Widget _num(IntroductionController c, BuildContext context) {
    return Obx(() {
      return UserNumCopyable(
        c.myUser.value?.num,
        key: const Key('NumCopyable'),
        share: PlatformUtils.isMobile,
        label: 'label_your_num'.l10n,
      );
    });
  }

  /// Builds the legal disclaimer information.
  Widget _terms(BuildContext context) {
    final style = Theme.of(context).style;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'alert_by_proceeding_you_accept_terms1'.l10n,
            style: style.fonts.smallest.regular.secondary,
          ),
          TextSpan(
            text: 'alert_by_proceeding_you_accept_terms2'.l10n,
            style: style.fonts.smallest.regular.primary,
            recognizer: TapGestureRecognizer()
              ..onTap = () => TermsOfUseView.show(context),
          ),
          TextSpan(
            text: 'alert_by_proceeding_you_accept_terms3'.l10n,
            style: style.fonts.smallest.regular.secondary,
          ),
        ],
      ),
    );
  }

  Widget _profiles(BuildContext context, IntroductionController c) {
    final style = Theme.of(context).style;

    return Obx(() {
      final profiles = c.profiles.where((e) => e.id != c.userId).toList();

      return Container(
        color: Color(0xFFe5ecf2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, -8),
              child: LineDivider('label_saved_accounts'.l10n),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 16),
                  ...profiles.map((e) {
                    final bool expired = !c.accounts.containsKey(e.id);

                    return Padding(
                      padding: ModalPopup.padding(context),
                      child: ContactTile(
                        key: Key('Account_${e.id}'),
                        myUser: e,

                        // TODO: Prompt to sign in to the non-[authorized].
                        onTap: () async {
                          if (expired) {
                            final hasPasswordOrEmail =
                                e.hasPassword || e.emails.confirmed.isNotEmpty;

                            if (hasPasswordOrEmail) {
                              c.page.value = IntroductionStage.signInAs;
                              c.signInAs = e;
                              c.login.unchecked = e.num.toString();
                              c.email.unchecked = e.num.toString();
                            } else {
                              await AccountIsNotAccessibleView.show(context, e);
                            }
                          } else {
                            await c.switchTo(e.id);
                          }
                        },
                        subtitle: [
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (expired)
                                Expanded(
                                  child: Text(
                                    'label_sign_in_required'.l10n,
                                    style: style.fonts.normal.regular.danger,
                                  ),
                                )
                              else
                                Expanded(
                                  child: Text(
                                    'label_signed_in'.l10n,
                                    style: style.fonts.normal.regular.secondary,
                                  ),
                                ),
                              WidgetButton(
                                key: const Key('RemoveAccount'),
                                onPressed: () async {
                                  bool? result;

                                  result = await MessagePopup.alert(
                                    'btn_remove_account'.l10n,
                                    description: [
                                      TextSpan(
                                        style:
                                            style.fonts.small.regular.secondary,
                                        children: [
                                          TextSpan(
                                            text:
                                                'label_account_will_be_removed_from_list1'
                                                    .l10n,
                                          ),
                                          TextSpan(
                                            style: style
                                                .fonts
                                                .small
                                                .regular
                                                .onBackground,
                                            text: '${e.name ?? e.num}',
                                          ),
                                          TextSpan(
                                            text:
                                                'label_account_will_be_removed_from_list2'
                                                    .l10n,
                                          ),
                                        ],
                                      ),
                                    ],
                                    button: (context) =>
                                        MessagePopup.deleteButton(
                                          context,
                                          label: 'btn_remove_account'.l10n,
                                          icon: SvgIcons.removeFromCallWhite,
                                        ),
                                  );

                                  if (result == true) {
                                    await c.deleteAccount(e.id);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    0,
                                    6,
                                    0,
                                  ),
                                  child: Text(
                                    'btn_remove'.l10n,
                                    style: style.fonts.normal.regular.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // TODO: Uncomment, when [MyUser]s will receive their
                          //       updates in real-time.
                          // else
                          //   Text(
                          //     myUser.getStatus() ?? '',
                          //     style: style.fonts.small.regular.secondary,
                          //   )
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(0, 8),
              child: LineDivider('label_add_account'.l10n),
            ),
          ],
        ),
      );
    });
  }
}
