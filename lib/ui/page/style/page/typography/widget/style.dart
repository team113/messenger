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

/// [Container] which represents [Text] with a specific [style].
class FontStyle extends StatelessWidget {
  const FontStyle(
    this.inverted, {
    super.key,
    required this.style,
    this.title,
    this.color,
    this.label = 'Black',
  });

  /// Indicator whether this [FontStyle] should have its colors
  /// inverted.
  final bool inverted;

  /// Label of this [FontStyle].
  final String? title;

  /// Description that represents the color of the [style].
  final String label;

  /// [TextStyle] defining the font style for this [FontStyle].
  final TextStyle? style;

  /// [Color] of [style].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return SizedBox(
      height: 245,
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          if (title != null)
            Center(
              child: Text(
                title!,
                style: style!.copyWith(
                  color: color ??
                      (inverted
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF000000)),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Divider(
            color: inverted ? const Color(0xFFFFFFFF) : const Color(0xFFE8E8E8),
            indent: 25,
            endIndent: 25,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DefaultTextStyle(
                style: fonts.bodySmall!.copyWith(
                  color: inverted
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF888888),
                ),
                child: Flexible(
                  child: SizedBox(
                    height: 130,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Text('Size'),
                              Expanded(
                                child: Divider(
                                  indent: 5,
                                  endIndent: 5,
                                  color: inverted
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFFE8E8E8),
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
                                  indent: 5,
                                  endIndent: 5,
                                  color: inverted
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFFE8E8E8),
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
                                  indent: 5,
                                  endIndent: 5,
                                  color: inverted
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFFE8E8E8),
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
                                  indent: 5,
                                  endIndent: 5,
                                  color: inverted
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFFE8E8E8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('Spacing'),
                              Expanded(
                                child: Divider(
                                  indent: 5,
                                  endIndent: 5,
                                  color: inverted
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFFE8E8E8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: DefaultTextStyle(
                  style: fonts.bodyMedium!.copyWith(
                    color: inverted
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF000000),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(style!.fontSize.toString()),
                        const SizedBox(height: 8),
                        Text(style!.fontWeight!.value.toString()),
                        const SizedBox(height: 8),
                        Text(_getFontWeightName(style!.fontWeight)),
                        const SizedBox(height: 8),
                        Text(label),
                        const SizedBox(height: 8),
                        style!.letterSpacing == null
                            ? const Text('0 %')
                            : Text('${style!.letterSpacing} %'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Returns the corresponding [fontWeight] name as a string.
  String _getFontWeightName(FontWeight? fontWeight) {
    final String fontWeightStyle;

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
