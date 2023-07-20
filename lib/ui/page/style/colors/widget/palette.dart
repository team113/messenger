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
import 'color.dart';
import 'color_builder.dart';

/// Palette of application colors.
class PaletteWidget extends StatelessWidget {
  const PaletteWidget(this.inverted, {super.key});

  /// Indicator whether this [PaletteWidget] should have its colors inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedWrap(
      inverted,
      children: [
        ColorWidget(
          inverted,
          style.colors.onBackground,
          subtitle: 'onBackground',
          hint: 'Primary text',
        ),
        ColorWidget(
          inverted,
          style.colors.secondaryBackground,
          subtitle: 'secondaryBackground',
          hint: 'Background text and stroke',
        ),
        ColorWidget(
          inverted,
          style.colors.secondaryBackgroundLight,
          subtitle: 'secondaryBackgroundLight',
          hint: 'Call background',
        ),
        ColorWidget(
          inverted,
          style.colors.secondaryBackgroundLightest,
          subtitle: 'secondaryBackgroundLightest',
          hint: 'Background of avatar and call buttons',
        ),
        ColorWidget(
          inverted,
          style.colors.secondary,
          subtitle: 'secondary',
          hint: 'Text and stroke',
        ),
        ColorWidget(
          inverted,
          style.colors.secondaryHighlightDarkest,
          subtitle: 'secondaryHighlightDarkest',
          hint: 'Inscriptions and icons over the background of the call',
        ),
        ColorWidget(
          inverted,
          style.colors.secondaryHighlightDark,
          subtitle: 'secondaryHighlightDark',
          hint: 'Navigation bar button',
        ),
        ColorWidget(
          inverted,
          style.colors.secondaryHighlight,
          subtitle: 'secondaryHighlight',
          hint: 'Circular progress indicator',
        ),
        ColorWidget(
          inverted,
          style.colors.background,
          subtitle: 'background',
          hint: 'General background',
        ),
        ColorWidget(
          inverted,
          style.colors.secondaryOpacity87,
          subtitle: 'secondaryOpacity87',
          hint: 'Raised hand and a muted microphone in a call',
        ),
        ColorWidget(
          inverted,
          style.colors.onBackgroundOpacity50,
          subtitle: 'onBackgroundOpacity50',
          hint: 'Attached file background',
        ),
        ColorWidget(
          inverted,
          style.colors.onBackgroundOpacity40,
          subtitle: 'onBackgroundOpacity40',
          hint: 'Bottom chat bar',
        ),
        ColorWidget(
          inverted,
          style.colors.onBackgroundOpacity27,
          subtitle: 'onBackgroundOpacity27',
          hint: 'Floating bar shadow',
        ),
        ColorWidget(
          inverted,
          style.colors.onBackgroundOpacity20,
          subtitle: 'onBackgroundOpacity20',
          hint: 'Panel with buttons in the call',
        ),
        ColorWidget(
          inverted,
          style.colors.onBackgroundOpacity13,
          subtitle: 'onBackgroundOpacity13',
          hint: 'Video play/pause button',
        ),
        ColorWidget(
          inverted,
          style.colors.onBackgroundOpacity7,
          subtitle: 'onBackgroundOpacity7',
          hint: 'Dividers',
        ),
        ColorWidget(
          inverted,
          style.colors.onBackgroundOpacity2,
          subtitle: 'onBackgroundOpacity2',
          hint: 'Text "Connecting", "Calling", etc. in a call',
        ),
        ColorWidget(
          inverted,
          style.colors.onPrimary,
          subtitle: 'onPrimary',
          hint: 'Left side of the profile page',
        ),
        ColorWidget(
          inverted,
          style.colors.onPrimaryOpacity95,
          subtitle: 'onPrimaryOpacity95',
          hint: 'Message that was received',
        ),
        ColorWidget(
          inverted,
          style.colors.onPrimaryOpacity50,
          subtitle: 'onPrimaryOpacity50',
          hint: 'Outline call accept buttons with audio and video',
        ),
        ColorWidget(
          inverted,
          style.colors.onPrimaryOpacity25,
          subtitle: 'onPrimaryOpacity25',
          hint: 'Shadow of forwarded messages',
        ),
        ColorWidget(
          inverted,
          style.colors.onPrimaryOpacity7,
          subtitle: 'onPrimaryOpacity7',
          hint: 'Additional background for the call',
        ),
        ColorWidget(
          inverted,
          style.colors.backgroundAuxiliary,
          subtitle: 'backgroundAuxiliary',
          hint: 'Active call',
        ),
        ColorWidget(
          inverted,
          style.colors.backgroundAuxiliaryLight,
          subtitle: 'backgroundAuxiliaryLight',
          hint: 'Profile background',
        ),
        ColorWidget(
          inverted,
          style.colors.onSecondaryOpacity88,
          subtitle: 'onSecondaryOpacity88',
          hint: 'Top draggable subtitle bar',
        ),
        ColorWidget(
          inverted,
          style.colors.onSecondary,
          subtitle: 'onSecondary',
          hint: 'Call button',
        ),
        ColorWidget(
          inverted,
          style.colors.onSecondaryOpacity60,
          subtitle: 'onSecondaryOpacity60',
          hint: 'Additional top draggable subtitle bar',
        ),
        ColorWidget(
          inverted,
          style.colors.onSecondaryOpacity50,
          subtitle: 'onSecondaryOpacity50',
          hint: 'Buttons in the gallery',
        ),
        ColorWidget(
          inverted,
          style.colors.onSecondaryOpacity20,
          subtitle: 'onSecondaryOpacity20',
          hint: 'Mobile selector',
        ),
        ColorWidget(
          inverted,
          style.colors.primaryHighlight,
          subtitle: 'primaryHighlight',
          hint: 'Dropdown menu',
        ),
        ColorWidget(
          inverted,
          style.colors.primary,
          subtitle: 'primary',
          hint: 'Inverted buttons and links',
        ),
        ColorWidget(
          inverted,
          style.colors.primaryHighlightShiniest,
          subtitle: 'primaryHighlightShiniest',
          hint: 'Read message',
        ),
        ColorWidget(
          inverted,
          style.colors.primaryHighlightLightest,
          subtitle: 'primaryHighlightLightest',
          hint: 'Outline of the read message',
        ),
        ColorWidget(
          inverted,
          style.colors.backgroundAuxiliaryLighter,
          subtitle: 'backgroundAuxiliaryLighter',
          hint: 'Unload',
        ),
        ColorWidget(
          inverted,
          style.colors.backgroundAuxiliaryLightest,
          subtitle: 'backgroundAuxiliaryLightest',
          hint: 'Background of group members and unread messages',
        ),
        ColorWidget(
          inverted,
          style.colors.acceptAuxiliaryColor,
          subtitle: 'acceptAuxiliaryColor',
          hint: 'User panel',
        ),
        ColorWidget(
          inverted,
          style.colors.acceptColor,
          subtitle: 'acceptColor',
          hint: 'Call accept button',
        ),
        ColorWidget(
          inverted,
          style.colors.dangerColor,
          subtitle: 'dangerColor',
          hint: 'Warns of something',
        ),
        ColorWidget(
          inverted,
          style.colors.declineColor,
          subtitle: 'declineColor',
          hint: 'End call button',
        ),
        ColorWidget(
          inverted,
          style.colors.warningColor,
          subtitle: 'warningColor',
          hint: 'Do not disturb status',
        ),
      ],
    );
  }
}
