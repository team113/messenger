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

/// Single fixed-height [OutlinedButton] of a row that typically contains some
/// primary and subtitle text, and a leading icon as well.
class OutlinedRoundedButton extends StatelessWidget {
  const OutlinedRoundedButton({
    super.key,
    this.title,
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
  });

  /// Primary content of this button.
  ///
  /// Typically a [Text] widget.
  final Widget? title;

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

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final BorderRadius borderRadius = BorderRadius.circular(
      15 * 0.7 * ((height ?? 42) / 42),
    );

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        boxShadow: shadows,
        color: onPressed == null
            ? disabled ?? style.colors.secondaryHighlight
            : color ?? style.colors.onPrimary,
        gradient: gradient,
        borderRadius: borderRadius,
        border: border,
      ),
      child: Material(
        color: style.colors.transparent,
        elevation: elevation,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onPressed,
          onLongPress: onLongPress,
          hoverColor: style.colors.onBackgroundOpacity7,
          child: Container(
            constraints: BoxConstraints(
              minHeight: height ?? 0,
              maxHeight: maxHeight ?? height ?? double.infinity,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 8 * 0.7,
              vertical: 6 * 0.7,
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                // if (leading != null) leading!,
                if (leading != null) ...[
                  SizedBox(width: leadingWidth, child: Center(child: leading!)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: DefaultTextStyle.merge(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: this.style ?? style.fonts.titleLarge,
                    child: Center(
                      child: Padding(
                        padding: leading == null
                            ? EdgeInsets.zero
                            : const EdgeInsets.only(left: 10 * 0.7),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            title ?? Container(),
                            if (subtitle != null)
                              const SizedBox(height: 1 * 0.7),
                            if (subtitle != null)
                              DefaultTextStyle.merge(
                                style: style.fonts.labelMedium,
                                child: subtitle!,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (leading != null) ...[
                  const SizedBox(width: 8),
                  // if (leading != null) Opacity(opacity: 0, child: leading!),

                  SizedBox(
                    width: leadingWidth,
                    child: Center(child: Opacity(opacity: 0, child: leading!)),
                  ),
                ],
                if (trailing != null) trailing!,
                const SizedBox(width: 8),
              ],
            ),
            // child: Stack(
            //   alignment: Alignment.centerLeft,
            //   children: [
            //     if (leading != null)
            //       Row(
            //         children: [
            //           Expanded(child: Center(child: leading)),
            //           Expanded(flex: 4, child: Container()),
            //           Expanded(child: Container()),
            //         ],
            //       ),
            //     DefaultTextStyle.merge(
            //       maxLines: 2,
            //       overflow: TextOverflow.ellipsis,
            //       textAlign: TextAlign.center,
            //       style: this.style ?? style.fonts.titleLarge,
            //       child: Center(
            //         child: Padding(
            //           padding: leading == null
            //               ? EdgeInsets.zero
            //               : const EdgeInsets.only(left: 10 * 0.7),
            //           child: Column(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             crossAxisAlignment: CrossAxisAlignment.center,
            //             children: [
            //               title ?? Container(),
            //               if (subtitle != null) const SizedBox(height: 1 * 0.7),
            //               if (subtitle != null)
            //                 DefaultTextStyle.merge(
            //                   style: style.fonts.labelLarge,
            //                   child: subtitle!,
            //                 ),
            //             ],
            //           ),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
          ),
        ),
      ),
    );
  }
}
