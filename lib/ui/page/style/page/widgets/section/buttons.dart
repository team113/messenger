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

import '../widget/headline.dart';
import '../widget/headlines.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/auth/widget/cupertino_button.dart';
import '/ui/page/call/widget/call_button.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/gallery_button.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/page/home/widget/shadowed_rounded_button.dart';
import '/ui/page/home/widget/unblock_button.dart';
import '/ui/page/login/widget/primary_button.dart';
import '/ui/page/login/widget/sign_button.dart';
import '/ui/page/work/widget/vacancy_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/download_button.dart';
import '/ui/widget/menu_button.dart';
import '/ui/widget/outlined_rounded_button.dart';
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
              leading: const SvgIcon(SvgIcons.frontend),
              inverted: false,
              onPressed: () {},
            ),
          ),
          (
            headline: 'MenuButton(inverted: true)',
            widget: MenuButton(
              title: 'Title',
              subtitle: 'Subtitle',
              leading: const SvgIcon(SvgIcons.frontendWhite),
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
            widget: SignButton(
              onPressed: () {},
              title: 'Label',
            ),
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
            widget:
                StyledCupertinoButton(onPressed: () {}, label: 'Clickable text')
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
          (
            headline: 'RectangleButton.radio',
            widget: RectangleButton(
              onPressed: () {},
              label: 'Label',
              radio: true,
            ),
          ),
          (
            headline: 'RectangleButton.radio(selected: true)',
            widget: RectangleButton(
              onPressed: () {},
              label: 'Label',
              selected: true,
              radio: true,
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
              withBlur: true,
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
      Headline(
        headline: 'GalleryButton',
        background: style.colors.primaryAuxiliaryOpacity25,
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GalleryButton(
              onPressed: () {},
              child: Icon(
                Icons.close_rounded,
                color: style.colors.onPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 32),
            GalleryButton(onPressed: () {}, icon: SvgIcons.fullscreenEnter),
            const SizedBox(width: 32),
            GalleryButton(
              onPressed: () {},
              child: Padding(
                padding: const EdgeInsets.only(left: 1),
                child: Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: style.colors.onPrimary,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
      const Headlines(
        children: [
          (
            headline: 'DownloadButton.windows',
            widget: DownloadButton.windows(),
          ),
          (
            headline: 'DownloadButton.macos',
            widget: DownloadButton.macos(),
          ),
          (
            headline: 'DownloadButton.linux',
            widget: DownloadButton.linux(),
          ),
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
            widget: DownloadButton.android(),
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
      Headlines(
        color: Color.alphaBlend(
          style.sidebarColor,
          style.colors.onBackgroundOpacity7,
        ),
        children: WorkTab.values
            .map(
              (e) => (
                headline: 'VacancyWorkButton(${e.name})',
                widget: VacancyWorkButton(e, onPressed: (_) {}),
              ),
            )
            .toList(),
      ),
    ];
  }
}
