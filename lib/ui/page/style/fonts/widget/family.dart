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

/// Column of application font families.
class FontFamiliesWidget extends StatelessWidget {
  const FontFamiliesWidget(this.isDarkMode, {super.key});

  /// Indicator whether the dark mode is enabled or not.
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF142839) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _FontFamilyContainer(
            isDarkMode,
            label: 'SFUI-Light',
            textStyle:
                fonts.displayLarge!.copyWith(fontWeight: FontWeight.w300),
          ),
          Divider(color: isDarkMode ? Colors.white : null),
          _FontFamilyContainer(
            isDarkMode,
            label: 'SFUI-Regular',
            textStyle:
                fonts.displayLarge!.copyWith(fontWeight: FontWeight.w400),
          ),
          Divider(color: isDarkMode ? Colors.white : null),
          _FontFamilyContainer(
            isDarkMode,
            label: 'SFUI-Bold',
            textStyle:
                fonts.displayLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// [AnimatedContainer] that displays a specific font family.
class _FontFamilyContainer extends StatelessWidget {
  const _FontFamilyContainer(
    this.isDarkMode, {
    required this.textStyle,
    this.label,
  });

  /// Indicator whether the dark mode is enabled or not.
  final bool isDarkMode;

  /// Label of this [_FontFamilyContainer].
  final String? label;

  /// Text style of this [_FontFamilyContainer].
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Expanded(
            child: Column(
              children: [
                DefaultTextStyle(
                  style: textStyle.copyWith(
                    color: isDarkMode
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF000000),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                        SizedBox(height: 40),
                        Text('abcdefghijklmnopqrstuvwxyz'),
                        SizedBox(height: 40),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '1234567890',
                                softWrap: true,
                              ),
                            ),
                            SizedBox(width: 50),
                            Flexible(
                              child: Text(
                                '_-–—.,:;!?()[]{}|©=+£€\$&%№«»“”˚*',
                                softWrap: true,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (label != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        label!,
                        style: fonts.displayLarge!.copyWith(
                          color: const Color(0xFFF5F5F5),
                          fontSize: 28,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
