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
import 'package:messenger/util/platform_utils.dart';

import '/themes.dart';

/// Wrap with [_FontStyleContainer]s.
class FontStyleWidget extends StatelessWidget {
  const FontStyleWidget(this.inverted, {super.key});

  /// Indicator whether this [FontStyleWidget] should have its colors inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: context.isNarrow ? 5 : 16,
      runSpacing: 16,
      children: [
        _FontStyleContainer(
          inverted,
          title: 'displayLarge',
          style: fonts.displayLarge!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'displayMedium',
          style: fonts.displayMedium!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'displaySmall',
          style: fonts.displaySmall!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'headlineLarge',
          style: fonts.headlineLarge!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'headlineMedium',
          style: fonts.headlineMedium!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'headlineSmall',
          style: fonts.headlineSmall!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'titleLarge',
          style: fonts.titleLarge!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'titleMedium',
          style: fonts.titleMedium!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'titleSmall',
          style: fonts.titleSmall!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'labelLarge',
          style: fonts.labelLarge!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'labelMedium',
          style: fonts.labelMedium!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'labelSmall',
          style: fonts.labelSmall!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'bodyLarge',
          style: fonts.bodyLarge!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'bodyMedium',
          style: fonts.bodyMedium!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'bodySmall',
          style: fonts.bodySmall!,
        ),
        _FontStyleContainer(
          inverted,
          title: 'linkStyle',
          style: style.linkStyle,
          color: style.linkStyle.color,
          label: 'Blue',
        ),
      ],
    );
  }
}

/// [AnimatedContainer] which represents [Text] with a specific [style].
class _FontStyleContainer extends StatelessWidget {
  const _FontStyleContainer(
    this.inverted, {
    required this.style,
    this.title,
    this.color,
    this.label = 'Black',
  });

  /// Indicator whether this [_FontStyleContainer] should have its colors
  /// inverted.
  final bool inverted;

  /// Label of this [_FontStyleContainer].
  final String? title;

  /// Description that represents the color of the [style].
  final String label;

  /// TextStyle defining the font style for this [_FontStyleContainer].
  final TextStyle style;

  /// Color of [style].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 245,
      width: 245,
      decoration: BoxDecoration(
        color: inverted ? const Color(0xFF142839) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          if (title != null)
            Center(
              child: Text(
                title!,
                style: style.copyWith(
                  color: color ??
                      (inverted
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF000000)),
                ),
              ),
            ),
          const SizedBox(height: 20),
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
                        Text(style.fontSize.toString()),
                        const SizedBox(height: 8),
                        Text(style.fontWeight!.value.toString()),
                        const SizedBox(height: 8),
                        Text(_getFontWeightName(style.fontWeight)),
                        const SizedBox(height: 8),
                        Text(label),
                        const SizedBox(height: 8),
                        style.letterSpacing == null
                            ? const Text('0 %')
                            : Text('${style.letterSpacing} %'),
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
