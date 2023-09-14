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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/safe_scrollbar.dart';

import '/themes.dart';
import '/ui/page/style/widget/builder_wrap.dart';
import '/ui/page/style/widget/header.dart';
import '/ui/page/style/widget/scrollable_column.dart';
import 'widget/color.dart';
import 'widget/color_schema.dart';

/// View of the [StyleTab.colors] page.
class ColorsView extends StatefulWidget {
  const ColorsView({
    super.key,
    this.inverted = false,
    this.dense = false,
  });

  /// Indicator whether this view should have its colors inverted.
  final bool inverted;

  /// Indicator whether this view should be compact, meaning minimal [Padding]s.
  final bool dense;

  @override
  State<ColorsView> createState() => _ColorsViewState();
}

class _ColorsViewState extends State<ColorsView> {
  final ScrollController _scrollController = ScrollController();

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

    final Iterable<(Color, String?, String?)> avatars = style.colors.userColors
        .mapIndexed((i, color) => (color, 'userColors[$i]', null))
        .toList();

    return SafeScrollbar(
      controller: _scrollController,
      margin: const EdgeInsets.only(top: CustomAppBar.height - 10),
      child: ScrollableColumn(
        controller: _scrollController,
        children: [
          const SizedBox(height: 16 + 5),
          Block(
            title: 'Colors',
            unconstrained: true,
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            children: [
              ColorSchemaWidget(
                colors,
                inverted: widget.inverted,
                dense: widget.dense,
              ),
            ],
          ),
          Block(
            title: 'Avatars',
            unconstrained: true,
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            children: [
              ColorSchemaWidget(
                avatars,
                inverted: widget.inverted,
                dense: widget.dense,
              ),
            ],
          ),
          // const Header('Colors'),
          // const SizedBox(height: 16),
          // ColorSchemaWidget(
          //   colors,
          //   inverted: widget.inverted,
          //   dense: widget.dense,
          // ),
          // const SubHeader('Avatars'),
          // ColorSchemaWidget(
          //   avatars,
          //   inverted: widget.inverted,
          //   dense: widget.dense,
          // ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
