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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/widget/num.dart';
import 'package:messenger/ui/page/login/controller.dart';
import 'package:messenger/ui/page/login/view.dart';
import 'package:messenger/ui/widget/download_button.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/web/web_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
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
    return ModalPopup.show(
      context: context,
      background: initial == IntroductionViewStage.link
          ? const Color(0xFFF0F2F4)
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
          final Widget? header;
          final List<Widget> children;

          switch (c.stage.value) {
            case IntroductionViewStage.link:
              // header = null;

              // header = const ModalPopupHeader(
              //   text: 'Messenger by Gapopa',
              //   close: false,
              //   // header: Center(
              //   //   child: Text(
              //   //     'Messenger by Gapopa',
              //   //     style: style.fonts.normal.regular.secondary,
              //   //   ),
              //   // ),
              //   dense: false,
              // );

              final guestButton = Center(
                child: OutlinedRoundedButton(
                  key: const Key('StartButton'),
                  maxWidth: 290,
                  height: 46,
                  leading: Transform.translate(
                    offset: const Offset(4, 0),
                    child: const SvgIcon(SvgIcons.oneTime),
                  ),
                  onPressed: Navigator.of(context).pop,
                  child: Text('btn_guest'.l10n),
                ),
              );

              final signInButton = Center(
                child: OutlinedRoundedButton(
                  key: const Key('SignInButton'),
                  child: Text('btn_sign_in'.l10n),
                  maxWidth: 290,
                  height: 46,
                  leading: Transform.translate(
                    offset: const Offset(4, 0),
                    child: const SvgIcon(SvgIcons.enter),
                  ),
                  onPressed: () =>
                      LoginView.show(context, initial: LoginViewStage.signIn),
                ),
              );

              final applicationButton = Center(
                child: OutlinedRoundedButton(
                  child: Text('label_application'.l10n),
                  maxWidth: 290,
                  height: 46,
                  leading: const Padding(
                    padding: EdgeInsets.fromLTRB(4, 0, 0, 0),
                    child: SvgIcon(SvgIcons.logo),
                  ),
                  onPressed: () async {
                    await WebUtils.launchScheme('/d/${router.joinByLink}');
                    if (context.mounted) {
                      await _download(context);
                    }
                  },
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
                        'Messenger by Gapopa',
                        style: style.fonts.normal.regular.secondary,
                      ),
                    ),
                  ),
                ];
              } else {
                header = const ModalPopupHeader(
                  text: 'Messenger by Gapopa',
                  // header: Padding(
                  //   padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                  //   child: Text(
                  //     'Messenger by Gapopa',
                  //     style: style.fonts.big.regular.onBackground,
                  //     textAlign: TextAlign.center,
                  //   ),
                  // ),
                  dense: false,
                );
                children = [
                  const SizedBox(height: 8),
                  if (true || PlatformUtils.isWeb) ...[
                    applicationButton,
                    const SizedBox(height: 15),
                  ],
                  guestButton,
                  const SizedBox(height: 15),
                  signInButton,
                  const SizedBox(height: 16),
                ];
              }
              break;

            case IntroductionViewStage.signUp:
              header = ModalPopupHeader(text: 'label_account_created'.l10n);

              children = [
                const SizedBox(height: 25),
                _num(c, context),
                const SizedBox(height: 25),
                _link(c, context),
                const SizedBox(height: 25),
                OutlinedRoundedButton(
                  key: const Key('OkButton'),
                  maxWidth: double.infinity,
                  child: Text(
                    'btn_ok'.l10n,
                    style: style.fonts.normal.regular.onPrimary,
                  ),
                  onPressed: Navigator.of(context).pop,
                  color: style.colors.primary,
                ),
                const SizedBox(height: 16),
              ];
              break;

            case IntroductionViewStage.oneTime:
              header = ModalPopupHeader(
                text: 'label_one_time_account_created'.l10n,
              );

              children = [
                const SizedBox(height: 25),
                _num(c, context),
                const SizedBox(height: 25),
                _link(c, context),
                const SizedBox(height: 25),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'label_introduction_description1'.l10n,
                        style: style.fonts.medium.regular.onBackground,
                      ),
                      TextSpan(
                        text: 'label_introduction_description2'.l10n,
                        style: style.fonts.medium.regular.primary,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).pop();
                            router.me();
                          },
                      ),
                      TextSpan(
                        text: 'label_introduction_description3'.l10n,
                        style: style.fonts.medium.regular.onBackground,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                OutlinedRoundedButton(
                  key: const Key('SetPasswordButton'),
                  maxWidth: double.infinity,
                  child: Text(
                    'btn_ok'.l10n,
                    style: style.fonts.normal.regular.onPrimary,
                  ),
                  onPressed: Navigator.of(context).pop,
                  color: style.colors.primary,
                ),
                const SizedBox(height: 16),
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: Scrollbar(
              key: Key('${c.stage.value.name.capitalizeFirst}Stage'),
              controller: c.scrollController,
              child: ListView(
                controller: c.scrollController,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                children: [
                  if (header != null) header,
                  ...children.map(
                    (e) => Padding(
                      padding: ModalPopup.padding(context),
                      child: e,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  /// Builds the [UserNumCopyable].
  Widget _num(IntroductionController c, BuildContext context) {
    return Obx(() {
      return UserNumCopyable(
        c.myUser.value?.num,
        key: const Key('NumCopyable'),
        share: PlatformUtils.isMobile,
      );
    });
  }

  /// Builds the [ChatDirectLink] visual representation field.
  Widget _link(IntroductionController c, BuildContext context) {
    Future<void> copy() async {
      if (PlatformUtils.isMobile) {
        Share.share(c.link.text);
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
              children: const [
                DownloadButton(
                  asset: SvgIcons.windows,
                  title: 'Windows',
                  link: 'messenger-windows.zip',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: SvgIcons.apple,
                  title: 'macOS',
                  link: 'messenger-macos.zip',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: SvgIcons.linux,
                  title: 'Linux',
                  link: 'messenger-linux.zip',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: SvgIcons.appStore,
                  title: 'App Store',
                  link: 'messenger-ios.zip',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: SvgIcons.googlePlay,
                  title: 'Google Play',
                  link: 'messenger-android.apk',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: SvgIcons.android,
                  title: 'Android',
                  link: 'messenger-android.apk',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
