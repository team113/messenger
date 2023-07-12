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
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

import '/themes.dart';

/// Single fixed-height [OutlinedButton] of a row that typically contains some
/// primary and subtitle text, and a leading icon as well.
class OutlinedRoundedButton extends StatelessWidget {
  const OutlinedRoundedButton({
    Key? key,
    this.title,
    this.subtitle,
    this.leading,
    this.onPressed,
    this.onLongPress,
    this.gradient,
    this.elevation = 0,
    this.color,
    this.maxWidth = 250 * 0.7,
    // this.maxWidth = 210,
    this.height = 42,
    this.shadows,
    this.style,
  }) : super(key: key);

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

  /// Callback, called when this button is tapped or activated other way.
  final VoidCallback? onPressed;

  /// Callback, called when this button is long-pressed.
  final VoidCallback? onLongPress;

  /// Background color of this button.
  final Color? color;

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

  /// Height of this button.
  final double? height;

  /// [BoxShadow]s to apply to this button.
  final List<BoxShadow>? shadows;

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    // return Container(
    //   alignment: Alignment.center,
    //   constraints: BoxConstraints(
    //     maxWidth: maxWidth,
    //     minHeight: (height ?? 0) + 10,
    //     maxHeight: (height ?? double.infinity) + 10,
    //   ),
    //   child: NeumorphicButton(
    //     onPressed: onPressed,
    //     style: NeumorphicStyle(
    //       color: onPressed == null
    //           ? style.colors.secondaryHighlight
    //           : color ?? style.colors.onPrimary,
    //     ),
    //     child: Padding(
    //       padding: const EdgeInsets.symmetric(
    //         horizontal: 16 * 0.7,
    //         vertical: 6 * 0.7,
    //       ),
    //       child: Stack(
    //         alignment: Alignment.centerLeft,
    //         children: [
    //           if (leading != null)
    //             Row(
    //               children: [
    //                 Expanded(child: Center(child: leading)),
    //                 Expanded(flex: 4, child: Container()),
    //                 Expanded(child: Container()),
    //               ],
    //             ),
    //           Padding(
    //             padding: EdgeInsets.symmetric(
    //                 // horizontal: leading == null ? 0 : 16,
    //                 // vertical: 8,
    //                 ),
    //             child: DefaultTextStyle.merge(
    //               maxLines: 2,
    //               overflow: TextOverflow.ellipsis,
    //               textAlign: TextAlign.center,
    //               style: this.style ?? fonts.titleLarge,
    //               child: Center(
    //                 child: Padding(
    //                   padding: leading == null
    //                       ? EdgeInsets.zero
    //                       : const EdgeInsets.only(left: 10 * 0.7),
    //                   child: Column(
    //                     mainAxisAlignment: MainAxisAlignment.center,
    //                     crossAxisAlignment: CrossAxisAlignment.center,
    //                     children: [
    //                       title ?? Container(),
    //                       if (subtitle != null) const SizedBox(height: 1 * 0.7),
    //                       if (subtitle != null)
    //                         DefaultTextStyle.merge(
    //                           style: fonts.labelSmall,
    //                           child: subtitle!,
    //                         ),
    //                     ],
    //                   ),
    //                 ),
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );

    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        minHeight: height ?? 0,
        maxHeight: height ?? double.infinity,
      ),
      decoration: BoxDecoration(
        boxShadow: shadows,
        color: onPressed == null
            ? style.colors.secondaryHighlight
            : color ?? style.colors.onPrimary,
        gradient: gradient,
        borderRadius: BorderRadius.circular(15 * 0.7),
      ),
      child: Material(
        color: style.colors.transparent,
        elevation: elevation,
        borderRadius: BorderRadius.circular(15 * 0.7),
        child: InkWell(
          borderRadius: BorderRadius.circular(15 * 0.7),
          onTap: onPressed,
          onLongPress: onLongPress,
          hoverColor: style.colors.secondary.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16 * 0.7,
              vertical: 6 * 0.7,
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (leading != null)
                  Row(
                    children: [
                      Expanded(child: Center(child: leading)),
                      Expanded(flex: 4, child: Container()),
                      Expanded(child: Container()),
                    ],
                  ),
                DefaultTextStyle.merge(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: this.style ?? fonts.titleLarge,
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
                          if (subtitle != null) const SizedBox(height: 1 * 0.7),
                          if (subtitle != null)
                            DefaultTextStyle.merge(
                              style: fonts.labelMedium,
                              child: subtitle!,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
