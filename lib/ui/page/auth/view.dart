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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/page/user/controller.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/web/web_utils.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
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
            const SizedBox(height: 4),
            StyledCupertinoButton(
              label: 'btn_download_application'.l10n,
              style: style.fonts.normal.regular.primary,
              onPressed: () async {
                await WebUtils.launchScheme('/work/freelance');
                if (context.mounted) {
                  await _download(context);
                }
              },
              // onPressed: () => _download(context),
            ),
            const SizedBox(height: 4),
            StyledCupertinoButton(
              padding: const EdgeInsets.all(8),
              label: 'btn_work_with_us'.l10n,
              style: style.fonts.small.regular.primary,
              onPressed: () => router.work(null),
            ),
            const SizedBox(height: 8),
          ],
        );

        // Header part of the page.
        //
        // All frames of the animation are drawn in offstage in order to
        // load all the images ahead of animation to reduce the possible
        // flickering.
        List<Widget> header = [
          Text(
            'Messenger',
            style: style.fonts.largest.regular.secondary,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            'by Gapopa',
            style: style.fonts.large.regular.secondary,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 25),
        ];

        return Obx(() {
          final List<Widget> footer;

          switch (c.screen.value) {
            case AuthScreen.accounts:
              final Iterable<Widget> accounts = c.accounts.mapIndexed((i, e) {
                final bool expired = i >= 2;

                return Padding(
                  padding: ModalPopup.padding(context),
                  child: ContactTile(
                    myUser: e.myUser,
                    onTap: () async {
                      if (expired) {
                        await LoginView.show(
                          context,
                          initial: LoginViewStage.signIn,
                        );
                      } else {
                        c.signInAs(e);
                      }
                    },
                    trailing: [
                      AnimatedButton(
                        decorator: (child) => Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
                          child: child,
                        ),
                        onPressed: () async {
                          final result = await MessagePopup.alert(
                            'btn_logout'.l10n,
                            description: [
                              TextSpan(
                                style: style.fonts.medium.regular.secondary,
                                children: [
                                  TextSpan(
                                    text: 'alert_are_you_sure_want_to_log_out1'
                                        .l10n,
                                  ),
                                  TextSpan(
                                    style:
                                        style.fonts.medium.regular.onBackground,
                                    text: e.myUser.name?.val ??
                                        e.myUser.num.toString(),
                                  ),
                                  TextSpan(
                                    text: 'alert_are_you_sure_want_to_log_out2'
                                        .l10n,
                                  ),
                                  if (!e.myUser.hasPassword) ...[
                                    const TextSpan(text: '\n\n'),
                                    TextSpan(
                                      text:
                                          'Пароль не задан. Доступ к аккаунту может быть утерян безвозвратно.'
                                              .l10n,
                                    ),
                                  ],
                                  if (e.myUser.emails.confirmed.isEmpty) ...[
                                    const TextSpan(text: '\n\n'),
                                    TextSpan(
                                      text:
                                          'E-mail или номер телефона не задан. Восстановление доступа к аккаунту невозможно.'
                                              .l10n,
                                    ),
                                  ],
                                ],
                              )
                            ],
                          );

                          if (result == true) {
                            await c.delete(e);

                            if (c.accounts.isEmpty) {
                              c.screen.value = AuthScreen.signIn;
                            }
                          }
                        },
                        child: const SvgIcon(SvgIcons.delete19),
                      ),
                    ],
                    subtitle: [
                      const SizedBox(height: 5),
                      if (expired)
                        Text(
                          'label_sign_in_required'.l10n,
                          style: style.fonts.small.regular.danger,
                        )
                      else
                        Text(
                          DateTime.now().toDifferenceAgo(),
                          style: style.fonts.small.regular.secondary,
                        ),
                    ],
                  ),
                );
              });

              footer = [
                const SizedBox(height: 25),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      ...accounts,
                      const SizedBox(height: 10),
                      Padding(
                        padding: ModalPopup.padding(context),
                        child: PrimaryButton(
                          onPressed: () async {
                            await LoginView.show(
                              context,
                              initial: LoginViewStage.signUpOrSignIn,
                            );
                          },
                          title: 'Add account'.l10n,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ];
              break;

            case AuthScreen.signIn:
              footer = [
                const SizedBox(height: 25),
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
                OutlinedRoundedButton(
                  key: const Key('StartButton'),
                  maxWidth: 210,
                  height: 46,
                  leading: Transform.translate(
                    offset: const Offset(4, 0),
                    child: const SvgIcon(SvgIcons.guest),
                  ),
                  onPressed: c.register,
                  child: Text('btn_guest'.l10n),
                ),
                const SizedBox(height: 15),
              ];
              break;
          }

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
                          status,
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
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
