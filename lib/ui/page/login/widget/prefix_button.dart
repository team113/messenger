// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

/// Stylized [InkWell]-based button with the optional [prefix].
class PrefixButton extends StatelessWidget {
  const PrefixButton({
    super.key,
    this.title = '',
    this.subtitle,
    this.onPressed,
    this.style,
    this.prefix,
  });

  /// Title of this [PrefixButton].
  final String title;

  /// Title of this [PrefixButton].
  final String? subtitle;

  /// [TextStyle] of the [title].
  final TextStyle? style;

  /// Callback, called when this button is pressed.
  final void Function()? onPressed;

  /// [Widget] to display as a prefix.
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).style;

    final BorderRadius borderRadius = BorderRadius.circular(11);

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: styles.colors.onPrimary,
            borderRadius: borderRadius,
            border: Border.all(width: 0.5, color: styles.colors.secondary),
          ),
          child: Material(
            color: styles.colors.transparent,
            borderRadius: borderRadius,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: onPressed,
              hoverColor: styles.colors.onBackgroundOpacity7,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 46,
                  maxHeight: double.infinity,
                ),
                padding: const EdgeInsets.fromLTRB(13.6, 4.2, 13.6, 4.2),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: style,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: styles.fonts.small.regular.secondary,
                        ),
                    ],
                  ),
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
