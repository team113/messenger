// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

/// [Tooltip] of a [hint].
class TooltipHint extends StatelessWidget {
  const TooltipHint({
    Key? key,
    required this.child,
    this.onTap,
    this.hint,
    this.verticalOffset,
  }) : super(key: key);

  /// Widget of this button.
  final Widget child;

  /// Callback, called when this button is pressed.
  final GestureTapCallback? onTap;

  /// Hint message of the [Tooltip].
  final String? hint;

  /// Vertical gap between the [child] and the displayed [hint].
  final double? verticalOffset;

  @override
  Widget build(BuildContext context) {
    return hint == null
        ? child
        : Tooltip(
            verticalOffset: verticalOffset,
            message: hint!,
            textStyle: Theme.of(context)
                .outlinedButtonTheme
                .style!
                .textStyle!
                .resolve({MaterialState.disabled})!.copyWith(
              fontSize: 13,
              color: Colors.white,
              shadows: const [
                Shadow(blurRadius: 6, color: Color(0xFF000000)),
                Shadow(blurRadius: 6, color: Color(0xFF000000)),
              ],
            ),
            decoration: const BoxDecoration(),
            child: child,
          );
  }
}
