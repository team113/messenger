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

        /// Header part of the page.
        ///
        /// All frames of the animation are drawn in offstage in order to
        /// load all the images ahead of animation to reduce the possible
        /// flickering.
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

        /// Animated logo widget.
        Widget logo = LayoutBuilder(builder: (context, constraints) {
          Widget placeholder = SizedBox(
            height: constraints.maxHeight > height
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
                              final machine =
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

        /// Dropdown widget where user can choose application language.
        Widget language = CupertinoButton(
          key: c.languageKey,
          child: Text(
            '${L10n.locales[L10n.chosen]!.countryCode}, ${L10n.languages[L10n.chosen]}',
            style: thin?.copyWith(fontSize: 13, color: primary),
          ),
          onPressed: () {
            if (!context.isMobile) {
              _desktopLanguageModal(c, context);
            } else {
              _mobileLanguageModal(c, context);
            }
          },
        );

        /// Footer part of the page.
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
            onPressed: () async {
              await c.register();
            },
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

  Future<T?> _desktopLanguageModal<T>(AuthController c, BuildContext context) {
    final TextStyle? thin =
        context.textTheme.caption?.copyWith(color: Colors.black);

    Offset offset = Offset.zero;
    final keyContext = c.languageKey.currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox?;
      offset = box?.localToGlobal(Offset.zero) ?? offset;
      offset = Offset(
        offset.dx + (box?.size.width ?? 0) / 2,
        offset.dy,
      );
    }

    return showDialog(
        context: context,
        barrierColor: kCupertinoModalBarrierColor,
        builder: (context) {
          return LayoutBuilder(builder: (context, constraints) {
            final keyContext = c.languageKey.currentContext;
            if (keyContext != null) {
              final box = keyContext.findRenderObject() as RenderBox?;
              offset = box?.localToGlobal(Offset.zero) ?? offset;
              offset = Offset(
                offset.dx + (box?.size.width ?? 0) / 2,
                offset.dy,
              );
            }

            Widget _button(MapEntry<String, String> e) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: Material(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  child: InkWell(
                    hoverColor: const Color(0x3363B4FF),
                    highlightColor: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      L10n.chosen = e.key;
                      Get.updateLocale(L10n.locales[L10n.chosen]!);
                    },
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Text(
                              e.value,
                              style: thin?.copyWith(
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              L10n.locales[e.key]!.languageCode.toUpperCase(),
                              style: thin?.copyWith(
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Stack(
              children: [
                Positioned(
                  left: offset.dx - 260 / 2,
                  bottom: MediaQuery.of(context).size.height - offset.dy,
                  child: Listener(
                    onPointerUp: (d) {
                      Navigator.of(context).pop();
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 260,
                          constraints: const BoxConstraints(maxHeight: 280),
                          padding: const EdgeInsets.fromLTRB(
                            0,
                            10,
                            0,
                            10,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBackground
                                .resolveFrom(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              SingleChildScrollView(
                                child: Column(
                                  children: L10n.languages.entries
                                      .map(_button)
                                      .toList(),
                                ),
                              ),
                              if (L10n.languages.length >= 8)
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      height: 15,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFFFFFFFF),
                                            Color(0x00FFFFFF),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (L10n.languages.length >= 8)
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      height: 15,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0x00FFFFFF),
                                            Color(0xFFFFFFFF),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          });
        });
  }

  Future<T?> _mobileLanguageModal<T>(AuthController c, BuildContext context) {
    final TextStyle? thin = context.textTheme.caption
        ?.copyWith(color: Theme.of(context).colorScheme.primary);

    return showModalBottomSheet(
      context: context,
      barrierColor: kCupertinoModalBarrierColor,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      builder: (context) {
        return Container(
          height: min(L10n.languages.length * (65), 330),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCCCCC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Stack(
                      children: [
                        CupertinoPicker(
                          magnification: 1,
                          squeeze: 1,
                          looping: true,
                          diameterRatio: 100,
                          useMagnifier: false,
                          itemExtent: 38,
                          selectionOverlay: Container(
                            margin: const EdgeInsetsDirectional.only(
                                start: 8, end: 8),
                            decoration:
                                const BoxDecoration(color: Color(0x3363B4FF)),
                          ),
                          onSelectedItemChanged: (int i) {
                            if (!PlatformUtils.isIOS) {
                              HapticFeedback.selectionClick();
                            }
                            c.selectedLanguage.value = i;
                          },
                          children: L10n.languages.entries.map((e) {
                            return Center(
                              child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(46, 0, 29, 0),
                                child: Row(
                                  children: [
                                    Text(
                                      e.value,
                                      style: thin?.copyWith(
                                        fontSize: 15,
                                        color: const Color(0xFF000000),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      L10n.locales[e.key]!.languageCode
                                          .toUpperCase(),
                                      style: thin?.copyWith(
                                        fontSize: 15,
                                        color: const Color(0xFF000000),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 15,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0x00FFFFFF),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 15,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x00FFFFFF),
                                  Color(0xFFFFFFFF),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
