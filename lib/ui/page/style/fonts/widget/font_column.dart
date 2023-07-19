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
import 'package:messenger/util/message_popup.dart';

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
      // height: 755,
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF142839) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }
}

/// Custom-styled [Text] with information.
class _CustomFont extends StatelessWidget {
  const _CustomFont(
    this.isDarkMode, {
    this.title,
    this.style,
  });

  /// Indicator whether the dark mode is enabled or not.
  final bool isDarkMode;

  /// Title of this [_CustomFont].
  final String? title;

  /// TextStyle of this [_CustomFont].
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return LayoutBuilder(
      builder: (context, constraints) {
        final Widget child;

        if (constraints.maxWidth < 300) {
          child = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                GestureDetector(
                  onTap: () {
                    MessagePopup.success(
                      '${style!.fontSize} pt, w${style!.fontWeight?.value}',
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    child: Text(
                      title!,
                      style: style!.copyWith(
                        color: isDarkMode
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF000000),
                      ),
                    ),
                  ),
                ),
            ],
          );
        } else {
          child = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              children: [
                Column(
                  children: [
                    if (title != null)
                      SizedBox(
                        width: 180,
                        child: Text(
                          title!,
                          style: style!.copyWith(
                            color: isDarkMode
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFF000000),
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  '${style!.fontSize} pt, w${style!.fontWeight?.value}',
                  style: fonts.titleMedium?.copyWith(
                    color: isDarkMode
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF000000),
                  ),
                ),
              ],
            ),
          );
        }

        return AnimatedSize(
          curve: Curves.ease,
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
    );
  }
}
