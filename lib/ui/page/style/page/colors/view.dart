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

import '/themes.dart';
import '/ui/page/style/widget/builder_wrap.dart';
import '/ui/page/style/widget/headers.dart';
import 'widget/color.dart';
import 'widget/schema.dart';

/// View of the [StyleTab.colors] page.
class ColorsView extends StatelessWidget {
  const ColorsView(this.inverted, this.compact, {super.key});

  /// Indicator whether this [ColorsView] should have its colors inverted.
  final bool inverted;

  ///
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final List<(Color, String, String)> colors = [
      (style.colors.onBackground, 'onBackground', 'Primary text'),
      (
        style.colors.secondaryBackground,
        'secondaryBackground',
        'Background text and stroke'
      ),
      (
        style.colors.secondaryBackgroundLight,
        'secondaryBackgroundLight',
        'Call background'
      ),
      (
        style.colors.secondaryBackgroundLightest,
        'secondaryBackgroundLightest',
        'Background of avatar and call buttons'
      ),
      (style.colors.secondary, 'secondary', 'Text and stroke'),
      (
        style.colors.secondaryHighlightDarkest,
        'secondaryHighlightDarkest',
        'Inscriptions and icons over the background of the call'
      ),
      (
        style.colors.secondaryHighlightDark,
        'secondaryHighlightDark',
        'Navigation bar button'
      ),
      (
        style.colors.secondaryHighlight,
        'secondaryHighlight',
        'Circular progress indicator'
      ),
      (style.colors.background, 'background', 'General background'),
      (
        style.colors.secondaryOpacity87,
        'secondaryOpacity87',
        'Raised hand and a muted microphone in a call'
      ),
      (
        style.colors.onBackgroundOpacity50,
        'onBackgroundOpacity50',
        'Attached file background'
      ),
      (
        style.colors.onBackgroundOpacity40,
        'onBackgroundOpacity40',
        'Bottom chat bar'
      ),
      (
        style.colors.onBackgroundOpacity27,
        'onBackgroundOpacity27',
        'Floating bar shadow'
      ),
      (
        style.colors.onBackgroundOpacity20,
        'onBackgroundOpacity20',
        'Panel with buttons in the call'
      ),
      (
        style.colors.onBackgroundOpacity13,
        'onBackgroundOpacity13',
        'Video play/pause button'
      ),
      (style.colors.onBackgroundOpacity7, 'onBackgroundOpacity7', 'Dividers'),
      (
        style.colors.onBackgroundOpacity2,
        'onBackgroundOpacity2',
        'Text "Connecting", "Calling", etc. in a call'
      ),
      (style.colors.onPrimary, 'onPrimary', 'Left side of the profile page'),
      (
        style.colors.onPrimaryOpacity95,
        'onPrimaryOpacity95',
        'Message that was received'
      ),
      (
        style.colors.onPrimaryOpacity50,
        'onPrimaryOpacity50',
        'Outline call accept buttons with audio and video'
      ),
      (
        style.colors.onPrimaryOpacity25,
        'onPrimaryOpacity25',
        'Shadow of forwarded messages'
      ),
      (
        style.colors.onPrimaryOpacity7,
        'onPrimaryOpacity7',
        'Additional background for the call'
      ),
      (style.colors.backgroundAuxiliary, 'backgroundAuxiliary', 'Active call'),
      (
        style.colors.backgroundAuxiliaryLight,
        'backgroundAuxiliaryLight',
        'Profile background'
      ),
      (
        style.colors.onSecondaryOpacity88,
        'onSecondaryOpacity88',
        'Top draggable subtitle bar'
      ),
      (style.colors.onSecondary, 'onSecondary', 'Call button'),
      (
        style.colors.onSecondaryOpacity60,
        'onSecondaryOpacity60',
        'Additional top draggable subtitle bar'
      ),
      (
        style.colors.onSecondaryOpacity50,
        'onSecondaryOpacity50',
        'Buttons in the gallery'
      ),
      (
        style.colors.onSecondaryOpacity20,
        'onSecondaryOpacity20',
        'Mobile selector'
      ),
      (style.colors.primaryHighlight, 'primaryHighlight', 'Dropdown menu'),
      (style.colors.primary, 'primary', 'Inverted buttons and links'),
      (
        style.colors.primaryHighlightShiniest,
        'primaryHighlightShiniest',
        'Read message'
      ),
      (
        style.colors.primaryHighlightLightest,
        'primaryHighlightLightest',
        'Outline of the read message'
      ),
      (
        style.colors.backgroundAuxiliaryLighter,
        'backgroundAuxiliaryLighter',
        'Unload'
      ),
      (
        style.colors.backgroundAuxiliaryLightest,
        'backgroundAuxiliaryLightest',
        'Background of group members and unread messages'
      ),
      (style.colors.acceptAuxiliaryColor, 'acceptAuxiliaryColor', 'User panel'),
      (style.colors.acceptColor, 'acceptColor', 'Call accept button'),
      (style.colors.dangerColor, 'dangerColor', 'Warns of something'),
      (style.colors.declineColor, 'declineColor', 'End call button'),
      (style.colors.warningColor, 'warningColor', 'Do not disturb status'),
    ];

    final List<Color> avatars = style.colors.userColors;

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate(
            [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 0 : 16,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    const Header(label: 'Palette'),
                    const SmallHeader(label: 'Color schema'),
                    ColorSchemaWidget(
                      colors.map((e) => (e.$1, e.$2)),
                      inverted: inverted,
                    ),
                    const SizedBox(height: 16),
                    const SmallHeader(label: 'Colors'),
                    BuilderWrap(
                      colors,
                      (e) => ColorWidget(
                        e.$1,
                        inverted: inverted,
                        subtitle: e.$2,
                        hint: e.$3,
                      ),
                      inverted: inverted,
                    ),
                    const SizedBox(height: 16),
                    const SmallHeader(label: 'Avatars'),
                    BuilderWrap(
                      avatars,
                      (e) => ColorWidget(e, inverted: inverted),
                      inverted: inverted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
