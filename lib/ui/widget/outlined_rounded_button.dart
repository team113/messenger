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
import 'package:messenger/ui/widget/widget_button.dart';

import '/themes.dart';

/// Single fixed-height [OutlinedButton] of a row that typically contains some
/// primary and subtitle text, and a leading icon as well.
class OutlinedRoundedButton extends StatefulWidget {
  const OutlinedRoundedButton({
    super.key,
    this.child,
    this.subtitle,
    this.leading,
    this.trailing,
    // this.leadingWidth = 24
    this.leadingWidth,
    this.onPressed,
    this.onLongPress,
    this.gradient,
    this.elevation = 0,
    this.color,
    this.disabled,
    this.maxWidth = 250 * 0.72,
    this.maxHeight,
    this.border,
    // this.maxWidth = 210,
    this.height = 42,
    this.shadows,
    this.style,
    this.headline,
  });

  /// Primary content of this button.
  ///
  /// Typically a [Text] widget.
  final Widget? child;

  /// Additional content displayed below the [title].
  ///
  /// Typically a [Text] widget.
  final Widget? subtitle;

  /// Widget to display before the [title].
  ///
  /// Typically an [Icon] or a [CircleAvatar] widget.
  final Widget? leading;
  final Widget? trailing;

  /// Callback, called when this button is tapped or activated other way.
  final VoidCallback? onPressed;

  /// Callback, called when this button is long-pressed.
  final VoidCallback? onLongPress;

  /// Background color of this button.
  final Color? color;
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
  final double? maxHeight;

  /// Height of this button.
  final double? height;

  /// [BoxShadow]s to apply to this button.
  final List<BoxShadow>? shadows;

  final double? leadingWidth;

  final TextStyle? style;

  final Border? border;

  final Widget? headline;

  @override
  State<OutlinedRoundedButton> createState() => _OutlinedRoundedButtonState();
}

class _OutlinedRoundedButtonState extends State<OutlinedRoundedButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final BorderRadius borderRadius = BorderRadius.circular(
      15 * 0.7, // * ((widget.height ?? 42) / 42),
    );

    final border = OutlineInputBorder(
      borderSide: widget.border?.bottom ?? BorderSide.none,
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
                          style.colors.onBackgroundOpacity7,
                          widget.color ?? style.colors.onPrimary,
                        )
                      : widget.color ?? style.colors.onPrimary,
            ),
            child: Container(
              constraints: BoxConstraints(
                minHeight: widget.height ?? 0,
                maxHeight: widget.maxHeight ?? widget.height ?? double.infinity,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8 * 0.7,
                vertical: 6 * 0.7,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  // if (leading != null) leading!,
                  if (widget.leading != null) ...[
                    SizedBox(
                      width: widget.leadingWidth,
                      child: Center(child: widget.leading!),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: DefaultTextStyle.merge(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: widget.style ??
                          style.fonts.medium.regular.onBackground,
                      child: Center(
                        child: Padding(
                          padding: widget.leading == null
                              ? EdgeInsets.zero
                              : const EdgeInsets.only(left: 10 * 0.7),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              widget.child ?? Container(),
                              if (widget.child != null &&
                                  widget.subtitle != null)
                                const SizedBox(height: 3),
                              if (widget.subtitle != null)
                                DefaultTextStyle.merge(
                                  style: style.fonts.smallest.regular.secondary,
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
                    // if (leading != null) Opacity(opacity: 0, child: leading!),

                    SizedBox(
                      width: widget.leadingWidth,
                      child: Center(
                          child: Opacity(opacity: 0, child: widget.leading!)),
                    ),
                  ],
                  if (widget.trailing != null) widget.trailing!,
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
