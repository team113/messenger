// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/auth/selector/view.dart';
import 'package:rive/rive.dart' hide LinearGradient;

import '/l10n/_l10n.dart';
import '/routes.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/outlined_rounded_button.dart';

/// View of the [Routes.auth] page.
class AuthView extends StatelessWidget {
  const AuthView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: AuthController(Get.find()),
      builder: (AuthController c) {
        bool isWeb = PlatformUtils.isWeb;
        bool isAndroidWeb = isWeb && PlatformUtils.isAndroid;
        bool isIosWeb = isWeb && PlatformUtils.isIOS;
        bool isDesktopWeb = isWeb && PlatformUtils.isDesktop;

        final TextStyle? thin =
            context.textTheme.caption?.copyWith(color: Colors.black);
        final Color primary = Theme.of(context).colorScheme.primary;

        // Header part of the page.
        //
        // All frames of the animation are drawn in offstage in order to
        // load all the images ahead of animation to reduce the possible
        // flickering.
        List<Widget> header = [
          ...List.generate(10, (i) => 'assets/images/logo/logo000$i.svg')
              .map((e) => Offstage(child: SvgLoader.asset(e)))
              .toList(),
          ...List.generate(10, (i) => 'assets/images/logo/logo000$i.svg')
              .map((e) => Offstage(child: SvgLoader.asset(e)))
              .toList(),
          const SizedBox(height: 30),
          Text(
            'Messenger',
            style: thin?.copyWith(fontSize: 24, color: primary),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            'by Gapopa',
            style: thin?.copyWith(fontSize: 15.4, color: primary),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 25),
        ];

        const double height = 250;

        // Animated logo widget.
        Widget logo = LayoutBuilder(builder: (context, constraints) {
          Widget placeholder = SizedBox(
            height: constraints.maxHeight > 250
                ? height
                : constraints.maxHeight <= 140
                    ? 140
                    : height,
            child: const Center(child: CircularProgressIndicator()),
          );

          return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 350),
              child: AnimatedSize(
                curve: Curves.ease,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  height: constraints.maxHeight >= height ? height : 140,
                  child: constraints.maxHeight >= height
                      ? Container(
                          key: const ValueKey('logo'),
                          child: RiveAnimation.asset(
                            'assets/images/logo/logo.riv',
                            onInit: (a) {
                              final StateMachineController? machine =
                                  StateMachineController.fromArtboard(
                                      a, 'Machine');
                              a.addController(machine!);
                              c.blink = machine.findInput<bool>('blink')
                                  as SMITrigger?;

                              Future.delayed(
                                const Duration(milliseconds: 500),
                                c.animate,
                              );
                            },
                          ),
                        )
                      : Obx(() {
                          return SvgLoader.asset(
                            'assets/images/logo/head000${c.logoFrame.value}.svg',
                            placeholderBuilder: (context) => placeholder,
                            height: 140,
                          );
                        }),
                ),
              ));
        });

        // Language selection dropdown.
        Widget language = CupertinoButton(
            key: c.languageKey,
            child: Text(
              '${L10n.locales[L10n.chosen]!.countryCode}, ${L10n.languages[L10n.chosen]}',
              style: thin?.copyWith(fontSize: 13, color: primary),
            ),
            onPressed: () async {
              await Selector.show(context, c.languageKey, {});
            });

        // Footer part of the page.
        List<Widget> footer = [
          const SizedBox(height: 25),
          OutlinedRoundedButton(
            key: const Key('StartChattingButton'),
            title: Text(
              'btn_start'.tr,
              style: const TextStyle(color: Colors.white),
            ),
            leading: Container(
              child: SvgLoader.asset(
                'assets/icons/start.svg',
                width: 25 * 0.7,
              ),
            ),
            onPressed: c.register,
            // color: Colors.red,
            color: const Color(0xFF63B4FF),
          ),
          const SizedBox(height: 15),
          OutlinedRoundedButton(
            key: const Key('SignInButton'),
            title: Text('btn_login'.tr),
            leading: SvgLoader.asset(
              'assets/icons/sign_in.svg',
              width: 20 * 0.7,
            ),
            onPressed: router.login,
          ),
          const SizedBox(height: 15),
          if (isIosWeb)
            OutlinedRoundedButton(
              title: Text('btn_download'.tr),
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 3 * 0.7),
                child: SvgLoader.asset(
                  'assets/icons/apple.svg',
                  width: 22 * 0.7,
                ),
              ),
              onPressed: () {},
            ),
          if (isAndroidWeb)
            OutlinedRoundedButton(
              title: Text('btn_download'.tr),
              leading: Padding(
                padding: const EdgeInsets.only(left: 2 * 0.7),
                child: SvgLoader.asset(
                  'assets/icons/google.svg',
                  width: 22 * 0.7,
                ),
              ),
              onPressed: () {},
            ),
          if (isDesktopWeb)
            OutlinedRoundedButton(
              title: Text('btn_download'.tr),
              leading: PlatformUtils.isMacOS
                  ? SvgLoader.asset(
                      'assets/icons/apple.svg',
                      width: 22 * 0.7,
                    )
                  : (PlatformUtils.isWindows)
                      ? SvgLoader.asset(
                          'assets/icons/windows.svg',
                          width: 22 * 0.7,
                        )
                      : (PlatformUtils.isLinux)
                          ? SvgLoader.asset(
                              'assets/icons/linux.svg',
                              width: 22 * 0.7,
                            )
                          : null,
              onPressed: () {},
            ),
          const SizedBox(height: 20),
          language,
        ];

        return Stack(
          key: const Key('AuthView'),
          children: [
            IgnorePointer(
              child: SvgLoader.asset(
                'assets/images/background_light.svg',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            GestureDetector(
              onTap: c.animate,
              child: Scaffold(
                backgroundColor: Colors.transparent,
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
                            ...header,
                            Flexible(child: logo),
                            ...footer,
                            SizedBox(
                              height: MediaQuery.of(context).viewPadding.bottom,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
