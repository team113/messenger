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

import '/ui/widget/animated_button.dart';

/// [AnimatedButton] of the provided [child].
class StyleCard extends StatelessWidget {
  const StyleCard({
    super.key,
    this.onPressed,
    this.inverted = false,
    required this.child,
  });

  /// Indicator whether this [StyleCard] should have its colors inverted.
  final bool inverted;

  /// Callback, called when this [StyleCard] is pressed.
  final void Function()? onPressed;

  /// Child to display withing this card.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      decorator: (child) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: child,
      ),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        curve: Curves.bounceInOut,
        scale: inverted ? 1.1 : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: inverted ? 1 : 0.7,
          child: child,
        ),
      ),
    );
  }
}
