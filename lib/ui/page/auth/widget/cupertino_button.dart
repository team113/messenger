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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Сustom [TextButton] featuring a Cupertino style design.
class CupertinoTextButton extends StatelessWidget {
  const CupertinoTextButton(
    this.data, {
    super.key,
    required this.onPressed,
    this.padding,
    this.color,
    this.disabledColor = CupertinoColors.quaternarySystemFill,
    this.minSize,
    this.pressedOpacity,
    this.borderRadius,
    this.alignment = Alignment.center,
  });

  /// Text to display.
  final String data;

  /// The amount of space to surround the child inside the bounds of the button.
  final EdgeInsetsGeometry? padding;

  /// Color of the button's background.
  final Color? color;

  /// The color of the button's background when the button is disabled.
  final Color disabledColor;

  /// Minimum size of the button.
  final double? minSize;

  /// The opacity that the button will fade to when it is pressed.
  final double? pressedOpacity;

  /// The radius of the button's corners when it has a background color.
  final BorderRadius? borderRadius;

  /// Alignment of the button's [child].
  final AlignmentGeometry alignment;

  /// Callback that is called when the button is tapped.
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        context.textTheme.bodySmall?.copyWith(color: Colors.black);
    final Color primary = Theme.of(context).colorScheme.primary;

    return CupertinoButton(
      onPressed: onPressed,
      padding: padding,
      color: color,
      disabledColor: disabledColor,
      minSize: minSize,
      pressedOpacity: pressedOpacity,
      borderRadius: borderRadius,
      alignment: alignment,
      child: Text(
        data,
        style: thin?.copyWith(fontSize: 13, color: primary),
      ),
    );
  }
}
