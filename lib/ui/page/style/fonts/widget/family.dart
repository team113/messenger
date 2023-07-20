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

/// [AnimatedContainer] of application font families.
class FontFamiliesWidget extends StatelessWidget {
  const FontFamiliesWidget(this.inverted, {super.key});

  /// Indicator whether this [FontFamiliesWidget] should have its colors
  /// inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: inverted ? const Color(0xFF142839) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _FontFamily(
            inverted,
            label: 'SFUI-Light',
            textStyle: fonts.displayLarge!.copyWith(
              fontWeight: FontWeight.w300,
            ),
          ),
          Divider(color: inverted ? const Color(0xFFFFFFFF) : null),
          _FontFamily(
            inverted,
            label: 'SFUI-Regular',
            textStyle: fonts.displayLarge!.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          Divider(color: inverted ? const Color(0xFFFFFFFF) : null),
          _FontFamily(
            inverted,
            label: 'SFUI-Bold',
            textStyle: fonts.displayLarge!.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// [Column] of all characters in a specific font family.
class _FontFamily extends StatelessWidget {
  const _FontFamily(
    this.inverted, {
    required this.textStyle,
    this.label,
  });

  /// Indicator whether this [_FontFamily] should have its colors
  /// inverted.
  final bool inverted;

  /// Label of this [_FontFamily].
  final String? label;

  /// Text style of this [_FontFamily].
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          DefaultTextStyle(
            style: textStyle.copyWith(
              color:
                  inverted ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
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
                    fontSize: 40,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
