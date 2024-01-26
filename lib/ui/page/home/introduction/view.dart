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
import 'package:get/get.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/widget/num.dart';
import 'package:messenger/ui/page/login/controller.dart';
import 'package:messenger/ui/page/login/view.dart';
import 'package:messenger/ui/widget/download_button.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:share_plus/share_plus.dart';

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
              header = null;
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

              // header = ModalPopupHeader(
              //   header: Padding(
              //     padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
              //     child: Center(
              //       child: OutlinedRoundedButton(
              //         title: const Text('Messenger by Gapopa'),
              //         subtitle: Text('btn_download'.l10n),
              //         maxWidth: 290,
              //         height: 72,
              //         leading: const SvgImage.asset(
              //           'assets/icons/logo.svg',
              //           width: 36,
              //           height: 36,
              //         ),
              //         onPressed: () => LoginView.show(context),
              //       ),
              //     ),
              //   ),
              // );
              // header = ModalPopupHeader(

              //   child: Center(
              //     child: Row(
              //       mainAxisSize: MainAxisSize.min,
              //       children: [
              //         // Image.asset(
              //         //   'assets/icons/application/macOS.png',
              //         //   width: 72,
              //         //   height: 72,
              //         // ),
              //         // Padding(
              //         //   padding: const EdgeInsets.all(12.0),
              //         //   child: SvgImage.asset(
              //         //     'assets/icons/face.svg',
              //         //     width: 36,
              //         //     height: 36,
              //         //   ),
              //         // ),
              //         Column(
              //           mainAxisSize: MainAxisSize.min,
              //           // crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text(
              //               'Messenger',
              //               style: style.fonts.larger.regular.secondary,
              //               textAlign: TextAlign.center,
              //               overflow: TextOverflow.ellipsis,
              //               maxLines: 1,
              //             ),
              //             const SizedBox(height: 1.7),
              //             Text(
              //               'by Gapopa',
              //               style: style.fonts.medium.regular.secondary,
              //               textAlign: TextAlign.center,
              //               overflow: TextOverflow.ellipsis,
              //               maxLines: 1,
              //             ),
              //           ],
              //         ),
              //         // const SizedBox(width: 32),
              //       ],
              //     ),
              //   ),
              // ),
              // );

              children = [
                const SizedBox(height: 8),
                if (!PlatformUtils.isMobile) const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Messenger by Gapopa',
                    style: style.fonts.big.regular.onBackground,
                  ),
                ),
                const SizedBox(height: 12),
                if (!PlatformUtils.isMobile) const SizedBox(height: 4),
                // const SizedBox(height: 16),
                // Text(
                //   'Messenger',
                //   style: style.fonts.larger.regular.secondary,
                //   textAlign: TextAlign.center,
                //   overflow: TextOverflow.ellipsis,
                //   maxLines: 1,
                // ),
                // const SizedBox(height: 1.6),

                // const SizedBox(height: 20),
                // const InteractiveLogo(),
                // Padding(
                //   padding: const EdgeInsets.all(16.0),
                //   child: SvgImage.asset(
                //     'assets/icons/face.svg',
                //     width: 64,
                //     height: 64,
                //   ),
                // ),
                // Image.asset(
                //   'assets/icons/application/macOS.png',
                //   width: 128,
                //   height: 128,
                // ),
                // const SizedBox(height: 7),
                // const SizedBox(height: 25),

                const SizedBox(height: 8),
                // Center(
                //   child: OutlinedRoundedButton(
                //     title: const Padding(
                //       padding: EdgeInsets.only(top: 2),
                //       child: Text('Messenger by Gapopa'),
                //     ),
                //     // title: Padding(
                //     //   padding: const EdgeInsets.only(top: 2),
                //     //   child: const Text('Messenger by Gapopa'),
                //     // ),
                //     subtitle: Text('btn_download'.l10n),
                //     maxWidth: 290,
                //     height: 72 + 4,
                //     // height: 72 + 4,

                //     leading: Container(
                //       decoration: BoxDecoration(
                //         color: Colors.white,
                //         borderRadius: BorderRadius.circular(8),
                //         boxShadow: const [
                //           BoxShadow(
                //             color: Colors.black12,
                //             blurRadius: 8,
                //             offset: Offset(0, 4),
                //           ),
                //         ],
                //       ),
                //       width: 32,
                //       height: 32,
                //       padding: const EdgeInsets.all(4),
                //       child: const SvgImage.asset(
                //         'assets/icons/logo.svg',
                //         // width: 30,
                //         height: 24,
                //       ),
                //     ),
                //     onPressed: () => _download(context),
                //   ),
                // ),
                Center(
                  child: OutlinedRoundedButton(
                    title: Text('btn_download'.l10n),
                    maxWidth: 290,
                    height: 46,
                    leading: const Padding(
                      padding: EdgeInsets.fromLTRB(4, 0, 0, 0),
                      child: SvgIcon(SvgIcons.logo),
                    ),
                    // leading: Transform.translate(
                    //   offset: const Offset(4, 0),
                    //   child: const SvgIcon(SvgIcons.enter),
                    // ),
                    onPressed: () => _download(context),
                  ),
                ),
                const SizedBox(height: 15),

                // Center(
                //   child: OutlinedRoundedButton(
                //     key: const Key('RegisterButton'),
                //     title: Text('btn_sign_up'.l10n),
                //     maxWidth: 290,
                //     height: 46,
                //     leading: Transform.translate(
                //       offset: const Offset(3, 0),
                //       child: const SvgIcon(SvgIcons.register),
                //     ),
                //     onPressed: () => LoginView.show(context),
                //   ),
                // ),
                // const SizedBox(height: 15),

                Center(
                  child: OutlinedRoundedButton(
                    key: const Key('SignInButton'),
                    title: Text('btn_sign_in'.l10n),
                    maxWidth: 290,
                    height: 46,
                    leading: Transform.translate(
                      offset: const Offset(4, 0),
                      child: const SvgIcon(SvgIcons.enter),
                    ),
                    onPressed: () =>
                        LoginView.show(context, initial: LoginViewStage.signIn),
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: OutlinedRoundedButton(
                    key: const Key('StartButton'),
                    title: Text('btn_guest'.l10n),
                    maxWidth: 290,
                    height: 46,
                    leading: Transform.translate(
                      offset: const Offset(4, 0),
                      child: const SvgIcon(SvgIcons.oneTime),
                    ),
                    onPressed: Navigator.of(context).pop,
                  ),
                ),
                const SizedBox(height: 8),

                // Center(
                //   child: Text(
                //     'Messenger by Gapopa',
                //     style: style.fonts.normal.regular.secondary,
                //   ),
                // ),

                // const SizedBox(height: 15),
              ];
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
                  title: Text(
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
                  title: Text(
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
                  ...children.map((e) =>
                      Padding(padding: ModalPopup.padding(context), child: e)),
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
