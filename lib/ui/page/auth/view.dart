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
import 'package:rive/rive.dart' hide LinearGradient;

import '/config.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/login/controller.dart';
import '/ui/page/login/view.dart';
import '/ui/widget/download_button.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';
import 'widget/animated_logo.dart';
import 'widget/cupertino_button.dart';

/// View of the [Routes.auth] page.
class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: AuthController(Get.find()),
      builder: (AuthController c) {
        final Widget status = Column(
          children: [
            const SizedBox(height: 4),
            StyledCupertinoButton(
              label: 'btn_download_application'.l10n,
              onPressed: () => _download(context),
            ),
            const SizedBox(height: 4),
            StyledCupertinoButton(
              padding: const EdgeInsets.all(8),
              label: 'btn_work_with_us'.l10n,
              onPressed: () => router.work(null),
            ),
          ],
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
          Text(
            'Messenger',
            style: style.fonts.displayLargeSecondary,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            'by Gapopa',
            style: style.fonts.displaySmall,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 25),
        ];

        // Footer part of the page.
        List<Widget> footer = [
          const SizedBox(height: 25),
          OutlinedRoundedButton(
            key: const Key('RegisterButton'),
            title: Text('btn_sign_up'.l10n),
            maxWidth: 210,
            height: 46,
            leading: Transform.translate(
              offset: const Offset(3, 0),
              child: const SvgImage.asset(
                'assets/icons/register.svg',
                width: 23,
                height: 23,
              ),
            ),
            onPressed: () => LoginView.show(
              context,
            ),
          ),
          const SizedBox(height: 15),
          OutlinedRoundedButton(
            key: const Key('SignButton'),
            title: Text('btn_sign_in'.l10n),
            maxWidth: 210,
            height: 46,
            leading: Transform.translate(
              offset: const Offset(4, 0),
              child: const SvgImage.asset(
                'assets/icons/enter.svg',
                width: 19.42,
                height: 24,
              ),
            ),
            onPressed: () =>
                LoginView.show(context, initial: LoginViewStage.signIn),
          ),
          const SizedBox(height: 15),
          OutlinedRoundedButton(
            key: const Key('StartButton'),
            subtitle: Text('btn_one_time_account'.l10n),
            maxWidth: 210,
            height: 46,
            maxlines: 2,
            leading: Transform.translate(
              offset: const Offset(4, 0),
              child: const SvgImage.asset(
                'assets/icons/one_time.svg',
                width: 19.88,
                height: 26,
              ),
            ),
            onPressed: c.register,
          ),
          const SizedBox(height: 15),
        ];

        final Widget column = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...header,
            AnimatedLogo(
              key: const ValueKey('Logo'),
              riveAsset: 'assets/images/logo/head.riv',
              onInit: Config.disableInfiniteAnimations
                  ? null
                  : (a) => _setBlink(c, a),
            ),
            ...footer,
          ],
        );

        return Listener(
          key: const Key('AuthView'),
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
                const IgnorePointer(
                  child: SvgImage.asset(
                    'assets/images/background_light.svg',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Expanded(child: Center(child: column)),
                          const SizedBox(height: 8),
                          status,
                        ],
                      ),
                    ),
                  ],
                ),
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
  }

  /// Opens a [ModalPopup] listing the buttons for downloading the application.
  Future<void> _download(BuildContext context) async {
    await ModalPopup.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModalPopupHeader(
            text: 'btn_download'.l10n,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              padding: ModalPopup.padding(context),
              shrinkWrap: true,
              children: const [
                DownloadButton(
                  asset: 'windows',
                  width: 23.93,
                  height: 24,
                  title: 'Windows',
                  link: 'messenger-windows.zip',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: 'apple',
                  width: 21.07,
                  height: 27,
                  title: 'macOS',
                  link: 'messenger-macos.zip',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: 'linux',
                  width: 20.57,
                  height: 24,
                  title: 'Linux',
                  link: 'messenger-linux.zip',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: 'app_store',
                  width: 23,
                  height: 23,
                  title: 'App Store',
                  link: 'messenger-ios.zip',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: 'google',
                  width: 20.33,
                  height: 22.02,
                  title: 'Google Play',
                  link: 'messenger-android.apk',
                ),
                SizedBox(height: 8),
                DownloadButton(
                  asset: 'android',
                  width: 20.99,
                  height: 25,
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
