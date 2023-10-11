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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/config.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/cupertino_button.dart';
import 'package:messenger/ui/page/call/widget/conditional_backdrop.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/navigation_bar.dart';
import 'package:messenger/ui/page/home/widget/wallet.dart';
import 'package:messenger/ui/page/login/widget/sign_button.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/menu_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/platform_utils.dart';

import 'controller.dart';

/// Widgets view of the [Routes.style] page.
class IconsView extends StatefulWidget {
  const IconsView({super.key, this.inverted = false});

  /// Indicator whether this view should have its colors inverted.
  final bool inverted;

  @override
  State<IconsView> createState() => _WidgetsViewState();
}

class _WidgetsViewState extends State<IconsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: IconsController(),
      builder: (IconsController c) {
        final List<Widget> children = [
          Block(
            color: style.colors.primaryDark,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _downloadableIcon(
                    context,
                    c,
                    icon: 'iOS.png',
                    archive: 'iOS',
                  ),
                  _downloadableIcon(
                    context,
                    c,
                    icon: 'macOS.png',
                    archive: 'macOS',
                  ),
                  _downloadableIcon(
                    context,
                    c,
                    icon: 'windows.ico',
                    archive: 'windows',
                  ),
                  _downloadableIcon(
                    context,
                    c,
                    icon: 'android.png',
                    archive: 'android',
                  ),
                  _downloadableIcon(
                    context,
                    c,
                    icon: 'web.png',
                    archive: 'web',
                    mini: true,
                  ),
                  _downloadableIcon(
                    context,
                    c,
                    icon: 'alert.png',
                    archive: 'alert',
                    mini: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Block(
            children: [
              _appBar(
                context,
                trailing: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.chat.asset),
                    child: Transform.translate(
                      offset: const Offset(0, 1),
                      child: const SvgIcon(SvgIcons.chat),
                    ),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () => c.icon.value =
                        IconDetails(SvgIcons.chatVideoCall.asset),
                    child: const SvgIcon(SvgIcons.chatVideoCall),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () => c.icon.value =
                        IconDetails(SvgIcons.chatAudioCall.asset),
                    child: const SvgIcon(SvgIcons.chatAudioCall),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _appBar(
                context,
                trailing: [
                  AnimatedButton(
                    onPressed: () => c.icon.value = IconDetails(
                      SvgIcons.callEnd.asset,
                      invert: true,
                    ),
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: style.colors.dangerColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SvgIcon(SvgIcons.callEnd),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () => c.icon.value = IconDetails(
                      SvgIcons.callStart.asset,
                      invert: true,
                    ),
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: style.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SvgIcon(SvgIcons.callStart),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _appBar(
                context,
                trailing: [
                  AnimatedButton(
                    onPressed: () => c.icon.value = IconDetails(
                      SvgIcons.callEndSmall.asset,
                      invert: true,
                    ),
                    child: Container(
                      height: 22,
                      width: 22,
                      decoration: BoxDecoration(
                        color: style.colors.dangerColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SvgIcon(SvgIcons.callEndSmall),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () => c.icon.value = IconDetails(
                      SvgIcons.callStartSmall.asset,
                      invert: true,
                    ),
                    child: Container(
                      height: 22,
                      width: 22,
                      decoration: BoxDecoration(
                        color: style.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SvgIcon(SvgIcons.callStartSmall),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _appBar(
                context,
                leading: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.home.asset),
                    child: const SvgIcon(SvgIcons.home),
                  ),
                ],
                trailing: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.shareThick.asset),
                    child: const SvgIcon(SvgIcons.shareThick),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.copyThick.asset),
                    child: const SvgIcon(SvgIcons.copyThick),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _appBar(
                context,
                leading: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.search.asset),
                    child: const SvgIcon(SvgIcons.search),
                  ),
                ],
                trailing: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.closePrimary.asset),
                    child: const SvgIcon(SvgIcons.closePrimary),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () => c.icon.value =
                        IconDetails(SvgIcons.contactsSwitch.asset),
                    child: const SvgIcon(SvgIcons.contactsSwitch),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.chatsSwitch.asset),
                    child: const SvgIcon(SvgIcons.chatsSwitch),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _appBar(
                context,
                trailing: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.searchExit.asset),
                    child: const SvgIcon(SvgIcons.searchExit),
                  ),
                ],
              ),
            ],
          ),
          Block(
            children: [
              SignButton(
                icon: const SvgIcon(SvgIcons.register),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.register.asset),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.enter),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.enter.asset),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.oneTime),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.oneTime.asset),
              ),

              //
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.email),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.email.asset),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.phone),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.phone.asset),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.password),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.password.asset),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.qrCode),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.qrCode.asset),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.google),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.google.asset),
              ),

              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.github),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.github.asset),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.apple),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.apple.asset),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.windows),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.windows.asset),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.linux),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.linux.asset),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.appStore),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.appStore.asset),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.googlePlay),
                text: '',
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.googlePlay.asset),
              ),
              const SizedBox(height: 8),
              SignButton(
                  icon: const SvgIcon(SvgIcons.android),
                  text: '',
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.android.asset)),
            ],
          ),
          Block(
            children: [
              ReactiveTextField(
                state: TextFieldState(),
                onSuffixPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.visibleOff.asset),
                readOnly: true,
                trailing: const SvgIcon(SvgIcons.visibleOff),
              ),
              const SizedBox(height: 8),
              ReactiveTextField(
                state: TextFieldState(),
                onSuffixPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.visibleOn.asset),
                readOnly: true,
                trailing: const SvgIcon(SvgIcons.visibleOn),
              ),
              const SizedBox(height: 8),
              ReactiveTextField(
                state: TextFieldState(),
                onSuffixPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.copy.asset),
                readOnly: true,
                trailing: const SvgIcon(SvgIcons.copy),
              ),
              const SizedBox(height: 8),
              ReactiveTextField(
                state: TextFieldState(),
                onSuffixPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.share.asset),
                readOnly: true,
                trailing: const SvgIcon(SvgIcons.share),
              ),
            ],
          ),
          Block(
            children: [
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.rust.asset),
                  child: const SvgIcon(SvgIcons.rust),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                inverted: true,
                leading: AnimatedButton(
                  onPressed: () => c.icon.value =
                      IconDetails(SvgIcons.rustWhite.asset, invert: true),
                  child: const SvgIcon(SvgIcons.rustWhite),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () => c.icon.value = IconDetails('frontend.svg'),
                  child: const SvgImage.asset(
                    'assets/icons/frontend.svg',
                    width: 25.87,
                    height: 32,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                inverted: true,
                leading: AnimatedButton(
                  onPressed: () => c.icon.value = IconDetails(
                    'frontend_white.svg',
                    invert: true,
                  ),
                  child: const SvgImage.asset(
                    'assets/icons/frontend_white.svg',
                    width: 25.87,
                    height: 32,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () => c.icon.value = IconDetails('freelance.svg'),
                  child: const SvgImage.asset(
                    'assets/icons/freelance.svg',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                inverted: true,
                leading: AnimatedButton(
                  onPressed: () => c.icon.value = IconDetails(
                    'freelance_white.svg',
                    invert: true,
                  ),
                  child: const SvgImage.asset(
                    'assets/icons/freelance_white.svg',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
            ],
          ),
          Block(
            children: [
              _navBar(
                context,
                [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails('wallet_closed1.svg'),
                    child: const WalletWidget(
                      balance: 0,
                      visible: true,
                    ),
                  ),
                  AnimatedButton(
                    onPressed: () => c.icon.value = IconDetails('wallet.svg'),
                    child: const WalletWidget(
                      balance: 1000,
                      visible: true,
                    ),
                  ),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails('wallet_opened1.svg'),
                    child: const WalletWidget(
                      balance: 1000,
                      visible: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _navBar(
                context,
                [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.partner.asset),
                    child: const SvgIcon(SvgIcons.partner),
                  ),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.publicsMuted.asset),
                    child: const SvgIcon(SvgIcons.publicsMuted),
                  ),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.publics.asset),
                    child: const SvgIcon(SvgIcons.publics),
                  ),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.chatsMuted.asset),
                    child: const SvgIcon(SvgIcons.chatsMuted),
                  ),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.chats.asset),
                    child: const SvgIcon(SvgIcons.chats),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 120),
        ];

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ListView(
                controller: _scrollController,
                children: children,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Obx(() {
                if (c.icon.value == null) {
                  return const SizedBox();
                }

                final String? asset = c.icon.value?.asset;
                final String? download =
                    c.icon.value?.download ?? c.icon.value?.asset;
                final bool invert = c.icon.value?.invert == true;

                return Container(
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  decoration: BoxDecoration(
                    borderRadius: style.cardRadius,
                    boxShadow: [
                      CustomBoxShadow(
                        blurRadius: 8,
                        color: style.colors.onBackgroundOpacity13,
                        blurStyle: BlurStyle.outer,
                      ),
                    ],
                  ),
                  child: ConditionalBackdropFilter(
                    condition: style.cardBlur > 0,
                    borderRadius: style.cardRadius,
                    filter: ImageFilter.blur(
                      sigmaX: style.cardBlur,
                      sigmaY: style.cardBlur,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            invert ? style.colors.primaryDark : style.cardColor,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: asset?.endsWith('.svg') == true
                                ? SvgImage.asset(
                                    'assets/icons/$asset',
                                    width: 16,
                                    height: 16,
                                  )
                                : Image.asset(
                                    'assets/icons/$asset',
                                    width: 16,
                                    height: 16,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$asset',
                                  style: invert
                                      ? style.fonts.labelLargeOnPrimary
                                      : style.fonts.labelLarge,
                                ),
                              ],
                            ),
                          ),
                          SelectionContainer.disabled(
                            child: StyledCupertinoButton(
                              label: 'Download',
                              onPressed: () async {
                                final file = await PlatformUtils.saveTo(
                                  '${Config.origin}/assets/assets/icons/$download',
                                );

                                if (file != null) {
                                  MessagePopup.success('$asset downloaded');
                                }
                              },
                              style: style.fonts.labelMediumPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _appBar(
    BuildContext context, {
    List<Widget> children = const [],
    List<Widget> leading = const [],
    List<Widget> trailing = const [],
  }) {
    return SizedBox(
      height: CustomAppBar.height,
      child: CustomAppBar(
        leading: leading,
        actions: trailing,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  Widget _downloadableIcon(
    BuildContext context,
    IconsController c, {
    required String icon,
    required String archive,
    bool mini = false,
  }) {
    return AnimatedButton(
      onPressed: () => c.icon.value = IconDetails(
        'application/$icon',
        invert: true,
        download: 'application/$archive.zip',
      ),
      child: Image.asset(
        'assets/icons/application/$icon',
        width: mini ? 32 : 64,
        height: mini ? 32 : 64,
      ),
    );
  }
}

Widget _navBar(BuildContext context, List<Widget> children) {
  final style = Theme.of(context).style;

  return Container(
    decoration: BoxDecoration(
      color: style.cardColor,
      boxShadow: [
        CustomBoxShadow(
          blurRadius: 8,
          color: style.colors.onBackgroundOpacity13,
          blurStyle: BlurStyle.outer,
        ),
      ],
      borderRadius: style.cardRadius,
      border: style.cardBorder,
    ),
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
    height: CustomNavigationBar.height,
    child: SelectionContainer.disabled(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: children,
      ),
    ),
  );
}
