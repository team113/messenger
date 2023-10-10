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
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/unread_counter.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/navigation_bar.dart';
import 'package:messenger/ui/page/home/widget/safe_scrollbar.dart';
import 'package:messenger/ui/page/home/widget/wallet.dart';
import 'package:messenger/ui/page/login/widget/sign_button.dart';
import 'package:messenger/ui/page/work/widget/vacancy_button.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/menu_button.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
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
                        c.icon.value = const IconDetails('chat.svg'),
                    child: Transform.translate(
                      offset: const Offset(0, 1),
                      child: const SvgImage.asset(
                        'assets/icons/chat.svg',
                        width: 20.12,
                        height: 21.62,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('chat_video_call.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/chat_video_call.svg',
                      height: 17,
                    ),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('chat_audio_call.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/chat_audio_call.svg',
                      height: 19,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _appBar(
                context,
                trailing: [
                  AnimatedButton(
                    onPressed: () => c.icon.value = const IconDetails(
                      'call_end.svg',
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
                        child: SvgImage.asset(
                          'assets/icons/call_end.svg',
                          width: 20.55,
                          height: 8.53,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () => c.icon.value = const IconDetails(
                      'call_start.svg',
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
                        child: SvgImage.asset(
                          'assets/icons/call_start.svg',
                          width: 15,
                          height: 15,
                        ),
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
                        c.icon.value = const IconDetails('home.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/home.svg',
                      width: 21.8,
                      height: 21.04,
                    ),
                  ),
                ],
                trailing: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('share_thick.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/share_thick.svg',
                      width: 17.54,
                      height: 18.36,
                    ),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('copy_thick.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/copy_thick.svg',
                      width: 16.18,
                      height: 18.8,
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
                        c.icon.value = const IconDetails('search.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/search.svg',
                      width: 17.77,
                    ),
                  ),
                ],
                trailing: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('close_primary.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/close_primary.svg',
                      height: 15,
                    ),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('contacts_switch.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/contacts_switch.svg',
                      width: 22.4,
                      height: 20.8,
                    ),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('chats_switch.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/chats_switch.svg',
                      width: 22.4,
                      height: 20.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _appBar(
                context,
                trailing: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('search_exit.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/search_exit.svg',
                      height: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Block(
            children: [
              SignButton(
                asset: 'register',
                assetWidth: 23,
                assetHeight: 23,
                text: '',
                onPressed: () =>
                    c.icon.value = const IconDetails('register.svg'),
              ),
              const SizedBox(height: 8),
              SignButton(
                asset: 'enter',
                assetWidth: 19.42,
                assetHeight: 24,
                text: '',
                onPressed: () => c.icon.value = const IconDetails('enter.svg'),
              ),
              const SizedBox(height: 8),
              SignButton(
                asset: 'one_time',
                assetWidth: 19.88,
                assetHeight: 26,
                text: '',
                onPressed: () =>
                    c.icon.value = const IconDetails('one_time.svg'),
              ),

              //
              const SizedBox(height: 8),
              SignButton(
                asset: 'email',
                assetWidth: 21.93,
                assetHeight: 22.5,
                text: '',
                onPressed: () => c.icon.value = const IconDetails('email.svg'),
              ),
              const SizedBox(height: 8),
              SignButton(
                asset: 'phone6',
                assetWidth: 17.61,
                assetHeight: 25,
                text: '',
                onPressed: () => c.icon.value = const IconDetails('phone6.svg'),
              ),
              const SizedBox(height: 8),
              SignButton(
                asset: 'password2',
                assetWidth: 19,
                assetHeight: 21,
                text: '',
                onPressed: () =>
                    c.icon.value = const IconDetails('password2.svg'),
              ),
              const SizedBox(height: 8),
              SignButton(
                asset: 'qr_code2',
                assetWidth: 20,
                assetHeight: 20,
                text: '',
                onPressed: () =>
                    c.icon.value = const IconDetails('qr_code2.svg'),
              ),
              const SizedBox(height: 8),
              SignButton(
                asset: 'google_logo1',
                assetWidth: 21.56,
                assetHeight: 22,
                text: '',
                onPressed: () =>
                    c.icon.value = const IconDetails('google_logo1.svg'),
              ),

              const SizedBox(height: 8),
              SignButton(
                asset: 'github1',
                assetHeight: 26,
                assetWidth: 26,
                text: '',
                onPressed: () =>
                    c.icon.value = const IconDetails('github1.svg'),
              ),
              const SizedBox(height: 8),
              SignButton(
                asset: 'apple',
                assetWidth: 21.07,
                assetHeight: 27,
                text: '',
                onPressed: () => c.icon.value = const IconDetails('apple.svg'),
              ),
              const SizedBox(height: 8),
              SignButton(
                asset: 'windows',
                assetWidth: 23.93,
                assetHeight: 24,
                text: '',
                onPressed: () =>
                    c.icon.value = const IconDetails('windows.svg'),
              ),
              const SizedBox(height: 8),
              SignButton(
                asset: 'linux',
                assetWidth: 20.57,
                assetHeight: 24,
                text: '',
                onPressed: () => c.icon.value = const IconDetails('linux.svg'),
              ),
              const SizedBox(height: 8),
              SignButton(
                asset: 'app_store',
                assetWidth: 23,
                assetHeight: 23,
                text: '',
                onPressed: () =>
                    c.icon.value = const IconDetails('app_store.svg'),
              ),
              const SizedBox(height: 8),
              SignButton(
                asset: 'google',
                assetWidth: 20.33,
                assetHeight: 22.02,
                text: '',
                onPressed: () => c.icon.value = const IconDetails('google.svg'),
              ),
              const SizedBox(height: 8),
              SignButton(
                asset: 'android',
                assetWidth: 20.99,
                assetHeight: 25,
                text: '',
                onPressed: () =>
                    c.icon.value = const IconDetails('android.svg'),
              ),
            ],
          ),
          Block(
            children: [
              ReactiveTextField(
                state: TextFieldState(),
                onSuffixPressed: () =>
                    c.icon.value = const IconDetails('visible_off.svg'),
                readOnly: true,
                trailing: const SvgImage.asset(
                  'assets/icons/visible_off.svg',
                  width: 17.07,
                ),
              ),
              const SizedBox(height: 8),
              ReactiveTextField(
                state: TextFieldState(),
                onSuffixPressed: () =>
                    c.icon.value = const IconDetails('visible_on.svg'),
                readOnly: true,
                trailing: const SvgImage.asset(
                  'assets/icons/visible_on.svg',
                  width: 17.07,
                ),
              ),
              const SizedBox(height: 8),
              ReactiveTextField(
                state: TextFieldState(),
                onSuffixPressed: () =>
                    c.icon.value = const IconDetails('copy.svg'),
                readOnly: true,
                trailing: const SvgImage.asset(
                  'assets/icons/copy.svg',
                  height: 17,
                ),
              ),
              const SizedBox(height: 8),
              ReactiveTextField(
                state: TextFieldState(),
                onSuffixPressed: () =>
                    c.icon.value = const IconDetails('share.svg'),
                readOnly: true,
                trailing: const SvgImage.asset(
                  'assets/icons/share.svg',
                  height: 17,
                ),
              ),
            ],
          ),
          Block(
            children: [
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () => c.icon.value = const IconDetails('rust.svg'),
                  child: const SvgImage.asset(
                    'assets/icons/rust.svg',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                inverted: true,
                leading: AnimatedButton(
                  onPressed: () => c.icon.value = const IconDetails(
                    'rust_white.svg',
                    invert: true,
                  ),
                  child: const SvgImage.asset(
                    'assets/icons/rust_white.svg',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = const IconDetails('frontend.svg'),
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
                  onPressed: () => c.icon.value = const IconDetails(
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
                  onPressed: () =>
                      c.icon.value = const IconDetails('freelance.svg'),
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
                  onPressed: () => c.icon.value = const IconDetails(
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
                        c.icon.value = const IconDetails('wallet_closed1.svg'),
                    child: const WalletWidget(
                      balance: 0,
                      visible: true,
                    ),
                  ),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('wallet.svg'),
                    child: const WalletWidget(
                      balance: 1000,
                      visible: true,
                    ),
                  ),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('wallet_opened1.svg'),
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
                        c.icon.value = const IconDetails('partner16.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/partner16.svg',
                      width: 36,
                      height: 28,
                    ),
                  ),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('publics_muted6.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/publics_muted6.svg',
                      width: 32,
                      height: 31,
                    ),
                  ),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('publics13.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/publics13.svg',
                      width: 32,
                      height: 31,
                    ),
                  ),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('chats_muted5.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/chats_muted5.svg',
                      width: 39.26,
                      height: 33.5,
                    ),
                  ),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = const IconDetails('publics13.svg'),
                    child: const SvgImage.asset(
                      'assets/icons/chats6.svg',
                      width: 39.26,
                      height: 33.5,
                    ),
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
