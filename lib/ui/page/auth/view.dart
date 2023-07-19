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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/widget/rmb_detector.dart';
import 'package:messenger/ui/page/login/controller.dart';
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

        Widget? icon;
        const double modifier = 1;

        if (isWeb) {
          icon = Obx(() {
            switch (c.system.value) {
              case 0:
                return SvgImage.asset(
                  'assets/icons/apple6_black.svg',
                  width: 19.15 * modifier,
                  height: 23.49 * modifier,
                );

              case 1:
                return SvgImage.asset(
                  'assets/icons/google4.svg',
                  width: 20.64 * modifier,
                  height: 23 * modifier,
                );

              case 2:
                return SvgImage.asset(
                  'assets/icons/linux4.svg',
                  width: 22.09 * modifier,
                  height: 26 * modifier,
                );

              case 3:
                return SvgImage.asset(
                  'assets/icons/windows4.svg',
                  width: 22.93 * modifier,
                  height: 23 * modifier,
                );
            }

            return const SizedBox();
          });
        }

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

                  // StyledCupertinoButton(
                  //   onPressed: () {
                  //     router.vacancy(null, push: true);
                  //     print(router.routes);
                  //   },
                  //   enlarge: true,
                  //   label: 'Work with us',
                  // ),
                  StyledCupertinoButton(
                    label: 'Terms and conditions',
                    color: style.colors.secondary,
                  ),
                ],
              ),
            ),
          );
        });

        // Header part of the page.
        //
        // All frames of the animation are drawn in offstage in order to
        // load all the images ahead of animation to reduce the possible
        // flickering.
        List<Widget> header = [
          ...List.generate(10, (i) => 'assets/images/logo/head000$i.svg')
              .map((e) => Offstage(child: SvgImage.asset(e)))
              .toList(),
          Text(
            'Messenger',
            style: thin?.copyWith(
              fontSize: 27,
              color: style.colors.secondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            'by Gapopa',
            style: thin?.copyWith(fontSize: 21, color: style.colors.secondary),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 25),
        ];

        List<Widget> footer = [
          const SizedBox(height: 25),
          OutlinedRoundedButton(
            key: const Key('RegisterButton'),
            title: Text('Регистрация'.l10n),
            maxWidth: 210,
            height: 46,
            // leading: SvgImage.asset(
            //   'assets/icons/door6.svg',
            //   width: 18.82,
            //   height: 23.73,
            // ),
            // leading: SvgImage.asset(
            //   'assets/icons/start_blue.svg',
            //   width: 23.91 * 1,
            //   height: 22.63 * 1,
            // ),
            leading: Transform.translate(
              offset: const Offset(-2, 0),
              child: Icon(
                Icons.how_to_reg,
                size: 26,
                color: style.colors.primary,
              ),
            ),
            onPressed: () => LoginView.show(context),
          ),
          const SizedBox(height: 15),
          OutlinedRoundedButton(
            key: const Key('SignButton'),
            title: Text('Вход'.l10n),
            maxWidth: 210,
            height: 46,
            leading: SvgImage.asset(
              'assets/icons/door6.svg',
              width: 18.82,
              height: 23.73,
            ),
            onPressed: () => LoginView.show(
              context,
              stage: LoginViewStage.signIn,
            ),
          ),
          const SizedBox(height: 15),
          OutlinedRoundedButton(
            key: const Key('StartButton'),
            subtitle: Text('Одноразовый\nаккаунт'.l10n),
            maxWidth: 210,
            height: 46,
            // leading: Transform.translate(
            //   offset: const Offset(-2, 0),
            //   child: Icon(
            //     Icons.local_drink_rounded,
            //     size: 26,
            //     color: style.colors.primary,
            //   ),
            // ),
            leading: SvgImage.asset(
              'assets/icons/start_blue.svg',
              width: 23.91 * 1,
              height: 22.63 * 1,
            ),
            onPressed: c.register,
          ),
          const SizedBox(height: 15),
          OutlinedRoundedButton(
            subtitle: Text(
              'Работайте\nс нами'.l10n,
              // style: TextStyle(color: style.colors.onPrimary),
            ),
            maxWidth: 210,
            height: 46,
            leading: SvgImage.asset(
              'assets/icons/partner16.svg',
              height: 20,
            ),
            // color: const Color(0xFFCAE8B8),
            onPressed: () => router.vacancy(null, push: true),
          ),
          const SizedBox(height: 15),
          RmbDetector(
            onPressed: c.systemUp,
            child: OutlinedRoundedButton(
              title: Text(
                'Скачать'.l10n,
                // style: TextStyle(color: style.colors.onPrimary),
              ),
              maxWidth: 210,
              height: 46,
              leading: icon,
              onPressed: () => _download(context),
              // color: style.colors.primary,
            ),
          ),

          // OutlinedRoundedButton(
          //   key: const Key('StartButton'),
          //   title: Text('Одноразовый аккаунт'.l10n),
          //   // subtitle: Text('account'.l10n),
          //   // height: 60,
          //   // maxWidth: 210,
          //   // maxWidth: 210,
          //   leading: SvgImage.asset(
          //     // 'assets/icons/one_time13.svg',
          //     // width: 23.5,
          //     // height: 22.78,
          //     'assets/icons/one_time14.svg',
          //     width: 23.91,
          //     height: 22.63,
          //   ),
          //   onPressed: c.register,
          // ),
          if (false) ...[
            if (isWeb) const SizedBox(height: 15),
            RmbDetector(
              onPressed: c.systemUp,
              child: OutlinedRoundedButton(
                subtitle: Text(
                  'Скачать\nприложение'.l10n,
                  style: TextStyle(color: style.colors.onPrimary),
                ),
                height: 53,
                // maxWidth: 210,
                maxWidth: 200,
                leading: icon,
                onPressed: () => _download(context),
                color: style.colors.primary,
              ),
            ),
          ],
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

                    // const SizedBox(height: 15),
                    // if (icon != null) ...[
                    //   // if (isWeb) const SizedBox(height: 15),
                    //   RmbDetector(
                    //     onPressed: c.systemUp,
                    //     child: OutlinedRoundedButton(
                    //       subtitle: Text(
                    //         'Скачать\nприложение'.l10n,
                    //         style: TextStyle(color: style.colors.onPrimary),
                    //       ),
                    //       height: 53,
                    //       // maxWidth: 210,
                    //       maxWidth: 170,
                    //       leading: icon,
                    //       onPressed: () => _download(context),
                    //       color: style.colors.primary,
                    //     ),
                    //   ),
                    //   const SizedBox(height: 15),
                    // ],
                    status,
                    // WidgetButton(
                    //   onPressed: () => _download(context),
                    //   child: SvgImage.asset(
                    //     'assets/icons/get_it_on_google_play.svg',
                    //     height: 45,
                    //   ),
                    // ),
                  ],
                ),
                // Column(
                //   children: [
                //     const Spacer(),
                //     // OutlinedRoundedButton(
                //     //   key: const Key('StartButton'),
                //     //   subtitle: Text(
                //     //     'Одноразовый\nаккаунт'.l10n,
                //     //     style: TextStyle(
                //     //       color: style.colors.onPrimary,
                //     //     ),
                //     //   ),
                //     //   // subtitle: Text('account'.l10n),
                //     //   // height: 60,
                //     //   // maxWidth: 210,
                //     //   // maxWidth: 210,
                //     //   height: 54,
                //     //   maxWidth: 160,
                //     //   color: Color.fromRGBO(126, 198, 113, 1),
                //     //   leading: SvgImage.asset(
                //     //     // 'assets/icons/one_time13.svg',
                //     //     // width: 23.5,
                //     //     // height: 22.78,
                //     //     'assets/icons/one_time15.svg',
                //     //     width: 23.91,
                //     //     height: 22.63,
                //     //   ),

                //     //   onPressed: c.register,
                //     // ),
                //     const SizedBox(height: 100),
                //   ],
                // ),
              ],
            ),
          ),
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
