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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '/config.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/auth/widget/cupertino_button.dart';
import '/ui/page/home/widget/num.dart';
import '/ui/page/login/controller.dart';
import '/ui/page/login/terms_of_use/view.dart';
import '/ui/page/login/view.dart';
import '/ui/widget/download_button.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// Introduction displaying important information alongside with an ability to
/// set a password.
///
/// Intended to be displayed with the [show] method.
class IntroductionView extends StatelessWidget {
  const IntroductionView({
    super.key,
    this.initial = IntroductionViewStage.oneTime,
  });

  /// Initial [IntroductionViewStage] to display.
  final IntroductionViewStage initial;

  /// Displays an [IntroductionView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    IntroductionViewStage initial = IntroductionViewStage.oneTime,
  }) {
    final style = Theme.of(context).style;

    return ModalPopup.show(
      context: context,
      background: initial == IntroductionViewStage.link
          ? style.colors.background
          : null,
      child: IntroductionView(initial: initial),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('IntroductionView'),
      init: IntroductionController(Get.find(), initial: initial),
      builder: (IntroductionController c) {
        return Obx(() {
          final Widget header;
          final List<Widget> children;

          switch (c.stage.value) {
            case IntroductionViewStage.signUp:
              header = ModalPopupHeader(text: 'label_account_created'.l10n);

              children = [
                const SizedBox(height: 25),
                _num(c, context),
                const SizedBox(height: 25),
                _link(c, context),
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('OkButton'),
                  onPressed: Navigator.of(context).pop,
                  title: 'btn_ok'.l10n,
                ),
                const SizedBox(height: 16),
              ];
              break;

            case IntroductionViewStage.oneTime:
              header = ModalPopupHeader(
                text: 'label_guest_account_created'.l10n,
                close: false,
              );

              children = [
                const SizedBox(height: 25),
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
                  onPressed: Navigator.of(context).pop,
                  title: 'btn_proceed'.l10n,
                ),
                const SizedBox(height: 16),
                Center(child: _terms(context)),
              ];
              break;

            case IntroductionViewStage.link:
              final guestButton = Center(
                child: OutlinedRoundedButton(
                  key: const Key('StartButton'),
                  maxWidth: 290,
                  height: 46,
                  leading: Transform.translate(
                    offset: const Offset(4, 0),
                    child: const SvgIcon(SvgIcons.guest),
                  ),
                  onPressed: Navigator.of(context).pop,
                  child: Text('btn_guest'.l10n),
                ),
              );

              final signInButton = Center(
                child: OutlinedRoundedButton(
                  key: const Key('SignInButton'),
                  maxWidth: 290,
                  height: 46,
                  leading: Transform.translate(
                    offset: const Offset(4, 0),
                    child: const SvgIcon(SvgIcons.enter),
                  ),
                  onPressed: () =>
                      LoginView.show(context, initial: LoginViewStage.signIn),
                  child: Text('btn_sign_in'.l10n),
                ),
              );

              final applicationButton = Center(
                child: OutlinedRoundedButton(
                  key: const Key('DownloadButton'),
                  maxWidth: 290,
                  height: 46,
                  leading: const Padding(
                    padding: EdgeInsets.fromLTRB(4, 0, 0, 0),
                    child: SvgIcon(SvgIcons.logo),
                  ),
                  onPressed: () => _download(context),
                  child: Text('label_application'.l10n),
                ),
              );

              if (PlatformUtils.isMobile) {
                header = const ModalPopupHeader(dense: true);
                children = [
                  const SizedBox(height: 8),
                  guestButton,
                  const SizedBox(height: 15),
                  signInButton,
                  if (PlatformUtils.isWeb) ...[
                    const SizedBox(height: 15),
                    applicationButton,
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: Animate(
                      effects: const [
                        FadeEffect(
                          delay: Duration(milliseconds: 0),
                          duration: Duration(milliseconds: 2000),
                        ),
                        MoveEffect(
                          delay: Duration(milliseconds: 0),
                          begin: Offset(0, 100),
                          end: Offset(0, 0),
                          curve: Curves.ease,
                          duration: Duration(milliseconds: 1000),
                        ),
                      ],
                      child: Text(
                        'label_messenger_full'.l10n,
                        style: style.fonts.normal.regular.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25 / 2),
                  Center(
                    child: StyledCupertinoButton(
                      label: 'btn_terms_and_conditions'.l10n,
                      onPressed: () => TermsOfUseView.show(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                ];
              } else {
                header = ModalPopupHeader(
                  text: 'label_messenger_full'.l10n,
                  dense: false,
                );
                children = [
                  const SizedBox(height: 8),
                  if (PlatformUtils.isWeb) ...[
                    applicationButton,
                    const SizedBox(height: 15),
                  ],
                  guestButton,
                  const SizedBox(height: 15),
                  signInButton,
                  const SizedBox(height: 25 / 2),
                  Center(
                    child: StyledCupertinoButton(
                      label: 'btn_terms_and_conditions'.l10n,
                      onPressed: () => TermsOfUseView.show(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                ];
              }
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: Scrollbar(
              key: Key('${c.stage.value.name.capitalized}Stage'),
              controller: c.scrollController,
              child: ListView(
                key: const Key('IntroductionScrollable'),
                controller: c.scrollController,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                children: [
                  header,
                  ...children.map(
                    (e) =>
                        Padding(padding: ModalPopup.padding(context), child: e),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  /// Builds the [ReactiveTextField] for [UserName].
  Widget _name(IntroductionController c, BuildContext context) {
    return Obx(() {
      return ReactiveTextField(
        key: Key('NameField'),
        state: c.name,
        label: 'label_your_name'.l10n,
        hint: 'label_name_hint'.l10n,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        formatters: [LengthLimitingTextInputFormatter(100)],
      );
    });
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

  /// Builds the [ChatDirectLink] visual representation field.
  Widget _link(IntroductionController c, BuildContext context) {
    Future<void> copy() async {
      if (PlatformUtils.isMobile) {
        await SharePlus.instance.share(ShareParams(text: c.link.text));
      } else {
        PlatformUtils.copy(text: c.link.text);
        MessagePopup.success('label_copied'.l10n);
      }

      await c.createLink();
    }

    return ReactiveTextField(
      state: c.link,
      onSuffixPressed: copy,
      selectable: c.myUser.value?.chatDirectLink != null,
      trailing: PlatformUtils.isMobile
          ? const SvgIcon(SvgIcons.share)
          : const SvgIcon(SvgIcons.copy),
      label: 'label_your_direct_link'.l10n,
    );
  }

  /// Opens a [ModalPopup] listing the buttons for downloading the application.
  Future<void> _download(BuildContext context) async {
    await ModalPopup.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalPopupHeader(text: 'btn_download'.l10n),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              padding: ModalPopup.padding(context),
              shrinkWrap: true,
              children: [
                const DownloadButton.windows(),
                const SizedBox(height: 8),
                const DownloadButton.macos(),
                const SizedBox(height: 8),
                const DownloadButton.linux(),
                const SizedBox(height: 8),
                if (Config.appStoreUrl.isNotEmpty) ...[
                  DownloadButton.appStore(),
                  const SizedBox(height: 8),
                ],
                const DownloadButton.ios(),
                const SizedBox(height: 8),
                if (Config.googlePlayUrl.isNotEmpty) ...[
                  DownloadButton.googlePlay(),
                  const SizedBox(height: 8),
                ],
                const DownloadButton.android(),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
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
}
