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
import 'package:messenger/themes.dart';

/// Stylized button with the optional [prefix] widget.
class PrefixButton extends StatelessWidget {
  const PrefixButton({
    super.key,
    this.text = '',
    this.onPressed,
    this.style,
    this.prefix,
  });

  /// [text] of this [PrefixButton].
  final String text;

  /// [TextStyle] of the [text].
  final TextStyle? style;

  /// Callback, called when this button is pressed.
  final void Function()? onPressed;

  /// [Widget] to display as a prefix.
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final BorderRadius borderRadius = BorderRadius.circular(
      15 * 0.72,
    );
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          constraints: const BoxConstraints(
            maxWidth: double.infinity,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: style.colors.onPrimary,
            borderRadius: borderRadius,
            border: Border.all(
              width: 0.5,
              color: style.colors.secondary,
            ),
          ),
          child: Material(
            color: style.colors.transparent,
            borderRadius: borderRadius,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: onPressed,
              hoverColor: style.colors.onBackgroundOpacity7,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 46,
                  maxHeight: double.infinity,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8 * 0.7,
                  vertical: 6 * 0.7,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: DefaultTextStyle.merge(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: style.fonts.titleLarge.copyWith(
                          color: onPressed == null
                              ? style.colors.onBackgroundOpacity40
                              : style.colors.onBackground,
                        ),
                        child: Center(
                          child: Text(
                            text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (prefix != null) IgnorePointer(child: prefix!),
      ],
    );
  }
}
