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
import 'package:get/get.dart';

import '/themes.dart';

/// [InkWell] button with a [Tooltip] of a [hint].
class TooltipButton extends StatelessWidget {
  const TooltipButton({
    super.key,
    this.child,
    this.onTap,
    this.hint,
    this.verticalOffset,
  });

  /// Widget of this button.
  final Widget? child;

  /// Callback, called when this button is pressed.
  final GestureTapCallback? onTap;

  /// Hint message of the [Tooltip].
  final String? hint;

  /// Vertical gap between the [child] and the displayed [hint].
  final double? verticalOffset;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    Widget button = InkWell(
      hoverColor: style.colors.transparent,
      highlightColor: style.colors.transparent,
      splashColor: style.colors.transparent,
      onTap: onTap,
      child: child,
    );

    return hint == null
        ? button
        : Tooltip(
            verticalOffset: verticalOffset,
            message: hint!,
            textStyle: context.theme.outlinedButtonTheme.style!.textStyle!
                .resolve({MaterialState.disabled})!.copyWith(
              fontSize: 13,
              color: style.colors.onPrimary,
              shadows: [
                Shadow(blurRadius: 6, color: style.colors.onBackground),
                Shadow(blurRadius: 6, color: style.colors.onBackground),
              ],
            ),
            decoration: const BoxDecoration(),
            child: button,
          );
  }
}
