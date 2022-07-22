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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/login/view.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of the [Routes.auth] page.
class AuthView extends StatelessWidget {
  const AuthView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: AuthController(Get.find()),
      builder: (AuthController c) => Obx(
        () {
          if (c.authStatus.value.isEmpty) {
            bool isWeb = PlatformUtils.isWeb;
            bool isAndroidWeb = isWeb && PlatformUtils.isAndroid;
            bool isIosWeb = isWeb && PlatformUtils.isIOS;
            bool isDesktopWeb = isWeb && PlatformUtils.isDesktop;

            /// Header part of the page.
            ///
            /// All frames of the animation are drawn in offstage in order to
            /// load all the images ahead of animation to reduce the possible
            /// flickering.
            List<Widget> header = [
              ...List.generate(10, (i) => 'assets/images/logo/logo000$i.svg')
                  .map((e) => Offstage(child: SvgLoader.asset(e)))
                  .toList(),
              ...List.generate(10, (i) => 'assets/images/logo/head000$i.svg')
                  .map((e) => Offstage(child: SvgLoader.asset(e)))
                  .toList(),
              const SizedBox(height: 30),
              Text(
                'Messenger',
                style: context.textTheme.headline3,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                'by Gapopa',
                style: context.textTheme.headline5,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 25),
            ];

            /// Animated logo widget.
            Widget logo = LayoutBuilder(builder: (context, constraints) {
              return Obx(() {
                Widget placeholder = SizedBox(
                  height: constraints.maxHeight > 350
                      ? 350
                      : constraints.maxHeight <= 160
                          ? 160
                          : 350,
                  child: const Center(child: CircularProgressIndicator()),
                );

                return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: AnimatedSize(
                      curve: Curves.ease,
                      duration: const Duration(milliseconds: 200),
                      child: SizedBox(
                        height: constraints.maxHeight >= 350 ? 350 : 160,
                        child: constraints.maxHeight >= 350
                            ? Container(
                                key: const ValueKey('logo'),
                                child: SvgLoader.asset(
                                  'assets/images/logo/logo000${c.logoFrame.value}.svg',
                                  placeholderBuilder: (context) => placeholder,
                                  height: 350,
                                ),
                              )
                            : SvgLoader.asset(
                                'assets/images/logo/head000${c.logoFrame.value}.svg',
                                placeholderBuilder: (context) => placeholder,
                                height: 160,
                              ),
                      ),
                    ));
              });
            });

            /// Dropdown widget where user can choose application language.
            Widget language = Obx(
              () => DropdownButton<Language>(
                key: const Key('LocalizationDropdown'),
                value: L10n.chosen.value,
                items: L10n.languages.map<DropdownMenuItem<Language>>((e) {
                  return DropdownMenuItem(
                    key: Key(e.toString()),
                    value: e,
                    child: Text('${e.locale.countryCode}, ${e.name}'),
                  );
                }).toList(),
                onChanged: (d) => L10n.set(d!),
                borderRadius: BorderRadius.circular(18),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 15,
                ),
                icon: const SizedBox(),
                underline: const SizedBox(),
              ),
            );

            /// Footer part of the page.
            List<Widget> footer = [
              const SizedBox(height: 25),
              OutlinedRoundedButton(
                key: const Key('StartChattingButton'),
                title: Text(
                  'btn_start_chatting'.l10n,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'label_no_registration'.l10n,
                  style: const TextStyle(color: Colors.white),
                ),
                leading: SvgLoader.asset('assets/icons/start.svg', width: 25),
                onPressed: c.register,
                gradient: const LinearGradient(
                  colors: [Color(0xFF03A803), Color(0xFF20CD66)],
                ),
              ),
              const SizedBox(height: 10),
              OutlinedRoundedButton(
                key: const Key('SignInButton'),
                title: Text('btn_login'.l10n),
                subtitle: Text('label_or_register'.l10n),
                leading: SvgLoader.asset('assets/icons/sign_in.svg', width: 20),
                onPressed: () => LoginView.show(context),
              ),
              const SizedBox(height: 10),
              if (isIosWeb)
                OutlinedRoundedButton(
                  title: Text('btn_download'.l10n),
                  subtitle: const Text('App Store'),
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: SvgLoader.asset('assets/icons/apple.svg', width: 22),
                  ),
                  onPressed: () {},
                ),
              if (isAndroidWeb)
                OutlinedRoundedButton(
                  title: Text('btn_download'.l10n),
                  subtitle: const Text('Google Play'),
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child:
                        SvgLoader.asset('assets/icons/google.svg', width: 22),
                  ),
                  onPressed: () {},
                ),
              if (isDesktopWeb)
                OutlinedRoundedButton(
                  title: Text('btn_download'.l10n),
                  subtitle: Text('label_application'.l10n),
                  leading: PlatformUtils.isMacOS
                      ? SvgLoader.asset('assets/icons/apple.svg', width: 22)
                      : (PlatformUtils.isWindows)
                          ? SvgLoader.asset('assets/icons/windows.svg',
                              width: 22)
                          : (PlatformUtils.isLinux)
                              ? SvgLoader.asset('assets/icons/linux.svg',
                                  width: 22)
                              : null,
                  onPressed: () {},
                ),
              const SizedBox(height: 20),
              if (isWeb) language,
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
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}
