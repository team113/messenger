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

class FontFamiliesView extends StatelessWidget {
  const FontFamiliesView({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return Column(
      children: [
        FontWidget(
          isDarkMode: isDarkMode,
          label: 'SFUI-Light',
          textStyle: fonts.displayLarge!.copyWith(fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 30),
        FontWidget(
          isDarkMode: isDarkMode,
          label: 'SFUI-Regular',
          textStyle: fonts.displayLarge!.copyWith(
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 30),
        FontWidget(
          isDarkMode: isDarkMode,
          label: 'SFUI-Bold',
          textStyle: fonts.displayLarge!,
        ),
      ],
    );
  }
}

class FontWidget extends StatelessWidget {
  const FontWidget({
    super.key,
    required this.textStyle,
    required this.label,
    required this.isDarkMode,
  });

  final bool isDarkMode;

  final String label;

  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Stack(
      children: [
        AnimatedContainer(
          height: 300,
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            color:
                isDarkMode ? style.colors.onBackground : style.colors.onPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 32),
            child: DefaultTextStyle(
              style: textStyle.copyWith(
                color: isDarkMode
                    ? style.colors.onPrimary
                    : style.colors.onBackground,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                  SizedBox(height: 40),
                  Text('abcdefghijklmnopqrstuvwxyz'),
                  SizedBox(height: 40),
                  Padding(
                    padding: EdgeInsets.only(bottom: 25),
                    child: Row(
                      children: [
                        Text('1234567890'),
                        SizedBox(width: 50),
                        Text('_-–—.,:;!?()[]{}|©=+£€\$&%№«»“”˚*')
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 0,
          child: Text(
            label,
            style: fonts.displayLarge!.copyWith(
              color: const Color(0xFFF5F5F5),
              fontSize: 55,
            ),
          ),
        ),
      ],
    );
  }
}
