// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import '../widget/headline.dart';
import '../widget/headlines.dart';
import '/routes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/my_profile/widget/background_preview.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';

/// [Routes.style] navigation section.
class NavigationSection {
  /// Returns the [Widget]s of this [NavigationSection].
  static List<Widget> build(BuildContext context) {
    return [
      Headlines(
        children: [
          (
            headline: 'CustomAppBar',
            widget: SizedBox(
              height: 60,
              child: CustomAppBar(
                top: false,
                title: const Text('Title'),
                leading: [StyledBackButton(onPressed: () {})],
                actions: const [SizedBox(width: 60)],
              ),
            ),
          ),
          (
            headline: 'CustomAppBar(leading, actions)',
            widget: SizedBox(
              height: 60,
              child: CustomAppBar(
                top: false,
                title: const Row(children: [Text('Title')]),
                padding: const EdgeInsets.only(left: 4, right: 20),
                leading: [StyledBackButton(onPressed: () {})],
                actions: [
                  AnimatedButton(
                    onPressed: () {},
                    child: const SvgIcon(SvgIcons.chatVideoCall),
                  ),
                  const SizedBox(width: 28),
                  AnimatedButton(
                    key: const Key('AudioCall'),
                    onPressed: () {},
                    child: const SvgIcon(SvgIcons.chatAudioCall),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      Headline(
        headline: 'CustomNavigationBar',
        child: ObxValue((p) {
          return CustomNavigationBar(
            currentIndex: p.value,
            onTap: (t) => p.value = t,
            items: [
              CustomNavigationBarItem.wallet(),
              CustomNavigationBarItem.partner(),
              const CustomNavigationBarItem.contacts(),
              CustomNavigationBarItem.chats(),
              CustomNavigationBarItem.menu(),
            ],
          );
        }, RxInt(0)),
      ),
      const Headline(child: BackgroundPreview(null)),
      Headline(
        child: BigAvatarWidget.myUser(null, onDelete: () {}, onUpload: () {}),
      ),
    ];
  }
}
