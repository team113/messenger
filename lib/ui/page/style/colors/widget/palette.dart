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

/// Palette of application colors.
class PaletteWidget extends StatelessWidget {
  const PaletteWidget(this.isDarkMode, {super.key});

  /// Indicator whether the dark mode is enabled or not.
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedContainer(
      width: MediaQuery.sizeOf(context).width,
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF142839) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            ColorWidget(
              isDarkMode,
              style.colors.onBackground,
              title: 'onBackground',
              subtitle: 'Primary text color',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryBackground,
              title: 'secondaryBackground',
              subtitle: 'Background text and stroke',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryBackgroundLight,
              title: 'secondaryBackground\nLight',
              subtitle: 'Call background color',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryBackgroundLightest,
              title: 'secondaryBackground\nLightest',
              subtitle: 'Background color of avatar and call buttons',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondary,
              title: 'secondary',
              subtitle: 'Text and stroke color',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryHighlightDarkest,
              title: 'secondaryHighlight\nDarkest',
              subtitle:
                  'Color of inscriptions and icons over the background of the call',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryHighlightDark,
              title: 'secondaryHighlightDark',
              subtitle: 'Navigation bar button color',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryHighlight,
              title: 'secondaryHighlight',
              subtitle: 'Circular progress indicator color',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.background,
              title: 'background',
              subtitle: 'General background',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryOpacity87,
              title: 'secondaryOpacity87',
              subtitle:
                  'Color of a raised hand and a muted microphone in a call',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity50,
              title: 'onBackgroundOpacity50',
              subtitle: 'Attached file background color',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity40,
              title: 'onBackgroundOpacity40',
              subtitle: 'Color of the bottom chat bar',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity27,
              title: 'onBackgroundOpacity27',
              subtitle: 'Color of the floating bar shadow',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity20,
              title: 'onBackgroundOpacity20',
              subtitle: 'Color of the panel with buttons in the call',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity13,
              title: 'onBackgroundOpacity13',
              subtitle: 'Color of the video play/pause button',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity7,
              title: 'onBackgroundOpacity7',
              subtitle: 'Color of the dividers',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity2,
              title: 'onBackgroundOpacity2',
              subtitle: 'Text color "Connecting", "Calling", etc. in a call',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onPrimary,
              title: 'onPrimary',
              subtitle: 'Color used on the left side of the profile page',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onPrimaryOpacity95,
              title: 'onPrimaryOpacity95',
              subtitle: 'Color of the message that was received',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onPrimaryOpacity50,
              title: 'onPrimaryOpacity50',
              subtitle:
                  'Outline color for call accept buttons with audio and video',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onPrimaryOpacity25,
              title: 'onPrimaryOpacity25',
              subtitle: 'Shadow color of forwarded messages',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onPrimaryOpacity7,
              title: 'onPrimaryOpacity7',
              subtitle: 'Additional background color for the call',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.backgroundAuxiliary,
              title: 'backgroundAuxiliary',
              subtitle: 'Active call color',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.backgroundAuxiliaryLight,
              title: 'backgroundAuxiliaryLight',
              subtitle: 'Profile background color',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onSecondaryOpacity88,
              title: 'onSecondaryOpacity88',
              subtitle: 'Color of the top draggable title bar',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onSecondary,
              title: 'onSecondary',
              subtitle: 'Call button color',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onSecondaryOpacity60,
              title: 'onSecondaryOpacity60',
              subtitle: 'Additional color for the top draggable title bar',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onSecondaryOpacity50,
              title: 'onSecondaryOpacity50',
              subtitle: 'Color of the buttons in the gallery',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onSecondaryOpacity20,
              title: 'onSecondaryOpacity20',
              subtitle: 'Mobile selector color',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.primaryHighlight,
              title: 'primaryHighlight',
              subtitle: 'Dropdown menu color',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.primary,
              title: 'primary',
              subtitle: 'Color of inverted buttons and links',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.primaryHighlightShiniest,
              title: 'primaryHighlightShiniest',
              subtitle: 'Color of the read message',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.primaryHighlightLightest,
              title: 'primaryHighlightLightest',
              subtitle: 'Outline color of the read message',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.backgroundAuxiliaryLighter,
              title: 'backgroundAuxiliary\nLighter',
              subtitle: 'Unload color',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.backgroundAuxiliaryLightest,
              title: 'backgroundAuxiliary\nLightest',
              subtitle: 'Background color of group members and unread messages',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.acceptAuxiliaryColor,
              title: 'acceptAuxiliaryColor',
              subtitle: 'User panel color',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.acceptColor,
              title: 'acceptColor',
              subtitle: 'Color of the call accept button',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.dangerColor,
              title: 'dangerColor',
              subtitle: 'Color that warns of something',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.declineColor,
              title: 'declineColor',
              subtitle: 'Color of the end call button',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.warningColor,
              title: 'warningColor',
              subtitle: 'Do not disturb status color',
            ),
          ],
        ),
      ),
    );
  }
}
