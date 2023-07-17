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

import '/l10n/l10n.dart';
import '/themes.dart';

/// Column of [_CustomFont]s.
class FontColumnWidget extends StatelessWidget {
  const FontColumnWidget(this.isDarkMode, {super.key});

  /// Indicator whether the dark mode is enabled or not.
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return AnimatedContainer(
      height: 755,
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF142839) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CustomFont(
                isDarkMode,
                title: 'Display Large',
                style: fonts.displayLarge,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Display Medium',
                style: fonts.displayMedium,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Display Small',
                style: fonts.displaySmall,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Headline Large',
                style: fonts.headlineLarge,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Headline Medium',
                style: fonts.headlineMedium,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Headline Small',
                style: fonts.headlineSmall,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Title Large',
                style: fonts.titleLarge,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Title Medium',
                style: fonts.titleMedium,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Title Small',
                style: fonts.titleSmall,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Label Large',
                style: fonts.labelLarge,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Label Medium',
                style: fonts.labelMedium,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Label Small',
                style: fonts.labelSmall,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Body Large',
                style: fonts.bodyLarge,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Body Medium',
                style: fonts.bodyMedium,
              ),
              _CustomFont(
                isDarkMode,
                title: 'Body Small',
                style: fonts.bodySmall,
              ),
            ],
          ),
          const Column(
            children: [],
          ),
        ],
      ),
    );
  }
}

///
class _CustomFont extends StatelessWidget {
  const _CustomFont(
    this.isDarkMode, {
    required this.title,
    this.style,
  });

  ///
  final bool isDarkMode;

  ///
  final String title;

  ///
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Row(
        children: [
          Column(
            children: [
              SizedBox(
                width: 180,
                child: Text(
                  title,
                  style: style!.copyWith(
                    color: isDarkMode
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF000000),
                  ),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Row(
                children: [
                  Text(
                    'Size: ${style!.fontSize}',
                    style: fonts.titleMedium?.copyWith(
                      color: isDarkMode
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF000000),
                    ),
                  ),
                  Text('space_vertical_space'.l10n),
                  Text(
                    'Font weight: ${style!.fontWeight?.value}',
                    style: fonts.titleMedium?.copyWith(
                      color: isDarkMode
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF000000),
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
