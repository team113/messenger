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

/// Column of [_CustomFont]s.
class FontColumnWidget extends StatelessWidget {
  const FontColumnWidget(this.inverted, {super.key});

  /// Indicator whether this [FontColumnWidget] should have its colors
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CustomFont(
                  inverted,
                  title: 'Display Large',
                  style: fonts.displayLarge,
                ),
                _CustomFont(
                  inverted,
                  title: 'Display Medium',
                  style: fonts.displayMedium,
                ),
                _CustomFont(
                  inverted,
                  title: 'Display Small',
                  style: fonts.displaySmall,
                ),
                _CustomFont(
                  inverted,
                  title: 'Headline Large',
                  style: fonts.headlineLarge,
                ),
                _CustomFont(
                  inverted,
                  title: 'Headline Medium',
                  style: fonts.headlineMedium,
                ),
                _CustomFont(
                  inverted,
                  title: 'Headline Small',
                  style: fonts.headlineSmall,
                ),
                _CustomFont(
                  inverted,
                  title: 'Title Large',
                  style: fonts.titleLarge,
                ),
                _CustomFont(
                  inverted,
                  title: 'Title Medium',
                  style: fonts.titleMedium,
                ),
                _CustomFont(
                  inverted,
                  title: 'Title Small',
                  style: fonts.titleSmall,
                ),
                _CustomFont(
                  inverted,
                  title: 'Label Large',
                  style: fonts.labelLarge,
                ),
                _CustomFont(
                  inverted,
                  title: 'Label Medium',
                  style: fonts.labelMedium,
                ),
                _CustomFont(
                  inverted,
                  title: 'Label Small',
                  style: fonts.labelSmall,
                ),
                _CustomFont(
                  inverted,
                  title: 'Body Large',
                  style: fonts.bodyLarge,
                ),
                _CustomFont(
                  inverted,
                  title: 'Body Medium',
                  style: fonts.bodyMedium,
                ),
                _CustomFont(
                  inverted,
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
    this.inverted, {
    this.title,
    this.style,
  });

  /// Indicator whether this [_CustomFont] should have its colors inverted.
  final bool inverted;

  /// Title of this [_CustomFont].
  final String? title;

  /// [TextStyle] of this [_CustomFont].
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return LayoutBuilder(
      builder: (context, constraints) {
        final Widget child;

        if (constraints.maxWidth < 305) {
          child = Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: style!.copyWith(
                      color: inverted
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFF000000),
                    ),
                  ),
                Text(
                  '${style!.fontSize} pt, w${style!.fontWeight?.value}',
                  style: fonts.titleMedium?.copyWith(
                    color: inverted
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF000000),
                  ),
                ),
              ],
            ),
          );
        } else {
          child = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              children: [
                if (title != null)
                  SizedBox(
                    width: 180,
                    child: Text(
                      title!,
                      style: style!.copyWith(
                        color: inverted
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF000000),
                      ),
                    ),
                  ),
                Text(
                  '${style!.fontSize} pt, w${style!.fontWeight?.value}',
                  style: fonts.titleMedium?.copyWith(
                    color: inverted
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
