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
              subtitle: 'onBackground',
              hint: 'Primary text',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryBackground,
              subtitle: 'secondaryBackground',
              hint: 'Background text and stroke',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryBackgroundLight,
              subtitle: 'secondaryBackgroundLight',
              hint: 'Call background',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryBackgroundLightest,
              subtitle: 'secondaryBackgroundLightest',
              hint: 'Background of avatar and call buttons',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondary,
              subtitle: 'secondary',
              hint: 'Text and stroke',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryHighlightDarkest,
              subtitle: 'secondaryHighlightDarkest',
              hint: 'Inscriptions and icons over the background of the call',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryHighlightDark,
              subtitle: 'secondaryHighlightDark',
              hint: 'Navigation bar button',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryHighlight,
              subtitle: 'secondaryHighlight',
              hint: 'Circular progress indicator',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.background,
              subtitle: 'background',
              hint: 'General background',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.secondaryOpacity87,
              subtitle: 'secondaryOpacity87',
              hint: 'Raised hand and a muted microphone in a call',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity50,
              subtitle: 'onBackgroundOpacity50',
              hint: 'Attached file background',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity40,
              subtitle: 'onBackgroundOpacity40',
              hint: 'Bottom chat bar',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity27,
              subtitle: 'onBackgroundOpacity27',
              hint: 'Floating bar shadow',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity20,
              subtitle: 'onBackgroundOpacity20',
              hint: 'Panel with buttons in the call',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity13,
              subtitle: 'onBackgroundOpacity13',
              hint: 'Video play/pause button',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity7,
              subtitle: 'onBackgroundOpacity7',
              hint: 'Dividers',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onBackgroundOpacity2,
              subtitle: 'onBackgroundOpacity2',
              hint: 'Text "Connecting", "Calling", etc. in a call',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onPrimary,
              subtitle: 'onPrimary',
              hint: 'Left side of the profile page',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onPrimaryOpacity95,
              subtitle: 'onPrimaryOpacity95',
              hint: 'Message that was received',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onPrimaryOpacity50,
              subtitle: 'onPrimaryOpacity50',
              hint: 'Outline call accept buttons with audio and video',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onPrimaryOpacity25,
              subtitle: 'onPrimaryOpacity25',
              hint: 'Shadow of forwarded messages',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onPrimaryOpacity7,
              subtitle: 'onPrimaryOpacity7',
              hint: 'Additional background for the call',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.backgroundAuxiliary,
              subtitle: 'backgroundAuxiliary',
              hint: 'Active call',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.backgroundAuxiliaryLight,
              subtitle: 'backgroundAuxiliaryLight',
              hint: 'Profile background',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onSecondaryOpacity88,
              subtitle: 'onSecondaryOpacity88',
              hint: 'Top draggable subtitle bar',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onSecondary,
              subtitle: 'onSecondary',
              hint: 'Call button',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onSecondaryOpacity60,
              subtitle: 'onSecondaryOpacity60',
              hint: 'Additional top draggable subtitle bar',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onSecondaryOpacity50,
              subtitle: 'onSecondaryOpacity50',
              hint: 'Buttons in the gallery',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.onSecondaryOpacity20,
              subtitle: 'onSecondaryOpacity20',
              hint: 'Mobile selector',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.primaryHighlight,
              subtitle: 'primaryHighlight',
              hint: 'Dropdown menu',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.primary,
              subtitle: 'primary',
              hint: 'Inverted buttons and links',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.primaryHighlightShiniest,
              subtitle: 'primaryHighlightShiniest',
              hint: 'Read message',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.primaryHighlightLightest,
              subtitle: 'primaryHighlightLightest',
              hint: 'Outline of the read message',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.backgroundAuxiliaryLighter,
              subtitle: 'backgroundAuxiliaryLighter',
              hint: 'Unload',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.backgroundAuxiliaryLightest,
              subtitle: 'backgroundAuxiliaryLightest',
              hint: 'Background of group members and unread messages',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.acceptAuxiliaryColor,
              subtitle: 'acceptAuxiliaryColor',
              hint: 'User panel',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.acceptColor,
              subtitle: 'acceptColor',
              hint: 'Call accept button',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.dangerColor,
              subtitle: 'dangerColor',
              hint: 'Warns of something',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.declineColor,
              subtitle: 'declineColor',
              hint: 'End call button',
            ),
            ColorWidget(
              isDarkMode,
              style.colors.warningColor,
              subtitle: 'warningColor',
              hint: 'Do not disturb status',
            ),
          ],
        ),
      ),
    );
  }
}
