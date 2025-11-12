// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025 Ideas Networks Solutions S.A.,
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

import '../widget/headline.dart';
import '../widget/headlines.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/auth/widget/cupertino_button.dart';
import '/ui/page/call/widget/call_button.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/page/home/widget/shadowed_rounded_button.dart';
import '/ui/page/home/widget/unblock_button.dart';
import '/ui/page/login/widget/sign_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/download_button.dart';
import '/ui/widget/menu_button.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// [Routes.style] buttons section.
class ButtonsSection {
  /// Returns the [Widget]s of this [ButtonsSection].
  static List<Widget> build(BuildContext context) {
    final style = Theme.of(context).style;

    return [
      Headlines(
        color: Color.alphaBlend(
          style.sidebarColor,
          style.colors.onBackgroundOpacity7,
        ),
        children: [
          (
            headline: 'MenuButton',
            widget: MenuButton(
              title: 'Title',
              subtitle: 'Subtitle',
              leading: const SvgIcon(SvgIcons.workFlutter),
              inverted: false,
              onPressed: () {},
            ),
          ),
          (
            headline: 'MenuButton(inverted: true)',
            widget: MenuButton(
              title: 'Title',
              subtitle: 'Subtitle',
              leading: const SvgIcon(SvgIcons.workFlutter),
              inverted: true,
              onPressed: () {},
            ),
          ),
        ],
      ),
      Headlines(
        color: Color.alphaBlend(
          style.sidebarColor,
          style.colors.onBackgroundOpacity7,
        ),
        children: [
          (
            headline: 'OutlinedRoundedButton(title)',
            widget: OutlinedRoundedButton(
              onPressed: () {},
              child: const Text('Title'),
            ),
          ),
          (
            headline: 'OutlinedRoundedButton(subtitle)',
            widget: OutlinedRoundedButton(
              subtitle: const Text('Subtitle'),
              onPressed: () {},
            ),
          ),
        ],
      ),
      Headline(
        background: Color.alphaBlend(
          style.sidebarColor,
          style.colors.onBackgroundOpacity7,
        ),
        child: ShadowedRoundedButton(
          onPressed: () {},
          child: const Text('Label'),
        ),
      ),
      Headline(
        headline: 'PrimaryButton',
        child: PrimaryButton(onPressed: () {}, title: 'PrimaryButton'),
      ),
      Headline(
        child: WidgetButton(
          onPressed: () {},
          child: Container(
            width: 250,
            height: 150,
            decoration: BoxDecoration(
              color: style.colors.onBackgroundOpacity13,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Clickable area')),
          ),
        ),
      ),
      Headlines(
        children: [
          (
            headline: 'SignButton',
            widget: SignButton(onPressed: () {}, title: 'Label'),
          ),
          (
            headline: 'SignButton(asset)',
            widget: SignButton(
              title: 'Password',
              icon: const SvgIcon(SvgIcons.password),
              onPressed: () {},
            ),
          ),
        ],
      ),
      Headlines(
        children: [
          (
            headline: 'StyledCupertinoButton',
            widget: StyledCupertinoButton(
              onPressed: () {},
              label: 'Clickable text',
            ),
          ),
          (
            headline: 'StyledCupertinoButton.primary',
            widget: StyledCupertinoButton(
              onPressed: () {},
              label: 'Clickable text',
              style: style.fonts.medium.regular.onBackground,
            ),
          ),
        ],
      ),
      Headlines(
        children: [
          (
            headline: 'RectangleButton',
            widget: RectangleButton(onPressed: () {}, label: 'Label'),
          ),
          (
            headline: 'RectangleButton(selected: true)',
            widget: RectangleButton(
              onPressed: () {},
              label: 'Label',
              selected: true,
            ),
          ),
        ],
      ),
      Headline(
        headline: 'AnimatedButton',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedButton(
              onPressed: () {},
              child: const SvgIcon(SvgIcons.chats),
            ),
            const SizedBox(width: 32),
            AnimatedButton(
              onPressed: () {},
              child: const SvgIcon(SvgIcons.chatVideoCall),
            ),
            const SizedBox(width: 32),
            AnimatedButton(
              onPressed: () {},
              child: const SvgIcon(SvgIcons.send),
            ),
          ],
        ),
      ),
      Headline(
        headline: 'CallButtonWidget',
        background: style.colors.primaryAuxiliaryOpacity25,
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CallButtonWidget(
              color: style.colors.onSecondaryOpacity50,
              onPressed: () {},
              big: true,
              asset: SvgIcons.fullscreenEnter,
            ),
            const SizedBox(width: 32),
            CallButtonWidget(
              onPressed: () {},
              hint: 'Hint',
              asset: SvgIcons.callScreenShareOn,
              hinted: true,
              expanded: true,
              big: true,
            ),
            const SizedBox(width: 32),
            CallButtonWidget(
              hint: 'Hint',
              asset: SvgIcons.callScreenShareOn,
              hinted: true,
              onPressed: () {},
            ),
          ],
        ),
      ),
      Headlines(
        children: [
          (
            headline: 'DownloadButton.windows',
            widget: const DownloadButton.windows(),
          ),
          (
            headline: 'DownloadButton.macos',
            widget: const DownloadButton.macos(),
          ),
          (
            headline: 'DownloadButton.linux',
            widget: const DownloadButton.linux(),
          ),
          (headline: 'DownloadButton.ios', widget: const DownloadButton.ios()),
          (
            headline: 'DownloadButton.appStore',
            widget: DownloadButton.appStore(),
          ),
          (
            headline: 'DownloadButton.googlePlay',
            widget: DownloadButton.googlePlay(),
          ),
          (
            headline: 'DownloadButton.android',
            widget: const DownloadButton.android(),
          ),
        ],
      ),
      Headline(child: StyledBackButton(onPressed: () {})),
      Headlines(
        children: [
          (
            headline: 'FloatingActionButton(arrow_upward)',
            widget: FloatingActionButton.small(
              heroTag: '1',
              onPressed: () {},
              child: const Icon(Icons.arrow_upward),
            ),
          ),
          (
            headline: 'FloatingActionButton(arrow_downward)',
            widget: FloatingActionButton.small(
              heroTag: '2',
              onPressed: () {},
              child: const Icon(Icons.arrow_downward),
            ),
          ),
        ],
      ),
      Headline(child: UnblockButton(() {})),
    ];
  }
}
