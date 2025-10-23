// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/config.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/auth/widget/cupertino_button.dart';
import '/ui/page/call/widget/call_button.dart';
import '/ui/page/call/widget/raised_hand.dart';
import '/ui/page/call/widget/round_button.dart';
import '/ui/page/home/widget/action.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/chat_tile.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/page/login/widget/sign_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/menu_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

import 'controller.dart';

/// Icons view of the [Routes.style] page.
class IconsView extends StatelessWidget {
  const IconsView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: IconsController(),
      builder: (IconsController c) {
        final List<Widget> children = [
          Block(
            background: style.colors.primaryDark,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _downloadableIcon(context, c, 'iOS.png'),
                  _downloadableIcon(context, c, 'macOS.png'),
                  _downloadableIcon(context, c, 'windows.ico'),
                  _downloadableIcon(context, c, 'android.png'),
                  _downloadableIcon(context, c, 'web.png', mini: true),
                  _downloadableIcon(context, c, 'alert.png', mini: true),
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
                        c.icon.value = IconDetails.svg(SvgIcons.chat),
                    child: Transform.translate(
                      offset: const Offset(0, 1),
                      child: const SvgIcon(SvgIcons.chat),
                    ),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.chatVideoCall),
                    child: const SvgIcon(SvgIcons.chatVideoCall),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.chatAudioCall),
                    child: const SvgIcon(SvgIcons.chatAudioCall),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _appBar(
                context,
                trailing: [
                  AnimatedButton(
                    onPressed: () => c.icon.value = IconDetails.svg(
                      SvgIcons.callEnd,
                      invert: true,
                    ),
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: style.colors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: SvgIcon(SvgIcons.callEnd)),
                    ),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () => c.icon.value = IconDetails.svg(
                      SvgIcons.callStart,
                      invert: true,
                    ),
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: style.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: SvgIcon(SvgIcons.callStart)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _appBar(
                context,
                trailing: [
                  AnimatedButton(
                    onPressed: () => c.icon.value = IconDetails.svg(
                      SvgIcons.callEndSmall,
                      invert: true,
                    ),
                    child: Container(
                      height: 22,
                      width: 22,
                      decoration: BoxDecoration(
                        color: style.colors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SvgIcon(SvgIcons.callEndSmall),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () => c.icon.value = IconDetails.svg(
                      SvgIcons.callStartSmall,
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
                        c.icon.value = IconDetails.svg(SvgIcons.home),
                    child: const SvgIcon(SvgIcons.home),
                  ),
                ],
                trailing: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.shareThick),
                    child: const SvgIcon(SvgIcons.shareThick),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.copyThick),
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
                        c.icon.value = IconDetails.svg(SvgIcons.search),
                    child: const SvgIcon(SvgIcons.search),
                  ),
                ],
                trailing: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.closePrimary),
                    child: const SvgIcon(SvgIcons.closePrimary),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.contactsSwitch),
                    child: const SvgIcon(SvgIcons.contactsSwitch),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.chatsSwitch),
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
                        c.icon.value = IconDetails.svg(SvgIcons.searchExit),
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
                        c.icon.value = IconDetails.svg(SvgIcons.addAccount),
                    child: const SvgIcon(SvgIcons.addAccount),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _appBar(
                context,
                trailing: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.palette),
                    child: const SvgIcon(SvgIcons.palette),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.typography),
                    child: const SvgIcon(SvgIcons.typography),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.widgets),
                    child: const SvgIcon(SvgIcons.widgets),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.icons),
                    child: const SvgIcon(SvgIcons.icons),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _appBar(
                context,
                trailing: [
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.lightMode),
                    child: const SvgIcon(SvgIcons.lightMode),
                  ),
                  const SizedBox(width: 24),
                  AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.darkMode),
                    child: const SvgIcon(SvgIcons.darkMode),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _appBar(
                context,
                leading: [
                  const SizedBox(width: 32),
                  Column(
                    children: [
                      const SizedBox(height: 32),
                      AnimatedButton(
                        onPressed: () =>
                            c.icon.value = IconDetails.svg(SvgIcons.mutedSmall),
                        child: const SvgIcon(SvgIcons.mutedSmall),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Block(
            children: [
              SignButton(
                icon: const SvgIcon(SvgIcons.register),
                title: '',
                onPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.register),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.enter),
                title: '',
                onPressed: () => c.icon.value = IconDetails.svg(SvgIcons.enter),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.guest),
                title: '',
                onPressed: () => c.icon.value = IconDetails.svg(SvgIcons.guest),
              ),

              //
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.email),
                title: '',
                onPressed: () => c.icon.value = IconDetails.svg(SvgIcons.email),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.phone),
                title: '',
                onPressed: () => c.icon.value = IconDetails.svg(SvgIcons.phone),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.password),
                title: '',
                onPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.password),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.google),
                title: '',
                onPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.google),
              ),

              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.github),
                title: '',
                onPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.github),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.apple),
                title: '',
                onPressed: () => c.icon.value = IconDetails.svg(SvgIcons.apple),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.windows),
                title: '',
                onPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.windows),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.linux),
                title: '',
                onPressed: () => c.icon.value = IconDetails.svg(SvgIcons.linux),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.appStore),
                title: '',
                onPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.appStore),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.googlePlay),
                title: '',
                onPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.googlePlay),
              ),
              const SizedBox(height: 8),
              SignButton(
                icon: const SvgIcon(SvgIcons.android),
                title: '',
                onPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.android),
              ),
            ],
          ),
          Block(
            children: [
              ReactiveTextField(
                state: TextFieldState(editable: false),
                onSuffixPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.visibleOff),
                trailing: const SvgIcon(SvgIcons.visibleOff),
              ),
              const SizedBox(height: 8),
              ReactiveTextField(
                state: TextFieldState(editable: false),
                onSuffixPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.visibleOn),
                trailing: const SvgIcon(SvgIcons.visibleOn),
              ),
              const SizedBox(height: 8),
              ReactiveTextField(
                state: TextFieldState(editable: false),
                onSuffixPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.copy),
                trailing: const SvgIcon(SvgIcons.copy),
              ),
              const SizedBox(height: 8),
              ReactiveTextField(
                state: TextFieldState(editable: false),
                onSuffixPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.share),
                trailing: const SvgIcon(SvgIcons.share),
              ),
              const SizedBox(height: 8),
              ReactiveTextField(
                state: TextFieldState(editable: false),
                onSuffixPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.timer),
                trailing: const SvgIcon(SvgIcons.timer),
              ),
              const SizedBox(height: 8),
              ReactiveTextField(
                state: TextFieldState(editable: false),
                onSuffixPressed: () =>
                    c.icon.value = IconDetails.svg(SvgIcons.errorBig),
                trailing: const SvgIcon(SvgIcons.errorBig),
              ),
            ],
          ),
          Block(
            children: [
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails.svg(SvgIcons.workRust),
                  child: const SvgIcon(SvgIcons.workRust),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails.svg(SvgIcons.workFlutter),
                  child: const SvgIcon(SvgIcons.workFlutter),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                leading: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails.svg(SvgIcons.workFreelance),
                  child: const SvgIcon(SvgIcons.workFreelance),
                ),
              ),
              const SizedBox(height: 8),
              MenuButton(
                inverted: true,
                leading: AnimatedButton(
                  onPressed: () => c.icon.value = IconDetails.svg(
                    SvgIcons.workDesigner,
                    invert: true,
                  ),
                  child: const SvgIcon(SvgIcons.workDesigner),
                ),
              ),
            ],
          ),
          Block(
            children: [
              _navBar(context, [
                AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails.svg(SvgIcons.partner),
                  child: const SvgIcon(SvgIcons.partner),
                ),
                AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails.svg(SvgIcons.chatsMuted),
                  child: const SvgIcon(SvgIcons.chatsMuted),
                ),
                AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails.svg(SvgIcons.chats),
                  child: const SvgIcon(SvgIcons.chats),
                ),
              ]),
            ],
          ),
          Block(
            children: [
              ActionButton(
                trailing: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails.svg(SvgIcons.delete),
                  child: const SvgIcon(SvgIcons.delete),
                ),
              ),
              const SizedBox(height: 8),
              ActionButton(
                trailing: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails.svg(SvgIcons.mute),
                  child: const SvgIcon(SvgIcons.mute),
                ),
              ),
              const SizedBox(height: 8),
              ActionButton(
                trailing: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails.svg(SvgIcons.unmute),
                  child: const SvgIcon(SvgIcons.unmute),
                ),
              ),
              const SizedBox(height: 8),
              ActionButton(
                trailing: AnimatedButton(
                  onPressed: () =>
                      c.icon.value = IconDetails.svg(SvgIcons.addUser),
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
                      c.icon.value = IconDetails.svg(SvgIcons.notes),
                  child: AvatarWidget.fromMonolog(
                    null,
                    null,
                    radius: AvatarRadius.large,
                  ),
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
                              c.icon.value = IconDetails.svg(SvgIcons.muted),
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
                          onPressed: () => c.icon.value = IconDetails.svg(
                            SvgIcons.mutedWhite,
                            invert: true,
                          ),
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
                          onPressed: () =>
                              c.icon.value = IconDetails.svg(SvgIcons.blocked),
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
                          onPressed: () => c.icon.value = IconDetails.svg(
                            SvgIcons.blockedWhite,
                            invert: true,
                          ),
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
                          c.icon.value = IconDetails.svg(SvgIcons.read),
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
                      onPressed: () => c.icon.value = IconDetails.svg(
                        SvgIcons.readWhite,
                        invert: true,
                      ),
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
                          c.icon.value = IconDetails.svg(SvgIcons.delivered),
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
                      onPressed: () => c.icon.value = IconDetails.svg(
                        SvgIcons.deliveredWhite,
                        invert: true,
                      ),
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
                          c.icon.value = IconDetails.svg(SvgIcons.sent),
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
                      onPressed: () => c.icon.value = IconDetails.svg(
                        SvgIcons.sentWhite,
                        invert: true,
                      ),
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
                          c.icon.value = IconDetails.svg(SvgIcons.sending),
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
                      onPressed: () => c.icon.value = IconDetails.svg(
                        SvgIcons.sendingWhite,
                        invert: true,
                      ),
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
                          c.icon.value = IconDetails.svg(SvgIcons.error),
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
                          c.icon.value = IconDetails.svg(SvgIcons.error),
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
              _messageStatus(context, c, SvgIcons.read),
              const SizedBox(height: 8),
              _messageStatus(context, c, SvgIcons.delivered),
              const SizedBox(height: 8),
              _messageStatus(context, c, SvgIcons.sent),
              const SizedBox(height: 8),
              _messageStatus(context, c, SvgIcons.sending),
              const SizedBox(height: 8),
              _messageStatus(context, c, SvgIcons.error),
            ],
          ),
          Block(
            children: [
              _messageCall(context, c, SvgIcons.callAudio),
              const SizedBox(height: 8),
              _messageCall(context, c, SvgIcons.callAudioDisabled),
              const SizedBox(height: 8),
              _messageCall(context, c, SvgIcons.callAudioMissed),
              const SizedBox(height: 8),
              _messageCall(context, c, SvgIcons.callAudioWhite),
              const SizedBox(height: 8),
              _messageCall(context, c, SvgIcons.callVideo),
              const SizedBox(height: 8),
              _messageCall(context, c, SvgIcons.callVideoDisabled),
              const SizedBox(height: 8),
              _messageCall(context, c, SvgIcons.callVideoMissed),
              const SizedBox(height: 8),
              _messageCall(context, c, SvgIcons.callVideoWhite),
            ],
          ),
          Block(
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(
                  borderRadius: style.cardRadius,
                  color: style.cardColor,
                  boxShadow: [
                    CustomBoxShadow(
                      blurRadius: 8,
                      color: style.colors.onBackgroundOpacity13,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 56,
                      child: Center(
                        child: AnimatedButton(
                          onPressed: () =>
                              c.icon.value = IconDetails.svg(SvgIcons.chatMore),
                          child: const SvgIcon(SvgIcons.chatMore),
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 50,
                      height: 56,
                      child: Center(
                        child: AnimatedButton(
                          onPressed: () =>
                              c.icon.value = IconDetails.svg(SvgIcons.forward),
                          child: const SvgIcon(SvgIcons.forward),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      height: 56,
                      child: Center(
                        child: AnimatedButton(
                          onPressed: () =>
                              c.icon.value = IconDetails.svg(SvgIcons.send),
                          child: const SvgIcon(SvgIcons.send),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(
                  borderRadius: style.cardRadius,
                  color: style.cardColor,
                  boxShadow: [
                    CustomBoxShadow(
                      blurRadius: 8,
                      color: style.colors.onBackgroundOpacity13,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    ...[
                      SvgIcons.videoMessageSmall,
                      SvgIcons.gallerySmall,
                      SvgIcons.giftSmall,
                      SvgIcons.smileSmall,
                    ].map((e) {
                      return SizedBox(
                        width: 50,
                        height: 56,
                        child: Center(
                          child: AnimatedButton(
                            onPressed: () => c.icon.value = IconDetails.svg(e),
                            child: SvgIcon(e),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(
                  borderRadius: style.cardRadius,
                  color: style.cardColor,
                  boxShadow: [
                    CustomBoxShadow(
                      blurRadius: 8,
                      color: style.colors.onBackgroundOpacity13,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    ...[
                      SvgIcons.audioMessageSmall,
                      SvgIcons.fileOutlinedSmall,
                      SvgIcons.takePhotoSmall,
                      SvgIcons.takeVideoSmall,
                    ].map((e) {
                      return SizedBox(
                        width: 50,
                        height: 56,
                        child: Center(
                          child: AnimatedButton(
                            onPressed: () => c.icon.value = IconDetails.svg(e),
                            child: SvgIcon(e),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          Block(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: style.cardRadius,
                  boxShadow: [
                    CustomBoxShadow(
                      blurRadius: 8,
                      color: style.colors.onBackgroundOpacity13,
                    ),
                  ],
                ),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        [
                          SvgIcons.videoMessage,
                          SvgIcons.gallery,
                          SvgIcons.gift,
                          SvgIcons.smile,
                          SvgIcons.audioMessage,
                          SvgIcons.fileOutlined,
                          SvgIcons.takePhoto,
                          SvgIcons.takeVideo,
                        ].mapIndexed((i, e) {
                          SvgData? trailing;

                          if (i == 0) {
                            trailing = SvgIcons.pin;
                          } else if (i == 1) {
                            trailing = SvgIcons.unpin;
                          }

                          return Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 26,
                                  child: AnimatedButton(
                                    onPressed: () =>
                                        c.icon.value = IconDetails.svg(e),
                                    child: SvgIcon(e),
                                  ),
                                ),
                                const SizedBox(width: 120),
                                if (trailing != null)
                                  SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: Center(
                                      child: AnimatedButton(
                                        onPressed: () => c.icon.value =
                                            IconDetails.svg(trailing!),
                                        child: SvgIcon(trailing),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ],
          ),
          Block(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 1, top: 1),
                decoration: BoxDecoration(
                  color: style.contextMenuBackgroundColor,
                  borderRadius: style.contextMenuRadius,
                  border: Border.all(
                    color: style.colors.secondaryHighlightDarkest,
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: style.colors.onBackgroundOpacity20,
                      blurStyle: BlurStyle.outer.workaround,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: style.contextMenuRadius,
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          [
                            SvgIcons.info,
                            SvgIcons.copy19,
                            SvgIcons.reply,
                            SvgIcons.forwardSmall,
                            SvgIcons.edit,
                            SvgIcons.pinOutlined,
                            SvgIcons.unpinOutlined,
                            SvgIcons.deleteThick,
                          ].map((e) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 15,
                              ),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 36 + 150),
                                  const Spacer(),
                                  AnimatedButton(
                                    onPressed: () =>
                                        c.icon.value = IconDetails.svg(e),
                                    child: SvgIcon(e),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Block(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      SvgIcons.callMore,
                      SvgIcons.callEndBig,
                      SvgIcons.callVideoOn,
                      SvgIcons.callVideoOff,
                      SvgIcons.callMicrophoneOn,
                      SvgIcons.callMicrophoneOff,
                      SvgIcons.callScreenShareOn,
                      SvgIcons.callScreenShareOff,
                      SvgIcons.callHandDown,
                      SvgIcons.callHandUp,
                      SvgIcons.callSettings,
                      SvgIcons.callParticipants,
                      SvgIcons.callIncomingVideoOn,
                      SvgIcons.callIncomingVideoOff,
                      SvgIcons.callIncomingAudioOn,
                      SvgIcons.callIncomingAudioOff,
                      SvgIcons.callAudioEarpiece,
                    ].map((e) {
                      return CallButtonWidget(
                        asset: e,
                        onPressed: () =>
                            c.icon.value = IconDetails.svg(e, invert: true),
                      );
                    }).toList(),
              ),
            ],
          ),
          Block(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: style.colors.onBackgroundOpacity50,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AnimatedButton(
                    onPressed: () => c.icon.value = IconDetails.svg(
                      SvgIcons.addBigger,
                      invert: true,
                    ),
                    child: const SvgIcon(SvgIcons.addBigger),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: style.colors.onBackgroundOpacity50,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: AnimatedButton(
                    onPressed: () => c.icon.value = IconDetails.svg(
                      SvgIcons.addBig,
                      invert: true,
                    ),
                    child: const SvgIcon(SvgIcons.addBig),
                  ),
                ),
              ),
            ],
          ),
          Block(
            children: [
              Container(
                key: const Key('Tooltip'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    CustomBoxShadow(
                      color: style.colors.onBackgroundOpacity13,
                      blurRadius: 8,
                      blurStyle: BlurStyle.outer.workaround,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: style.colors.primaryDarkOpacity70,
                  ),
                  padding: const EdgeInsets.only(
                    left: 6,
                    right: 6,
                    top: 4,
                    bottom: 4,
                  ),
                  height: 32,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        [
                          SvgIcons.audioOffSmall,
                          SvgIcons.microphoneOffSmall,
                          SvgIcons.screenShareSmall,
                          SvgIcons.videoOffSmall,
                          SvgIcons.lowSignalSmall,
                        ].map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 4, right: 4),
                            child: AnimatedButton(
                              onPressed: () => c.icon.value = IconDetails.svg(
                                e,
                                invert: true,
                              ),
                              child: SvgIcon(e),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ],
          ),
          Block(
            children: [
              AnimatedButton(
                onPressed: () => c.icon.value = IconDetails.svg(
                  SvgIcons.handUpBig,
                  invert: true,
                ),
                child: const RaisedHand(true),
              ),
            ],
          ),
          Block(
            children: [
              Container(
                key: const ValueKey('TitleBar'),
                color: style.colors.backgroundAuxiliaryLight,
                height: 30,
                child: Row(
                  children: [
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 3, left: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedButton(
                            onPressed: () => c.icon.value = IconDetails.svg(
                              SvgIcons.fullscreenExitSmall,
                              invert: true,
                            ),
                            child: const SvgIcon(SvgIcons.fullscreenExitSmall),
                          ),
                          const SizedBox(width: 10),
                          AnimatedButton(
                            onPressed: () => c.icon.value = IconDetails.svg(
                              SvgIcons.fullscreenEnterSmall,
                              invert: true,
                            ),
                            child: const SvgIcon(SvgIcons.fullscreenEnterSmall),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Block(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: _RoundFloatingButton(
                      onPressed: () => c.icon.value = IconDetails.svg(
                        SvgIcons.fullscreenExit,
                        invert: true,
                      ),
                      icon: SvgIcons.fullscreenExit,
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: _RoundFloatingButton(
                      onPressed: () => c.icon.value = IconDetails.svg(
                        SvgIcons.fullscreenEnter,
                        invert: true,
                      ),
                      icon: SvgIcons.fullscreenEnter,
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: _RoundFloatingButton(
                      onPressed: () => c.icon.value = IconDetails.svg(
                        SvgIcons.arrowLeft,
                        invert: true,
                      ),
                      icon: SvgIcons.arrowLeft,
                      offset: const Offset(-1, 0),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: _RoundFloatingButton(
                      onPressed: () => c.icon.value = IconDetails.svg(
                        SvgIcons.arrowRight,
                        invert: true,
                      ),
                      icon: SvgIcons.arrowRight,
                      offset: const Offset(1, 0),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: _RoundFloatingButton(
                      onPressed: () => c.icon.value = IconDetails.svg(
                        SvgIcons.arrowLeftDisabled,
                        invert: true,
                      ),
                      icon: SvgIcons.arrowLeftDisabled,
                      offset: const Offset(-1, 0),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: _RoundFloatingButton(
                      onPressed: () => c.icon.value = IconDetails.svg(
                        SvgIcons.arrowRightDisabled,
                        invert: true,
                      ),
                      icon: SvgIcons.arrowRightDisabled,
                      offset: const Offset(1, 0),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: _RoundFloatingButton(
                      onPressed: () => c.icon.value = IconDetails.svg(
                        SvgIcons.close,
                        invert: true,
                      ),
                      icon: SvgIcons.close,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Block(
            children: [
              Container(
                width: 250,
                height: 250,
                color: style.colors.onBackgroundOpacity13,
                child: Center(
                  child: AnimatedButton(
                    onPressed: () =>
                        c.icon.value = IconDetails.svg(SvgIcons.download),
                    child: const SvgIcon(SvgIcons.download),
                  ),
                ),
              ),
            ],
          ),
          Block(
            children: [
              Container(
                height: 250,
                width: 370,
                decoration: BoxDecoration(
                  color: style.colors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: AnimatedButton(
                    onPressed: () => c.icon.value = IconDetails.svg(
                      SvgIcons.noVideo,
                      invert: true,
                    ),
                    child: const SvgIcon(SvgIcons.noVideo),
                  ),
                ),
              ),
            ],
          ),
          Block(
            children: [
              ...[
                SvgIcons.menuProfile,
                SvgIcons.menuSigning,
                SvgIcons.menuLink,
                SvgIcons.menuBackground,
                SvgIcons.menuChats,
                SvgIcons.menuCalls,
                SvgIcons.menuMedia,
                SvgIcons.menuNotifications,
                SvgIcons.menuStorage,
                SvgIcons.menuLanguage,
                SvgIcons.menuBlocklist,
                SvgIcons.menuDownload,
                SvgIcons.menuDanger,
                SvgIcons.menuLogout,
              ].map(
                (e) => MenuButton(
                  leading: AnimatedButton(
                    onPressed: () => c.icon.value = IconDetails.svg(e),
                    child: SvgIcon(e),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 120),
        ];

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ListView(children: children),
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
                final SvgData? data = c.icon.value?.data;
                final String download =
                    data?.asset ??
                    'assets/icons/${c.icon.value?.download ?? c.icon.value?.asset}';
                final bool invert = c.icon.value?.invert == true;

                return Container(
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  decoration: BoxDecoration(
                    borderRadius: style.cardRadius,
                    boxShadow: [
                      CustomBoxShadow(
                        blurRadius: 8,
                        color: style.colors.onBackgroundOpacity13,
                        blurStyle: BlurStyle.outer.workaround,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: invert
                          ? style.colors.primaryDark
                          : style.cardColor,
                      borderRadius: style.cardRadius,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: data == null
                              ? asset?.endsWith('.svg') == true
                                    ? SvgImage.asset(
                                        'assets/icons/$asset',
                                        width: 24,
                                        height: 24,
                                      )
                                    : Image.asset(
                                        'assets/icons/$asset',
                                        width: 24,
                                        height: 24,
                                      )
                              : SvgIcon(data, height: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data?.asset.replaceFirst('assets/icons/', '') ?? asset}',
                                style: invert
                                    ? style.fonts.normal.regular.onPrimary
                                    : style.fonts.normal.regular.onBackground,
                              ),
                            ],
                          ),
                        ),
                        SelectionContainer.disabled(
                          child: StyledCupertinoButton(
                            label: 'Download',
                            onPressed: () async {
                              final file = await PlatformUtils.saveTo(
                                '${Config.origin}/assets/$download',
                              );

                              if (file != null) {
                                MessagePopup.success('$asset downloaded');
                              }
                            },
                            style: style.fonts.small.regular.primary,
                          ),
                        ),
                      ],
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

  /// Constructs a [CustomAppBar] displaying the provided [children].
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

  /// Constructs the [IconDetails] downloadable in the `application` directory.
  Widget _downloadableIcon(
    BuildContext context,
    IconsController c,
    String icon, {
    bool mini = false,
  }) {
    return AnimatedButton(
      onPressed: () => c.icon.value = IconDetails(
        'application/$icon',
        invert: true,
        download: 'application/${icon.split('.').first}.zip',
      ),
      child: Image.asset(
        'assets/icons/application/$icon',
        width: mini ? 32 : 64,
        height: mini ? 32 : 64,
      ),
    );
  }
}

/// [RoundFloatingButton] with specified [RoundFloatingButton.color].
class _RoundFloatingButton extends StatelessWidget {
  const _RoundFloatingButton({this.onPressed, required this.icon, this.offset});

  /// Callback, called when the button is tapped or activated other way.
  final void Function()? onPressed;

  /// [SvgData] to display instead of [asset].
  final SvgData icon;

  /// [Offset] to apply to the [icon] or [asset].
  final Offset? offset;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return RoundFloatingButton(
      color: style.colors.onSecondaryOpacity50,
      onPressed: onPressed,
      icon: icon,
      offset: offset,
    );
  }
}

/// Constructs the [Container] visually shaped like the [CustomNavigationBar].
Widget _navBar(BuildContext context, List<Widget> children) {
  final style = Theme.of(context).style;

  return Container(
    decoration: BoxDecoration(
      color: style.cardColor,
      boxShadow: [
        CustomBoxShadow(
          blurRadius: 8,
          color: style.colors.onBackgroundOpacity13,
          blurStyle: BlurStyle.outer.workaround,
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

/// Constructs a [Container] visually shaped like a [ChatCall] message.
Widget _messageCall(BuildContext context, IconsController c, SvgData icon) {
  final style = Theme.of(context).style;

  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: style.colors.background,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
          child: AnimatedButton(
            onPressed: () => c.icon.value = IconDetails.svg(icon),
            child: SvgIcon(icon),
          ),
        ),
        const SizedBox(width: 100, height: 34),
      ],
    ),
  );
}

/// Constructs a [Container] visually shaped like a message displaying the
/// [icon] as its status.
Widget _messageStatus(BuildContext context, IconsController c, SvgData icon) {
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
            onPressed: () => c.icon.value = IconDetails.svg(icon),
            child: SvgIcon(icon),
          ),
        ),
      ],
    ),
  );
}
