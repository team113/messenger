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
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';

/// [ReactiveTextField]-styled button.
class FieldButton extends StatefulWidget {
  const FieldButton({
    super.key,
    this.text,
    this.textAlign = TextAlign.start,
    this.hint,
    this.maxLines = 1,
    this.onPressed,
    this.onTrailingPressed,
    this.trailing,
    this.prefix,
    this.style,
  });

  /// Optional label of this [FieldButton].
  final String? text;

  /// [TextAlign] of the [text].
  final TextAlign textAlign;

  /// Optional hint of this [FieldButton].
  final String? hint;

  /// Maximum number of lines to show at one time, wrapping if necessary.
  final int? maxLines;

  /// Callback, called when this [FieldButton] is pressed.
  final VoidCallback? onPressed;

  /// Callback, called when the [trailing] is pressed.
  ///
  /// Only meaningful if the [trailing] is `null`.
  final VoidCallback? onTrailingPressed;

  /// Optional trailing [Widget].
  final Widget? trailing;

  /// Optional prefix [Widget].
  final Widget? prefix;

  /// [TextStyle] of the [text].
  final TextStyle? style;

  @override
  State<FieldButton> createState() => _FieldButtonState();
}

/// State of a [FieldButton] maintaining the [_hovered] indicator.
class _FieldButtonState extends State<FieldButton> {
  /// Indicator whether this [FieldButton] is hovered.
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final Widget child = MouseRegion(
      onEnter: PlatformUtils.isMobile
          ? null
          : (_) => setState(() => _hovered = true),
      onExit: PlatformUtils.isMobile
          ? null
          : (_) => setState(() => _hovered = false),
      child: WidgetButton(
        behavior: HitTestBehavior.deferToChild,
        onPressed: widget.onPressed,
        child: IgnorePointer(
          child: ReactiveTextField(
            textAlign: widget.textAlign,
            state: TextFieldState(text: widget.text, editable: false),
            label: widget.hint,
            maxLines: widget.maxLines,
            trailing: widget.onTrailingPressed == null
                ? AnimatedScale(
                    duration: const Duration(milliseconds: 100),
                    scale: _hovered ? AnimatedButton.scale : 1,
                    child: Transform.translate(
                      offset: const Offset(0, 1),
                      child: widget.trailing,
                    ),
                  )
                : null,
            prefix: widget.prefix,
            style: widget.style,
            fillColor: _hovered && widget.onPressed != null
                ? style.colors.onPrimary.darken(0.03)
                : style.colors.onPrimary,
          ),
        ),
      ),
    );

    if (widget.trailing == null || widget.onTrailingPressed == null) {
      return child;
    }

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: AnimatedButton(
              onPressed: widget.onTrailingPressed,
              enabled: widget.onTrailingPressed != null,
              decorator: (child) {
                return SizedBox(
                  width: 50,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: child,
                    ),
                  ),
                );
              },
              child: widget.trailing!,
            ),
          ),
        ),
      ],
    );
  }
}
