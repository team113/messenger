// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import '/ui/widget/outlined_rounded_button.dart';

import '/themes.dart';
import '/ui/widget/text_field.dart';

/// [ReactiveTextField]-styled button.
class FieldButton extends StatefulWidget {
  const FieldButton({
    super.key,
    this.text,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.onPressed,
    this.onTrailingPressed,
    this.trailing,
    this.style,
    this.subtitle,
    this.headline,
    this.warning = false,
    this.danger = false,
  });

  /// Optional label of this [FieldButton].
  final String? text;

  /// [TextAlign] of the [text].
  final TextAlign textAlign;

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

  /// Optional subtitle [Widget].
  final Widget? subtitle;

  /// Optional headline [Widget].
  final Widget? headline;

  /// [TextStyle] of the [text].
  final TextStyle? style;

  /// Indicator whether this [FieldButton] should have warning style.
  final bool warning;

  /// Indicator whether the [text] should have danger color.
  final bool danger;

  @override
  State<FieldButton> createState() => _FieldButtonState();
}

/// State of a [FieldButton] maintaining the [_hovered] indicator.
class _FieldButtonState extends State<FieldButton> {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      children: [
        OutlinedRoundedButton(
          maxWidth: double.infinity,
          color: widget.warning ? style.colors.primary : style.colors.onPrimary,
          disabled: style.colors.onPrimary,
          onPressed: widget.onPressed,
          style: (widget.style ?? style.fonts.medium.regular.onBackground)
              .copyWith(
            // Exception, as [widget.style] may vary.
            color: widget.onPressed == null
                ? style.colors.onBackgroundOpacity40
                : widget.warning
                    ? style.colors.onPrimary
                    : widget.danger
                        ? style.colors.danger
                        : style.colors.onBackground,
          ),
          height: 46,
          leading: Transform.translate(
            offset: const Offset(0, 1),
            child: widget.trailing,
          ),
          headline: widget.headline,
          maxHeight: double.infinity,
          border: BorderSide(width: 0.5, color: style.colors.secondary),
          child: Text(widget.text ?? '', maxLines: widget.maxLines),
        ),
        if (widget.subtitle != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: widget.subtitle,
            ),
          ),
      ],
    );
  }
}
