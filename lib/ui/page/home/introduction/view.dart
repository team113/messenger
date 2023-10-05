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
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:share_plus/share_plus.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/widget/copyable.dart';
import '/ui/page/home/widget/sharable.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// Introduction displaying important information alongside with an ability to
/// set a password.
///
/// Intended to be displayed with the [show] method.
class IntroductionView extends StatelessWidget {
  const IntroductionView({Key? key}) : super(key: key);

  /// Displays an [IntroductionView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const IntroductionView());
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('IntroductionView'),
      init: IntroductionController(Get.find()),
      builder: (IntroductionController c) {
        return Obx(() {
          List<Widget> numId() {
            return [
              const SizedBox(height: 25),
              if (PlatformUtils.isMobile)
                SharableTextField(
                  key: const Key('NumCopyable'),
                  text: c.num.text,
                  label: 'label_num'.l10n,
                  share: 'Gapopa ID: ${c.myUser.value?.num}',
                  style: style.fonts.headlineMedium,
                )
              else
                CopyableTextField(
                  key: const Key('NumCopyable'),
                  state: c.num,
                  label: 'label_num'.l10n,
                  style: style.fonts.headlineMedium,
                ),
              const SizedBox(height: 25),
            ];
          }

          final Widget header;
          final List<Widget> children;

          switch (c.stage.value) {
            case IntroductionViewStage.signUp:
              header = ModalPopupHeader(text: 'label_account_created'.l10n);

              children = [
                const SizedBox(height: 25),
                if (PlatformUtils.isMobile)
                  SharableTextField(
                    text: c.num.text,
                    label: 'label_num'.l10n,
                    share: 'Gapopa ID: ${c.myUser.value?.num}',
                    style: style.fonts.headlineMedium,
                  )
                else
                  CopyableTextField(
                    state: c.num,
                    label: 'label_num'.l10n,
                    style: style.fonts.headlineMedium,
                  ),
                const SizedBox(height: 25),
                // _emails(c, context),
                // _phones(c, context),
                _link(c, context),
                const SizedBox(height: 25),
                OutlinedRoundedButton(
                  key: const Key('OkButton'),
                  maxWidth: double.infinity,
                  title: Text(
                    'btn_ok'.l10n,
                    style: style.fonts.bodyMedium.copyWith(
                      color: style.colors.onPrimary,
                    ),
                  ),
                  onPressed: Navigator.of(context).pop,
                  color: style.colors.primary,
                ),
              ];
              break;

            case IntroductionViewStage.validate:
              header = ModalPopupHeader(text: 'label_account_created'.l10n);

              children = [
                ...numId(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Obx(() {
                    return Text(
                      c.resent.value
                          ? 'label_add_email_confirmation_sent_again'.l10n
                          : 'label_add_email_confirmation_sent'.l10n,
                      style: style.fonts.bodyMedium.copyWith(
                        color: style.colors.secondary,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  state: c.emailCode,
                  label: 'label_confirmation_code'.l10n,
                  style: style.fonts.headlineMedium,
                  treatErrorAsStatus: false,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 25),
                Obx(() {
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedRoundedButton(
                          key: const Key('Resend'),
                          maxWidth: double.infinity,
                          title: Text(
                            c.resendEmailTimeout.value == 0
                                ? 'label_resend'.l10n
                                : 'label_resend_timeout'.l10nfmt(
                                    {'timeout': c.resendEmailTimeout.value},
                                  ),
                            style: style.fonts.bodyMedium.copyWith(
                              color: c.resendEmailTimeout.value == 0
                                  ? style.colors.onPrimary
                                  : style.colors.onBackground,
                            ),
                          ),
                          onPressed: c.resendEmailTimeout.value == 0
                              ? c.resendEmail
                              : null,
                          color: style.colors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedRoundedButton(
                          key: const Key('Proceed'),
                          maxWidth: double.infinity,
                          title: Text(
                            'btn_proceed'.l10n,
                            style: style.fonts.bodyMedium.copyWith(
                              color: c.emailCode.isEmpty.value
                                  ? style.colors.onBackground
                                  : style.colors.onPrimary,
                            ),
                          ),
                          onPressed: c.emailCode.isEmpty.value
                              ? null
                              : c.emailCode.submit,
                          color: style.colors.primary,
                        ),
                      ),
                    ],
                  );
                }),
              ];

            case IntroductionViewStage.password:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = null,
                text: 'label_one_time_account_created'.l10n,
              );

              children = [
                ...numId(),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'btn_set_password'.l10n,
                    style: style.fonts.headlineMedium,
                  ),
                ),
                const SizedBox(height: 18),
                ReactiveTextField(
                  key: const Key('PasswordField'),
                  state: c.password,
                  label: 'label_password'.l10n,
                  obscure: c.obscurePassword.value,
                  style: style.fonts.headlineMedium,
                  onSuffixPressed: c.obscurePassword.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgImage.asset(
                    'assets/icons/visible_${c.obscurePassword.value ? 'off' : 'on'}.svg',
                    width: 17.07,
                  ),
                ),
                const SizedBox(height: 12),
                ReactiveTextField(
                  key: const Key('RepeatPasswordField'),
                  state: c.repeat,
                  label: 'label_repeat_password'.l10n,
                  obscure: c.obscureRepeat.value,
                  style: style.fonts.bodyMedium,
                  onSuffixPressed: c.obscureRepeat.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgImage.asset(
                    'assets/icons/visible_${c.obscureRepeat.value ? 'off' : 'on'}.svg',
                    width: 17.07,
                  ),
                ),
                const SizedBox(height: 25),
                OutlinedRoundedButton(
                  key: const Key('ChangePasswordButton'),
                  title: Text(
                    'btn_proceed'.l10n,
                    style: style.fonts.bodyMedium.copyWith(
                      color: c.password.isEmpty.value || c.repeat.isEmpty.value
                          ? style.colors.onBackground
                          : style.colors.onPrimary,
                    ),
                  ),
                  onPressed: c.password.isEmpty.value || c.repeat.isEmpty.value
                      ? null
                      : c.setPassword,
                  color: style.colors.primary,
                ),
              ];
              break;

            case IntroductionViewStage.success:
              header = ModalPopupHeader(
                text: 'label_one_time_account_created'.l10n,
              );

              children = [
                ...numId(),
                Text(
                  'label_password_set'.l10n,
                  style: style.fonts.bodyMedium.copyWith(
                    color: style.colors.secondary,
                  ),
                ),
                const SizedBox(height: 25),
                Center(
                  child: OutlinedRoundedButton(
                    key: const Key('CloseButton'),
                    maxWidth: double.infinity,
                    title: Text(
                      'btn_close'.l10n,
                      style: style.fonts.bodyMedium.copyWith(
                        color: style.colors.onPrimary,
                      ),
                    ),
                    onPressed: Navigator.of(context).pop,
                    color: style.colors.primary,
                  ),
                ),
              ];
              break;

            default:
              header = ModalPopupHeader(
                text: 'label_one_time_account_created'.l10n,
              );

              children = [
                ...numId(),
                _link(c, context),
                const SizedBox(height: 25),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'label_introduction_description1'.l10n,
                        style: style.fonts.titleLarge,
                      ),
                      TextSpan(
                        text: 'label_introduction_description2'.l10n,
                        style: style.fonts.titleLarge
                            .copyWith(color: style.colors.primary),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).pop();
                            router.me();
                          },
                      ),
                      TextSpan(
                        text: 'label_introduction_description3'.l10n,
                        style: style.fonts.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                OutlinedRoundedButton(
                  key: const Key('SetPasswordButton'),
                  maxWidth: double.infinity,
                  title: Text(
                    'btn_ok'.l10n,
                    style: style.fonts.bodyMedium.copyWith(
                      color: style.colors.onPrimary,
                    ),
                  ),
                  onPressed: Navigator.of(context).pop,
                  color: style.colors.primary,
                ),
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
                physics: const ClampingScrollPhysics(),
                children: [
                  header,
                  ...children.map((e) =>
                      Padding(padding: ModalPopup.padding(context), child: e)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _emails(IntroductionController c, BuildContext context) {
    final style = Theme.of(context).style;

    final Iterable<UserEmail> emails = [
      ...c.myUser.value?.emails.confirmed ?? <UserEmail>[],
      c.myUser.value?.emails.unconfirmed,
    ].whereNotNull();

    if (emails.isEmpty) {
      return const SizedBox();
    }

    final List<Widget> widgets = [];

    for (var e in emails) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (PlatformUtils.isMobile)
              SharableTextField(
                text: e.val,
                label: 'label_email'.l10n,
                style: style.fonts.headlineMedium,
              )
            else
              CopyableTextField(
                state: TextFieldState(text: e.val, editable: false),
                label: 'label_email'.l10n,
                style: style.fonts.headlineMedium,
              ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    return Column(children: [...widgets, const SizedBox(height: 25)]);
  }

  Widget _phones(IntroductionController c, BuildContext context) {
    final style = Theme.of(context).style;

    final Iterable<UserPhone> phones = [
      ...c.myUser.value?.phones.confirmed ?? <UserPhone>[],
      c.myUser.value?.phones.unconfirmed,
    ].whereNotNull();

    if (phones.isEmpty) {
      return const SizedBox();
    }

    final List<Widget> widgets = [];

    for (var e in phones) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (PlatformUtils.isMobile)
              SharableTextField(
                text: e.val,
                label: 'label_phone_number'.l10n,
                style: style.fonts.headlineMedium,
              )
            else
              CopyableTextField(
                state: TextFieldState(text: e.val, editable: false),
                label: 'label_phone_number'.l10n,
                style: style.fonts.headlineMedium,
              ),
          ],
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    return Column(children: [...widgets, const SizedBox(height: 15)]);
  }

  Widget _link(IntroductionController c, BuildContext context) {
    final style = Theme.of(context).style;

    return ReactiveTextField(
      key: const Key('LinkField'),
      state: TextFieldState(
        text:
            '${Config.origin.replaceFirst('https://', '').replaceFirst('http://', '')}${Routes.chatDirectLink}/${c.link.text}',
        editable: false,
      ),
      style: style.fonts.bodyMedium,
      onSuffixPressed: () async {
        await c.copyLink(
          onSuccess: () async {
            final link =
                '${Config.origin}${Routes.chatDirectLink}/${c.link.text}';

            if (PlatformUtils.isMobile) {
              await Share.share(link);
            } else {
              PlatformUtils.copy(text: link);
              MessagePopup.success('label_copied'.l10n);
            }
          },
        );
      },
      trailing: PlatformUtils.isMobile
          ? Transform.translate(
              offset: const Offset(0, -4),
              child: Icon(
                Icons.ios_share_rounded,
                color: style.colors.primary,
                size: 21,
              ),
            )
          : Transform.translate(
              offset: const Offset(0, -1),
              child: Transform.scale(
                scale: 1.15,
                child:
                    const SvgImage.asset('assets/icons/copy.svg', height: 15),
              ),
            ),
      label: 'label_your_direct_link'.l10n,
    );
  }
}
