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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/config.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/language/view.dart';
import '/ui/page/login/controller.dart';
import '/ui/page/login/view.dart';
import '/ui/widget/download_button.dart';
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
    final style = Theme.of(context).style;

    return GetBuilder(
      init: AuthController(Get.find()),
      builder: (AuthController c) {
        final Widget status = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: FittedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        StyledCupertinoButton(
                          label: 'btn_work_with_us'.l10n,
                          style: style.fonts.small.regular.secondary,
                          onPressed: () => router.work(null),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 1,
                          height: 12,
                          color: style.colors.onBackgroundOpacity20,
                        ),
                        if (PlatformUtils.isWeb || !PlatformUtils.isMobile) ...[
                          StyledCupertinoButton(
                            label: 'btn_download'.l10n,
                            style: style.fonts.small.regular.secondary,
                            onPressed: () => _download(context),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            width: 1,
                            height: 12,
                            color: style.colors.onBackgroundOpacity20,
                          ),
                        ],
                        Obx(() {
                          final Language? chosen = L10n.chosen.value;

                          return StyledCupertinoButton(
                            label: 'label_language_entry'.l10nfmt({
                              'code': chosen?.locale.languageCode.toUpperCase(),
                              'name': chosen?.name,
                            }),
                            style: style.fonts.small.regular.secondary,
                            onPressed: () async {
                              await LanguageSelectionView.show(context, null);
                            },
                          );
                        }),
                      ],
                    ),
                    if (Config.copyright.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        Config.copyright,
                        style: style.fonts.small.regular.secondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );

        // Header part of the page.
        //
        // All frames of the animation are drawn in offstage in order to
        // load all the images ahead of animation to reduce the possible
        // flickering.
        List<Widget> header = [
          Text(
            'label_messenger'.l10n,
            style: style.fonts.largest.regular.secondary,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            'label_by_gapopa'.l10n,
            style: style.fonts.large.regular.secondary,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 25),
        ];

        // Footer part of the page.
        List<Widget> footer = [
          const SizedBox(height: 25),
          Obx(() {
            return OutlinedRoundedButton(
              key: const Key('StartButton'),
              maxWidth: 210,
              height: 46,
              leading: Transform.translate(
                offset: const Offset(4, 0),
                child: const SvgIcon(SvgIcons.guest),
              ),
              onPressed: c.authStatus.value.isEmpty ? c.register : () {},
              child: Text('btn_guest'.l10n),
            );
          }),
          const SizedBox(height: 15),
          OutlinedRoundedButton(
            key: const Key('RegisterButton'),
            maxWidth: 210,
            height: 46,
            leading: Transform.translate(
              offset: const Offset(3, 0),
              child: const SvgIcon(SvgIcons.register),
            ),
            onPressed: () => LoginView.show(context),
            child: Text('btn_sign_up'.l10n),
          ),
          const SizedBox(height: 15),
          OutlinedRoundedButton(
            key: const Key('SignInButton'),
            maxWidth: 210,
            height: 46,
            leading: Transform.translate(
              offset: const Offset(4, 0),
              child: const SvgIcon(SvgIcons.enter),
            ),
            onPressed: () =>
                LoginView.show(context, initial: LoginViewStage.signIn),
            child: Text('btn_sign_in'.l10n),
          ),
          const SizedBox(height: 15),
        ];

        final Widget column = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...header,
            Obx(() {
              return AnimatedLogo(
                key: const ValueKey('Logo'),
                index: c.logoFrame.value,
              );
            }),
            ...footer,
          ],
        );

        return Listener(
          key: const Key('AuthView'),
          onPointerDown: (_) => c.animate(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // For web, background color is displayed in `index.html` file.
              if (!PlatformUtils.isWeb)
                IgnorePointer(
                  child: ColoredBox(color: style.colors.background),
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
                        SafeArea(top: false, child: status),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
                DownloadButton.windows(),
                SizedBox(height: 8),
                DownloadButton.macos(),
                SizedBox(height: 8),
                DownloadButton.linux(),
                SizedBox(height: 8),
                DownloadButton.appStore(),
                SizedBox(height: 8),
                DownloadButton.googlePlay(),
                SizedBox(height: 8),
                DownloadButton.android(),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
