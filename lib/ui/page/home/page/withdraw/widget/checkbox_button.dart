// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';

/// Clickable [Checkbox] with a [label].
class CheckboxButton extends StatelessWidget {
  const CheckboxButton({
    super.key,
    this.value = false,
    this.onPressed,
    required this.label,
  }) : span = null;

  /// Builds a [CheckboxButton] from the [TextSpan].
  const CheckboxButton.rich({
    super.key,
    this.value = false,
    this.onPressed,
    required this.span,
  }) : label = null;

  /// Indicator whether [Checkbox] should be enabled.
  final bool value;

  /// Callback, called when this button is pressed.
  final void Function(bool s)? onPressed;

  /// Label to display alongside [Checkbox].
  final String? label;

  /// [TextSpan] to display alongside [Checkbox].
  final TextSpan? span;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return WidgetButton(
      onPressed: onPressed == null ? null : () => onPressed?.call(!value),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              child: Transform.translate(
                offset: PlatformUtils.isWeb
                    ? PlatformUtils.isMobile
                          ? const Offset(-5, 8)
                          : const Offset(-5, 4)
                    : const Offset(-5, 4),
                child: Transform.scale(
                  scale: 0.7,
                  child: IgnorePointer(
                    child: Checkbox(
                      splashRadius: 0,
                      visualDensity: VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                      value: value,
                      onChanged: (e) => onPressed?.call(e ?? false),
                      activeColor: style.colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                        side: BorderSide(color: style.colors.primary),
                      ),
                      fillColor: onPressed == null
                          ? WidgetStateColor.resolveWith(
                              (_) => value == true
                                  ? style.colors.secondaryHighlightDarkest
                                  : style.colors.secondaryHighlight,
                            )
                          : null,
                      checkColor: style.colors.onPrimary,
                      focusColor: style.colors.primary,
                      side: onPressed == null
                          ? BorderSide(
                              color: style.colors.secondaryHighlightDarkest,
                              width: 2,
                            )
                          : BorderSide(color: style.colors.primary, width: 2),
                    ),
                  ),
                ),
              ),
            ),
            span ??
                TextSpan(
                  text: label,
                  style: style.fonts.small.regular.secondary,
                ),
          ],
        ),
      ),
    );
  }
}
