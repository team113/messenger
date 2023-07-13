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

/// Wrap with [_FontStyleContainer]s.
class FontStyleWidget extends StatelessWidget {
  const FontStyleWidget(this.isDarkMode, {super.key});

  /// Indicator whether the dark mode is enabled or not.
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        _FontStyleContainer(
          isDarkMode,
          label: 'displayLarge',
          style: fonts.displayLarge!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'displayMedium',
          style: fonts.displayMedium!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'displaySmall',
          style: fonts.displaySmall!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'headlineLarge',
          style: fonts.headlineLarge!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'headlineMedium',
          style: fonts.headlineMedium!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'headlineSmall',
          style: fonts.headlineSmall!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'titleLarge',
          style: fonts.titleLarge!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'titleMedium',
          style: fonts.titleMedium!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'titleSmall',
          style: fonts.titleSmall!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'labelLarge',
          style: fonts.labelLarge!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'labelMedium',
          style: fonts.labelMedium!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'labelSmall',
          style: fonts.labelSmall!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'bodyLarge',
          style: fonts.bodyLarge!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'bodyMedium',
          style: fonts.bodyMedium!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'bodySmall',
          style: fonts.bodySmall!,
        ),
        _FontStyleContainer(
          isDarkMode,
          label: 'linkStyle',
          style: style.linkStyle,
          color: 'Blue',
        ),
      ],
    );
  }
}

/// [AnimatedContainer] which represents [Text] with a specific [style].
class _FontStyleContainer extends StatelessWidget {
  const _FontStyleContainer(
    this.isDarkMode, {
    this.label,
    required this.style,
    this.color = 'Black',
  });

  /// Indicator whether the dark mode is enabled or not.
  final bool isDarkMode;

  /// Label of this [_FontStyleContainer].
  final String? label;

  /// Description that represents the color of the [style].
  final String color;

  /// TextStyle defining the font style for this [_FontStyleContainer].
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: 270,
      width: 290,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF142839) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            if (label != null)
              Center(
                child: Text(
                  label!,
                  style: style.copyWith(
                    color: isDarkMode
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF000000),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Divider(color: isDarkMode ? const Color(0xFFFFFFFF) : null),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DefaultTextStyle(
                  style: fonts.bodySmall!.copyWith(
                    color: isDarkMode
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF888888),
                  ),
                  child: SizedBox(
                    height: 130,
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Text('Size'),
                            Expanded(
                              child: Divider(
                                indent: 10,
                                endIndent: 10,
                                color:
                                    isDarkMode ? const Color(0xFFFFFFFF) : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Weight'),
                            Expanded(
                              child: Divider(
                                indent: 10,
                                endIndent: 10,
                                color:
                                    isDarkMode ? const Color(0xFFFFFFFF) : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Style'),
                            Expanded(
                              child: Divider(
                                indent: 10,
                                endIndent: 10,
                                color:
                                    isDarkMode ? const Color(0xFFFFFFFF) : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Color'),
                            Expanded(
                              child: Divider(
                                indent: 10,
                                endIndent: 10,
                                color:
                                    isDarkMode ? const Color(0xFFFFFFFF) : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Letter spacing'),
                            Expanded(
                              child: Divider(
                                indent: 10,
                                endIndent: 10,
                                color:
                                    isDarkMode ? const Color(0xFFFFFFFF) : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                DefaultTextStyle(
                  style: fonts.bodyMedium!.copyWith(
                    color: isDarkMode
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF000000),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(style.fontSize.toString()),
                        const SizedBox(height: 8),
                        Text(style.fontWeight!.value.toString()),
                        const SizedBox(height: 8),
                        Text(_getFontWeightName(style.fontWeight)),
                        const SizedBox(height: 8),
                        Text(color),
                        const SizedBox(height: 8),
                        style.letterSpacing == null
                            ? const Text('0 %')
                            : Text('${style.letterSpacing} %'),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the corresponding [fontWeight] name as a string.
  String _getFontWeightName(FontWeight? fontWeight) {
    String fontWeightStyle = '';

    switch (fontWeight) {
      case FontWeight.w100:
        fontWeightStyle = 'Thin';
        break;
      case FontWeight.w200:
        fontWeightStyle = 'Extra-light';
        break;
      case FontWeight.w300:
        fontWeightStyle = 'Light';
        break;
      case FontWeight.w400:
        fontWeightStyle = 'Regular';
        break;
      case FontWeight.w500:
        fontWeightStyle = 'Medium';
        break;
      case FontWeight.w600:
        fontWeightStyle = 'Semi-bold';
        break;
      case FontWeight.w700:
        fontWeightStyle = 'Bold';
        break;
      case FontWeight.w800:
        fontWeightStyle = 'Extra-bold';
        break;
      case FontWeight.w900:
        fontWeightStyle = 'Black';
        break;
      default:
        fontWeightStyle = 'Regular';
        break;
    }

    return fontWeightStyle;
  }
}
