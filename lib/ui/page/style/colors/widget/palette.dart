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
import 'custom_switcher.dart';

/// Colors tab view of the [Routes.style] page.
class PaletteWidget extends StatefulWidget {
  const PaletteWidget({super.key});

  @override
  State<PaletteWidget> createState() => _PaletteWidgetState();
}

/// State of a [PaletteWidget] used to keep the [isDarkMode] indicator.
class _PaletteWidgetState extends State<PaletteWidget> {
  /// Indicator whether this page is in dark mode.
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedContainer(
      width: MediaQuery.sizeOf(context).width,
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: isDarkMode ? style.colors.onBackground : style.colors.onPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.light_mode, color: style.colors.warningColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: CustomSwitcher(
                    onChanged: (b) => setState(() => isDarkMode = b),
                  ),
                ),
                const Icon(Icons.dark_mode, color: Color(0xFF1F3C5D)),
              ],
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              CustomColor(
                isDarkMode,
                style.colors.onBackground,
                title: 'onBackground',
                subtitle: 'Primary text color',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryBackground,
                title: 'secondaryBackground',
                subtitle: 'Background text and stroke',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryBackgroundLight,
                title: 'secondaryBackgroundLight',
                subtitle: 'Call background color',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryBackgroundLightest,
                title: 'secondaryBackgroundLightest',
                subtitle: 'Background color of avatar and call buttons',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondary,
                title: 'secondary',
                subtitle: 'Text and stroke color',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryHighlightDarkest,
                title: 'secondaryHighlightDarkest',
                subtitle:
                    'Color of inscriptions and icons over the background of the call',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryHighlightDark,
                title: 'secondaryHighlightDark',
                subtitle: 'Navigation bar button color',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryHighlight,
                title: 'secondaryHighlight',
                subtitle: 'Circular progress indicator color',
              ),
              CustomColor(
                isDarkMode,
                style.colors.background,
                title: 'background',
                subtitle: 'General background',
              ),
              CustomColor(
                isDarkMode,
                style.colors.secondaryOpacity87,
                title: 'secondaryOpacity87',
                subtitle:
                    'Color of a raised hand and a muted microphone in a call',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity50,
                title: 'onBackgroundOpacity50',
                subtitle: 'Attached file background color',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity40,
                title: 'onBackgroundOpacity40',
                subtitle: 'Color of the bottom chat bar',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity27,
                title: 'onBackgroundOpacity27',
                subtitle: 'Color of the floating bar shadow',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity20,
                title: 'onBackgroundOpacity20',
                subtitle: 'Color of the panel with buttons in the call',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity13,
                title: 'onBackgroundOpacity13',
                subtitle: 'Color of the video play/pause button',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity7,
                title: 'onBackgroundOpacity7',
                subtitle: 'Color of the dividers',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onBackgroundOpacity2,
                title: 'onBackgroundOpacity2',
                subtitle: 'Text color "Connecting", "Calling", etc. in a call',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onPrimary,
                title: 'onPrimary',
                subtitle: 'Color used on the left side of the profile page',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onPrimaryOpacity95,
                title: 'onPrimaryOpacity95',
                subtitle: 'Color of the message that was received',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onPrimaryOpacity50,
                title: 'onPrimaryOpacity50',
                subtitle:
                    'Outline color for call accept buttons with audio and video',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onPrimaryOpacity25,
                title: 'onPrimaryOpacity25',
                subtitle: 'Shadow color of forwarded messages',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onPrimaryOpacity7,
                title: 'onPrimaryOpacity7',
                subtitle: 'Additional background color for the call',
              ),
              CustomColor(
                isDarkMode,
                style.colors.backgroundAuxiliary,
                title: 'backgroundAuxiliary',
                subtitle: 'Active call color',
              ),
              CustomColor(
                isDarkMode,
                style.colors.backgroundAuxiliaryLight,
                title: 'backgroundAuxiliaryLight',
                subtitle: 'Profile background color',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onSecondaryOpacity88,
                title: 'onSecondaryOpacity88',
                subtitle: 'Color of the top draggable title bar',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onSecondary,
                title: 'onSecondary',
                subtitle: 'Call button color',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onSecondaryOpacity60,
                title: 'onSecondaryOpacity60',
                subtitle: 'Additional color for the top draggable title bar',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onSecondaryOpacity50,
                title: 'onSecondaryOpacity50',
                subtitle: 'Color of the buttons in the gallery',
              ),
              CustomColor(
                isDarkMode,
                style.colors.onSecondaryOpacity20,
                title: 'onSecondaryOpacity20',
                subtitle: 'Mobile selector color',
              ),
              CustomColor(
                isDarkMode,
                style.colors.primaryHighlight,
                title: 'primaryHighlight',
                subtitle: 'Dropdown menu color',
              ),
              CustomColor(
                isDarkMode,
                style.colors.primary,
                title: 'primary',
                subtitle: 'Color of inverted buttons and links',
              ),
              CustomColor(
                isDarkMode,
                style.colors.primaryHighlightShiniest,
                title: 'primaryHighlightShiniest',
                subtitle: 'Color of the read message',
              ),
              CustomColor(
                isDarkMode,
                style.colors.primaryHighlightLightest,
                title: 'primaryHighlightLightest',
                subtitle: 'Outline color of the read message',
              ),
              CustomColor(
                isDarkMode,
                style.colors.backgroundAuxiliaryLighter,
                title: 'backgroundAuxiliaryLighter',
                subtitle: 'Unload color',
              ),
              CustomColor(
                isDarkMode,
                style.colors.backgroundAuxiliaryLightest,
                title: 'backgroundAuxiliaryLightest',
                subtitle:
                    'Background color of group members and unread messages',
              ),
              CustomColor(
                isDarkMode,
                style.colors.acceptAuxiliaryColor,
                title: 'acceptAuxiliaryColor',
                subtitle: 'User panel color',
              ),
              CustomColor(
                isDarkMode,
                style.colors.acceptColor,
                title: 'acceptColor',
                subtitle: 'Color of the call accept button',
              ),
              CustomColor(
                isDarkMode,
                style.colors.dangerColor,
                title: 'dangerColor',
                subtitle: 'Color that warns of something',
              ),
              CustomColor(
                isDarkMode,
                style.colors.declineColor,
                title: 'declineColor',
                subtitle: 'Color of the end call button',
              ),
              CustomColor(
                isDarkMode,
                style.colors.warningColor,
                title: 'warningColor',
                subtitle: 'Do not disturb status color',
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
