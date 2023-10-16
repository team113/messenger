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
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/auth/widget/cupertino_button.dart';
import 'package:messenger/ui/page/call/widget/conditional_backdrop.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/widget/action.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/chat_tile.dart';
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
              const SizedBox(height: 8),
              _appBar(
                context,
                trailing: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails(SvgIcons.addAccount.asset),
                    child: const SvgIcon(SvgIcons.addAccount),
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
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.frontend.asset),
                  child: const SvgIcon(SvgIcons.frontend),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                inverted: true,
                leading: AnimatedButton(
                  onPressed: () => c.icon.value = IconDetails(
                    SvgIcons.frontendWhite.asset,
                    invert: true,
                  ),
                  child: const SvgIcon(SvgIcons.frontendWhite),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.freelance.asset),
                  child: const SvgIcon(SvgIcons.freelance),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                inverted: true,
                leading: AnimatedButton(
                  onPressed: () => c.icon.value = IconDetails(
                    SvgIcons.freelanceWhite.asset,
                    invert: true,
                  ),
                  child: const SvgIcon(SvgIcons.freelanceWhite),
                ),
              ),
            ],
          ),
          Block(
            children: [
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () => c.icon.value =
                      IconDetails(SvgIcons.publicInformation.asset),
                  child: const SvgIcon(SvgIcons.publicInformation),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                inverted: true,
                leading: AnimatedButton(
                  onPressed: () => c.icon.value = IconDetails(
                    SvgIcons.publicInformationWhite.asset,
                    invert: true,
                  ),
                  child: const SvgIcon(SvgIcons.publicInformationWhite),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.menuSigning.asset),
                  child: const SvgIcon(SvgIcons.menuSigning),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.menuLink.asset),
                  child: const SvgIcon(SvgIcons.menuLink),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                  leading: AnimatedButton(
                onPressed: () =>
                    c.icon.value = IconDetails(SvgIcons.menuBackground.asset),
                child: const SvgIcon(SvgIcons.menuBackground),
              )),
              const SizedBox(height: 8),
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.menuChats.asset),
                  child: const SvgIcon(SvgIcons.menuChats),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.menuCalls.asset),
                  child: const SvgIcon(SvgIcons.menuCalls),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.menuMedia.asset),
                  child: const SvgIcon(SvgIcons.menuMedia),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(leading: RectangleIcon.tab(ProfileTab.welcome)),
              const SizedBox(height: 8),
              MenuButton(leading: RectangleIcon.tab(ProfileTab.getPaid)),
              const SizedBox(height: 8),
              MenuButton(leading: RectangleIcon.tab(ProfileTab.donates)),
              const SizedBox(height: 8),
              MenuButton(leading: RectangleIcon.tab(ProfileTab.notifications)),
              const SizedBox(height: 8),
              MenuButton(leading: RectangleIcon.tab(ProfileTab.storage)),
              const SizedBox(height: 8),
              MenuButton(leading: RectangleIcon.tab(ProfileTab.language)),
              const SizedBox(height: 8),
              MenuButton(leading: RectangleIcon.tab(ProfileTab.blocklist)),
              const SizedBox(height: 8),
              MenuButton(leading: RectangleIcon.tab(ProfileTab.devices)),
              const SizedBox(height: 8),
              MenuButton(leading: RectangleIcon.tab(ProfileTab.vacancies)),
              const SizedBox(height: 8),
              MenuButton(leading: RectangleIcon.tab(ProfileTab.download)),
              const SizedBox(height: 8),
              MenuButton(leading: RectangleIcon.tab(ProfileTab.danger)),
              const SizedBox(height: 8),
              MenuButton(leading: RectangleIcon.tab(ProfileTab.styles)),
              const SizedBox(height: 8),
              MenuButton(leading: RectangleIcon.tab(ProfileTab.logout)),
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
          Block(
            children: [
              ActionButton(
                trailing: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.delete.asset),
                  child: const SvgIcon(SvgIcons.delete),
                ),
              ),
              const SizedBox(height: 8),
              ActionButton(
                trailing: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.mute.asset),
                  child: const SvgIcon(SvgIcons.mute),
                ),
              ),
              const SizedBox(height: 8),
              ActionButton(
                trailing: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.unmute.asset),
                  child: const SvgIcon(SvgIcons.unmute),
                ),
              ),
              const SizedBox(height: 8),
              ActionButton(
                trailing: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.addUser.asset),
                  child: const SvgIcon(SvgIcons.addUser),
                ),
              ),
            ],
          ),
          Block(
            children: [
              ChatTile(
                avatarBuilder: (_) => AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails(SvgIcons.notes.asset),
                  child: AvatarWidget.fromMonolog(null, null, radius: 30),
                ),
                titleBuilder: (_) => const SizedBox(),
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                subtitle: [
                  const SizedBox(height: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 38),
                    child: Row(
                      children: [
                        const SizedBox(height: 3),
                        const Spacer(),
                        const SizedBox(width: 5),
                        AnimatedButton(
                          onPressed: () =>
                              c.icon.value = IconDetails(SvgIcons.muted.asset),
                          child: const SvgIcon(SvgIcons.muted),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                selected: true,
                subtitle: [
                  const SizedBox(height: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 38),
                    child: Row(
                      children: [
                        const SizedBox(height: 3),
                        const Spacer(),
                        const SizedBox(width: 5),
                        AnimatedButton(
                          onPressed: () => c.icon.value =
                              IconDetails(SvgIcons.mutedWhite.asset),
                          child: const SvgIcon(SvgIcons.mutedWhite),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                subtitle: [
                  const SizedBox(height: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 38),
                    child: Row(
                      children: [
                        const SizedBox(height: 3),
                        const Spacer(),
                        const SizedBox(width: 5),
                        AnimatedButton(
                          onPressed: () => c.icon.value =
                              IconDetails(SvgIcons.blocked.asset),
                          child: const SvgIcon(SvgIcons.blocked),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                selected: true,
                subtitle: [
                  const SizedBox(height: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 38),
                    child: Row(
                      children: [
                        const SizedBox(height: 3),
                        const Spacer(),
                        const SizedBox(width: 5),
                        AnimatedButton(
                          onPressed: () => c.icon.value =
                              IconDetails(SvgIcons.blockedWhite.asset),
                          child: const SvgIcon(SvgIcons.blockedWhite),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                status: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedButton(
                      onPressed: () =>
                          c.icon.value = IconDetails(SvgIcons.read.asset),
                      child: const SvgIcon(SvgIcons.read),
                    ),
                  ),
                ],
                subtitle: const [SizedBox(height: 21)],
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                selected: true,
                status: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedButton(
                      onPressed: () =>
                          c.icon.value = IconDetails(SvgIcons.readWhite.asset),
                      child: const SvgIcon(SvgIcons.readWhite),
                    ),
                  ),
                ],
                subtitle: const [SizedBox(height: 21)],
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                status: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedButton(
                      onPressed: () =>
                          c.icon.value = IconDetails(SvgIcons.delivered.asset),
                      child: const SvgIcon(SvgIcons.delivered),
                    ),
                  ),
                ],
                subtitle: const [SizedBox(height: 21)],
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                selected: true,
                status: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedButton(
                      onPressed: () => c.icon.value =
                          IconDetails(SvgIcons.deliveredWhite.asset),
                      child: const SvgIcon(SvgIcons.deliveredWhite),
                    ),
                  ),
                ],
                subtitle: const [SizedBox(height: 21)],
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                status: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedButton(
                      onPressed: () =>
                          c.icon.value = IconDetails(SvgIcons.sent.asset),
                      child: const SvgIcon(SvgIcons.sent),
                    ),
                  ),
                ],
                subtitle: const [SizedBox(height: 21)],
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                selected: true,
                status: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedButton(
                      onPressed: () =>
                          c.icon.value = IconDetails(SvgIcons.sentWhite.asset),
                      child: const SvgIcon(SvgIcons.sentWhite),
                    ),
                  ),
                ],
                subtitle: const [SizedBox(height: 21)],
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                status: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedButton(
                      onPressed: () =>
                          c.icon.value = IconDetails(SvgIcons.sending.asset),
                      child: const SvgIcon(SvgIcons.sending),
                    ),
                  ),
                ],
                subtitle: const [SizedBox(height: 21)],
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                selected: true,
                status: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedButton(
                      onPressed: () => c.icon.value =
                          IconDetails(SvgIcons.sendingWhite.asset),
                      child: const SvgIcon(SvgIcons.sendingWhite),
                    ),
                  ),
                ],
                subtitle: const [SizedBox(height: 21)],
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                status: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedButton(
                      onPressed: () =>
                          c.icon.value = IconDetails(SvgIcons.error.asset),
                      child: const SvgIcon(SvgIcons.error),
                    ),
                  ),
                ],
                subtitle: const [SizedBox(height: 21)],
              ),
              const SizedBox(height: 8),
              ChatTile(
                avatarBuilder: (_) => const SizedBox(width: 60, height: 60),
                titleBuilder: (_) => const SizedBox(),
                selected: true,
                status: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedButton(
                      onPressed: () =>
                          c.icon.value = IconDetails(SvgIcons.error.asset),
                      child: const SvgIcon(SvgIcons.error),
                    ),
                  ),
                ],
                subtitle: const [SizedBox(height: 21)],
              ),
            ],
          ),
          Block(
            children: [
              _messageStatus(context, c, SvgIcons.readSmall),
              const SizedBox(height: 8),
              _messageStatus(context, c, SvgIcons.deliveredSmall),
              const SizedBox(height: 8),
              _messageStatus(context, c, SvgIcons.sentSmall),
              const SizedBox(height: 8),
              _messageStatus(context, c, SvgIcons.sendingSmall),
              const SizedBox(height: 8),
              _messageStatus(context, c, SvgIcons.errorSmall),
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
                            width: 22,
                            height: 22,
                            child: asset?.endsWith('.svg') == true
                                ? SvgImage.asset(
                                    'assets/icons/$asset',
                                    width: 24,
                                    height: 24,
                                  )
                                : Image.asset(
                                    'assets/icons/$asset',
                                    width: 24,
                                    height: 24,
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

Widget _messageStatus(
  BuildContext context,
  IconsController c,
  SvgData icon,
) {
  final style = Theme.of(context).style;

  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: style.colors.background,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 100, height: 40),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 6, 8),
          child: AnimatedButton(
            onPressed: () => c.icon.value = IconDetails(icon.asset),
            child: SvgIcon(icon),
          ),
        ),
      ],
    ),
  );
}
