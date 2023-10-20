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

import '/themes.dart';

/// Custom styled [CupertinoButton].
class StyledCupertinoButton extends StatefulWidget {
  const StyledCupertinoButton({
    super.key,
    required this.label,
    this.padding = EdgeInsets.zero,
    this.onPressed,
    this.style,
  });

  /// Label to display.
  final String label;

  /// Callback, called when this button is pressed.
  final void Function()? onPressed;

  /// Padding to apply to the button.
  ///
  /// Meant to be used to manipulate clickable area.
  final EdgeInsets padding;

  /// [TextStyle] to apply to the [label].
  final TextStyle? style;

  @override
  State<StyledCupertinoButton> createState() => _StyledCupertinoButtonState();
}

/// State of a [StyledCupertinoButton] maintaining the [_hovered] and [_clicked]
/// indicators.
class _StyledCupertinoButtonState extends State<StyledCupertinoButton> {
  /// Indicator whether this button is hovered.
  bool _hovered = false;

  /// Indicator whether this button is pushed down.
  bool _clicked = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      opaque: false,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onLongPressUp: () => setState(() => _clicked = false),
        onLongPressCancel: () => setState(() => _clicked = false),
        onTapDown: (_) => setState(() => _clicked = true),
        onTapUp: (_) {
          setState(() => _clicked = false);
          widget.onPressed?.call();
        },
        child: Padding(
          padding: widget.padding,
          child: AnimatedDefaultTextStyle(
            curve: Curves.ease,
            duration: const Duration(milliseconds: 100),
            style: (widget.style ?? style.fonts.small.regular.secondary),
            child: Opacity(
              opacity: _clicked
                  ? 0.5
                  : _hovered
                      ? 0.7
                      : 1,
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}
