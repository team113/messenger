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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:rive/rive.dart' hide LinearGradient;

import '/config.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/widget/download_button.dart';
import '/ui/page/login/view.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/animated_logo.dart';
import 'widget/cupertino_button.dart';

/// View of the [Routes.auth] page.
class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return GetBuilder(
      init: AuthController(Get.find()),
      builder: (AuthController c) {
        bool isWeb = PlatformUtils.isWeb || true;
        bool isAndroidWeb = isWeb && PlatformUtils.isAndroid;
        bool isIosWeb = isWeb && PlatformUtils.isIOS;
        bool isDesktopWeb = isWeb && PlatformUtils.isDesktop;

        final TextStyle? thin = context.textTheme.bodySmall?.copyWith(
          color: style.colors.onBackground,
        );

        final Widget status = LayoutBuilder(builder: (context, constraints) {
          final bool narrow = constraints.maxWidth > 300;

          return Container(
            width: double.infinity,
            // color: Colors.white.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Flex(
                mainAxisSize: narrow ? MainAxisSize.min : MainAxisSize.min,
                mainAxisAlignment: narrow
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.center,
                // direction: narrow ? Axis.horizontal : Axis.vertical,
                direction: Axis.vertical,
                children: [
                  // if (narrow)
                  //   const Expanded(
                  //     child: StyledCupertinoButton(
                  //       label: 'Terms and conditions',
                  //     ),
                  //   )
                  // else

                  // Container(
                  //   margin: const EdgeInsets.symmetric(horizontal: 10),
                  //   width: 1,
                  //   height: 12,
                  //   color: Colors.grey,
                  // ),
                  // StyledCupertinoButton(
                  //   onPressed: () => _download(context),
                  //   label: 'Download application',
                  // ),
                  // WidgetButton(
                  //   onPressed: () => _download(context),
                  //   child: SvgImage.asset(
                  //     'assets/icons/get_it_on_google_play.svg',
                  //     width: 759.84 * 0.23,
                  //     height: 257.23 * 0.23,
                  //   ),
                  // )
                  StyledCupertinoButton(
                    onPressed: () {
                      router.vacancy(null, push: true);
                      print(router.routes);
                    },
                    label: 'Work with us',
                  ),
                  StyledCupertinoButton(
                    label: 'Terms and conditions',
                    color: style.colors.secondary,
                  ),
                ],
              ),
            ),
          );
        });

        final Widget download = SvgImage.asset(
          'assets/icons/get_it_on_google_play.svg',
          width: 759.84 * 0.23,
          height: 257.23 * 0.23,
        );

        // Header part of the page.
        //
        // All frames of the animation are drawn in offstage in order to
        // load all the images ahead of animation to reduce the possible
        // flickering.
        List<Widget> header = [
          ...List.generate(10, (i) => 'assets/images/logo/head000$i.svg')
              .map((e) => Offstage(child: SvgImage.asset(e)))
              .toList(),
          // const SizedBox(height: 30),
          Text(
            'Messenger',
            style: thin?.copyWith(
              fontSize: 24,
              color: style.colors.secondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            'by Gapopa',
            style: thin?.copyWith(fontSize: 17, color: style.colors.secondary),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),

          // Text(
          //   'Gapopa',
          //   style: thin?.copyWith(fontSize: 32, color: style.colors.secondary),
          //   textAlign: TextAlign.center,
          //   overflow: TextOverflow.ellipsis,
          //   maxLines: 1,
          // ),
          // const SizedBox(height: 2),
          // Text(
          //   'messenger',
          //   style: thin?.copyWith(
          //     fontSize: 17,
          //     color: style.colors.secondary,
          //   ),
          //   textAlign: TextAlign.center,
          //   overflow: TextOverflow.ellipsis,
          //   maxLines: 1,
          // ),
          const SizedBox(height: 25),
        ];

        const double icon = 0.7;

        // Footer part of the page.
        List<Widget> footer = [
          const SizedBox(height: 25),
          OutlinedRoundedButton(
            key: const Key('RegisterButton'),
            // title: Text(
            //   'Enter'.l10n,
            //   style: TextStyle(color: style.colors.onPrimary),
            // ),
            title: Text(
              'Sign up'.l10n,
              style: TextStyle(color: style.colors.onPrimary),
            ),
            subtitle: Text(
              'or sign in'.l10n,
              style: TextStyle(color: style.colors.onPrimary),
            ),
            height: 53,
            // leading: SvgImage.asset('assets/icons/start.svg', width: 25 * 0.7),
            leading: SvgImage.asset(
              'assets/icons/sign_in_white.svg',
              width: 20 * 0.7,
            ),
            onPressed: () => LoginView.show(context),
            color: style.colors.primary,
          ),
          // const SizedBox(height: 6),
          // WidgetButton(
          //   child: Text(
          //     'One-time account',
          //     style: TextStyle(color: style.colors.primary),
          //   ),
          // ),

          // const SizedBox(height: 15),
          // OutlinedRoundedButton(
          //   title: Text('Работа'.l10n),
          //   leading: Padding(
          //     padding: const EdgeInsets.only(left: 2 * 0.7),
          //     child: SvgImage.asset(
          //       'assets/icons/partner16.svg',
          //       width: 36 * 0.61,
          //       height: 28 * 0.61,
          //     ),
          //   ),
          //   // color: Color.fromRGBO(110, 184, 118, 1),
          //   onPressed: () => FreelanceView.show(context),
          // ),
          // const SizedBox(height: 15),
          // OutlinedRoundedButton(
          //   key: const Key('SignInButton'),
          //   title: Text('btn_login'.l10n),
          //   leading:
          //       SvgImage.asset('assets/icons/sign_in.svg', width: 20 * 0.7),
          //   onPressed: () => LoginView.show(context),
          // ),

          const SizedBox(height: 15),
          OutlinedRoundedButton(
            key: const Key('StartButton'),
            title: Text('One-time'.l10n),
            subtitle: Text('account'.l10n),
            // style: fonts.labelMedium,
            height: 53,
            leading: SvgImage.asset('assets/icons/one-time.svg', width: 25.328),
            // leading:
            //     SvgImage.asset('assets/icons/sign_in.svg', width: 20 * 0.7),
            onPressed: c.register,
          ),
          // const SizedBox(height: 15),
          // StyledCupertinoButton(label: 'Скачать'),
          // const SizedBox(height: 48),
          // WidgetButton(
          //   onPressed: () => _download(context),
          //   child: SvgImage.asset('assets/icons/download_app_store.svg'),
          // ),
          // const SizedBox(height: 15),
          // StyledCupertinoButton(
          //   onPressed: () {
          //     router.vacancy(null, push: true);
          //     print(router.routes);
          //   },
          //   label: 'Work with us',
          // ),
          // const StyledCupertinoButton(label: 'Terms and conditions'),
          if (true) ...[
            if (isWeb) const SizedBox(height: 15),
            //   OutlinedRoundedButton(
            //     title: const Text('Download'),
            //     // subtitle: const Text('application'),
            //     height: 53,
            //     leading: Padding(
            //       padding: const EdgeInsets.only(bottom: 3 * 0.7),
            //       child: SvgImage.asset(
            //         'assets/icons/download_cloud.svg',
            //         width: 34.93,
            //         height: 22.79,
            //       ),
            //     ),
            //     onPressed: () => _download(context),
            //   ),
            // ],
            if (isIosWeb)
              OutlinedRoundedButton(
                title: const Text('Download'),
                // subtitle: const Text('application'),
                height: 53,
                leading: Padding(
                  padding: const EdgeInsets.only(bottom: 3 * 0.7),
                  child: SvgImage.asset('assets/icons/apple.svg',
                      width: 22 * icon),
                ),
                onPressed: () => _download(context),
              ),
            if (isAndroidWeb)
              OutlinedRoundedButton(
                title: Text('btn_download'.l10n),
                // subtitle: const Text('application'),
                height: 53,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 2 * 0.7),
                  child: SvgImage.asset(
                    'assets/icons/google.svg',
                    width: 22 * icon,
                  ),
                ),
                onPressed: () => _download(context),
              ),
            if (isDesktopWeb)
              OutlinedRoundedButton(
                title: Text('btn_download'.l10n),
                // subtitle: const Text('application'),
                height: 53,
                leading: PlatformUtils.isMacOS
                    ? SvgImage.asset('assets/icons/apple.svg', width: 22 * icon)
                    : (PlatformUtils.isWindows)
                        ? SvgImage.asset(
                            'assets/icons/windows.svg',
                            width: 22 * icon,
                          )
                        : (PlatformUtils.isLinux)
                            ? SvgImage.asset(
                                'assets/icons/linux.svg',
                                width: 22 * icon,
                              )
                            : null,
                onPressed: () => _download(context),
              ),
          ],
          // if (isWeb) const SizedBox(height: 15),
          // OutlinedRoundedButton(
          //   title: Text(
          //     // 'Работа и партнёрство'.l10n,
          //     // 'Work and cooperation'.l10n,
          //     'Work'.l10n,
          //   ),
          //   leading: Padding(
          //     padding: const EdgeInsets.only(left: 2 * 0.7),
          //     child: SvgImage.asset(
          //       'assets/icons/partner16.svg',
          //       width: 36 * 0.61,
          //       height: 28 * 0.61,
          //     ),
          //   ),
          //   // color: Color.fromRGBO(110, 184, 118, 1),
          //   onPressed: () => FreelanceView.show(context),
          // ),
          // const SizedBox(height: 20),
          // WidgetButton(
          //   onPressed: () => LanguageSelectionView.show(context, null),
          //   child: Container(
          //     child: Text(
          //       'Work and cooperation',
          //       style: TextStyle(
          //         fontSize: 11,
          //         color: Color.fromRGBO(110, 184, 118, 1),
          //       ),
          //     ),
          //   ),
          // ),
          // StyledCupertinoButton(
          //   label: 'Work and cooperation',
          //   onPressed: () => LanguageSelectionView.show(context, null),
          //   color: Color.fromRGBO(110, 184, 118, 1),
          // ),
          // const SizedBox(height: 8),

          // const StyledCupertinoButton(label: 'Terms and conditions'),
          // const StyledCupertinoButton(label: 'Contact us'),
          // const SizedBox(height: 32),
          // StyledCupertinoButton(
          //   label: 'label_language_entry'.l10nfmt({
          //     'code': L10n.chosen.value!.locale.countryCode,
          //     'name': L10n.chosen.value!.name,
          //   }),
          //   onPressed: () => LanguageSelectionView.show(context, null),
          // ),
        ];

        final Widget column = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...header,
            Obx(() {
              return AnimatedLogo(
                key: const ValueKey('Logo'),
                svgAsset: 'assets/images/logo/head000${c.logoFrame.value}.svg',
                onInit: Config.disableInfiniteAnimations
                    ? null
                    : (a) => _setBlink(c, a),
              );
            }),
            ...footer,
          ],
        );

        return Listener(
          onPointerDown: (_) => c.animate(),
          child: Container(
            color: style.colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: style.colors.background,
                  ),
                ),
                IgnorePointer(
                  child: SvgImage.asset(
                    'assets/images/background_light.svg',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Column(
                  children: [
                    Expanded(child: Center(child: column)),
                    // if (isWeb) download,
                    status,
                  ],
                ),
              ],
            ),
          ),
        );

        return Stack(
          key: const Key('AuthView'),
          children: [
            IgnorePointer(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: style.colors.background,
              ),
            ),
            IgnorePointer(
              child: SvgImage.asset(
                'assets/images/background_light.svg',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            GestureDetector(
              onTap: c.animate,
              child: Scaffold(
                backgroundColor: style.colors.transparent,
                body: Center(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              max(550, MediaQuery.of(context).size.height),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(child: column),
                            Opacity(opacity: 0, child: download),
                            Container(
                              color: Colors.transparent,
                              child: Opacity(opacity: 0, child: status),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // if (isWeb)
            Align(
              alignment: const Alignment(0, 0.7),
              child: WidgetButton(
                onPressed: () => _download(context),
                child: download,
              ),
            ),
            if (false)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 16, 0),
                  child: WidgetButton(
                    onPressed: () => _download(context),
                    child:
                        SvgImage.asset('assets/icons/download_app_store.svg'),
                  ),
                ),
              ),
            if (false)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Скачать\nприложение'),
                      ],
                    ),
                  ),
                ),
              ),
            Align(alignment: Alignment.bottomCenter, child: status),
          ],
        );
      },
    );
  }

  /// Sets the [AuthController.blink] from the provided [Artboard] and invokes
  /// a [AuthController.animate] to animate it.
  Future<void> _setBlink(AuthController c, Artboard a) async {
    final StateMachineController machine =
        StateMachineController(a.stateMachines.first);
    a.addController(machine);

    c.blink = machine.findInput<bool>('blink') as SMITrigger?;

    await Future.delayed(const Duration(milliseconds: 500), c.animate);
  }

  /// Opens a [ModalPopup] listing the buttons for downloading the application.
  Future<void> _download(BuildContext context) async {
    final style = Theme.of(context).style;

    await ModalPopup.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalPopupHeader(
            header: Center(
              child: Text(
                'btn_download'.l10n,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: style.colors.onBackground,
                      fontSize: 18,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              padding: ModalPopup.padding(context),
              shrinkWrap: true,
              children: const [
                DownloadButton(
                  asset: 'windows',
                  width: 21.93,
                  height: 22,
                  title: 'Windows',
                  link: 'messenger-windows.zip',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: 'apple',
                  width: 23,
                  height: 29,
                  title: 'macOS',
                  link: 'messenger-macos.zip',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: 'linux',
                  width: 18.85,
                  height: 22,
                  title: 'Linux',
                  link: 'messenger-linux.zip',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: 'apple',
                  width: 23,
                  height: 29,
                  title: 'iOS',
                  link: 'messenger-ios.zip',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: 'google',
                  width: 20.33,
                  height: 22.02,
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
