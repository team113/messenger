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
import '/ui/widget/widget_button.dart';

/// Single fixed-height [OutlinedButton] of a row that typically contains some
/// primary and subtitle text, and a leading icon as well.
class OutlinedRoundedButton extends StatefulWidget {
  const OutlinedRoundedButton({
    super.key,
    this.child,
    this.subtitle,
    this.leading,
    this.headline,
    this.onPressed,
    this.onLongPress,
    this.gradient,
    this.elevation = 0,
    this.color,
    this.disabled,
    this.maxWidth = 250 * 0.72,
    this.maxHeight,
    this.border,
    this.height = 42,
    this.shadows,
    this.style,
  });

  /// Primary content of this button.
  ///
  /// Typically a [Text] widget.
  final Widget? child;

  /// Additional content displayed below the [child].
  ///
  /// Typically a [Text] widget.
  final Widget? subtitle;

  /// Widget to display before the [child].
  ///
  /// Typically an [Icon] or a [CircleAvatar] widget.
  final Widget? leading;

  /// Optional headline [Widget].
  final Widget? headline;

  /// Callback, called when this button is tapped or activated other way.
  final VoidCallback? onPressed;

  /// Callback, called when this button is long-pressed.
  final VoidCallback? onLongPress;

  /// Background color of this button.
  final Color? color;

  /// Background color of this button, when [onPressed] is `null`.
  final Color? disabled;

  /// Gradient to use when filling this button.
  ///
  /// If this is specified, [color] has no effect.
  final Gradient? gradient;

  /// Z-coordinate at which this button should be placed relatively to its
  /// parent.
  ///
  /// This controls the size of the shadow below this button.
  final double elevation;

  /// Maximum width this button is allowed to occupy.
  final double maxWidth;

  /// Maximum height this button is allowed to occupy.
  final double? maxHeight;

  /// Height of this button.
  final double? height;

  /// [BoxShadow]s to apply to this button.
  final List<BoxShadow>? shadows;

  /// Optional [TextStyle] of this [OutlinedRoundedButton].
  final TextStyle? style;

  /// Optional [BorderSide] of this [OutlinedRoundedButton].
  final BorderSide? border;

  @override
  State<OutlinedRoundedButton> createState() => _OutlinedRoundedButtonState();
}

/// State of a [OutlinedRoundedButton] maintaining the [_hovered] indicator.
class _OutlinedRoundedButtonState extends State<OutlinedRoundedButton> {
  /// Indicator whether this [OutlinedRoundedButton] is hovered.
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final BorderRadius borderRadius = BorderRadius.circular(
      10.5 * ((widget.height ?? 42) / 42),
    );

    final border = OutlineInputBorder(
      borderSide: widget.border ?? BorderSide.none,
      borderRadius: borderRadius,
    );

    return WidgetButton(
      onPressed: widget.onPressed,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            boxShadow: widget.shadows,
            gradient: widget.gradient,
            borderRadius: borderRadius,
          ),
          child: InputDecorator(
            decoration: InputDecoration(
              contentPadding: widget.headline == null
                  ? EdgeInsets.zero
                  : const EdgeInsets.fromLTRB(16, 0, 16, 0),
              label: widget.headline,
              border: border,
              errorBorder: border,
              enabledBorder: border,
              focusedBorder: border,
              disabledBorder: border,
              focusedErrorBorder: border,
              filled: true,
              fillColor: widget.onPressed == null
                  ? widget.disabled ?? style.colors.secondaryHighlight
                  : _hovered
                  ? Color.alphaBlend(
                      style.colors.onBackgroundOpacity2,
                      widget.color ?? style.colors.onPrimary,
                    )
                  : widget.color ?? style.colors.onPrimary,
            ),
            child: Container(
              constraints: BoxConstraints(
                minHeight: widget.height ?? 0,
                maxHeight: widget.maxHeight ?? widget.height ?? double.infinity,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: widget.leading == null ? 0 : 8 * 0.7,
                vertical: 6 * 0.7,
              ),
              child: Row(
                children: [
                  if (widget.leading != null) ...[
                    const SizedBox(width: 8),
                    SizedBox(child: Center(child: widget.leading!)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: DefaultTextStyle.merge(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style:
                          widget.style ??
                          style.fonts.medium.regular.onBackground,
                      child: Center(
                        child: Padding(
                          padding: widget.leading == null
                              ? EdgeInsets.zero
                              : const EdgeInsets.only(left: 10 * 0.7),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(child: widget.child ?? Container()),
                              if (widget.subtitle != null)
                                const SizedBox(height: 1 * 0.7),
                              if (widget.subtitle != null)
                                DefaultTextStyle.merge(
                                  style: style.fonts.small.regular.onBackground,
                                  child: widget.subtitle!,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.leading != null) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      child: Center(
                        child: Opacity(opacity: 0, child: widget.leading!),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
