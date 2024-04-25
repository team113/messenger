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

import '/themes.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import 'highlighted_container.dart';

/// Stylized grouped section of the provided [children].
class Block extends StatelessWidget {
  const Block({
    super.key,
    this.title,
    this.highlight = false,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.expanded,
    this.padding = defaultPadding,
    this.margin = defaultMargin,
    this.children = const [],
    this.background,
    this.headline,
    this.maxWidth = 400,
  });

  /// Optional header of this [Block].
  final String? title;

  /// Optional headline of this [Block].
  final String? headline;

  /// Indicator whether this [Block] should be highlighted.
  final bool highlight;

  /// [CrossAxisAlignment] to apply to the [children].
  final CrossAxisAlignment crossAxisAlignment;

  /// Indicator whether this [Block] should occupy the whole space, if `true`,
  /// or be fixed width otherwise.
  ///
  /// If not specified, then [MobileExtensionOnContext.isNarrow] is used.
  final bool? expanded;

  /// Padding to apply to the [children].
  final EdgeInsets padding;

  /// Margin to apply to the [Block].
  final EdgeInsets margin;

  /// [Widget]s to display.
  final List<Widget> children;

  /// Optional background [Color] of this [Block].
  final Color? background;

  /// Maximum width this [Block] should occupy.
  final double maxWidth;

  /// Default [Block.padding] of its contents.
  static const EdgeInsets defaultPadding = EdgeInsets.fromLTRB(32, 16, 32, 16);

  /// Default [Block.margin] to apply.
  static const EdgeInsets defaultMargin = EdgeInsets.fromLTRB(8, 4, 8, 4);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final InputBorder border = OutlineInputBorder(
      borderSide: BorderSide(
        color: style.primaryBorder.top.color,
        width: style.primaryBorder.top.width,
      ),
      borderRadius: BorderRadius.circular(15),
    );

    return HighlightedContainer(
      highlight: highlight == true,
      child: Center(
        child: Container(
          padding: margin,
          constraints: (expanded ?? context.isNarrow)
              ? null
              : BoxConstraints(maxWidth: maxWidth),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: background ?? style.messageColor,
              focusedBorder: border,
              errorBorder: border,
              enabledBorder: border,
              disabledBorder: border,
              focusedErrorBorder: border,
              contentPadding: const EdgeInsets.all(12),
              border: border,
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: padding,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    alignment: Alignment.topCenter,
                    curve: Curves.easeInOut,
                    child: Column(
                      crossAxisAlignment: crossAxisAlignment,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null) ...[
                          Center(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                              child: Text(
                                title!,
                                textAlign: TextAlign.center,
                                style: style.fonts.big.regular.onBackground,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        ...children,
                      ],
                    ),
                  ),
                ),
                if (headline != null)
                  Positioned(
                    child: Text(headline!, style: _headlineStyle(context)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the [TextStyle] to display [headline] with.
  TextStyle _headlineStyle(BuildContext context) {
    final style = Theme.of(context).style;

    if (background != null) {
      final HSLColor hsl = HSLColor.fromColor(background!);
      if (hsl.lightness < 0.5 && hsl.alpha > 0.2) {
        return style.fonts.small.regular.onPrimary;
      }
    }

    return style.fonts.small.regular.secondaryHighlightDarkest;
  }
}

/// [SvgIcons.editSmall] button to put into [Block.overlay].
///
/// Returns [Positioned], meaning it must be placed inside a [Stack].
class EditBlockButton extends StatelessWidget {
  const EditBlockButton({
    Key? key,
    this.onPressed,
    this.editing = false,
  })  : _key = key,
        super(key: null);

  /// Callback, called when button is pressed.
  final void Function()? onPressed;

  /// Indicator whether an [SvgIcons.closeSmallPrimary] should be displayed
  /// instead.
  final bool editing;

  /// [Key] to uniquely identify the [AnimatedButton].
  final Key? _key;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      child: Center(
        child: AnimatedButton(
          key: _key,
          onPressed: onPressed,
          decorator: (child) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 0, 6),
              child: child,
            );
          },
          child: editing
              ? const Padding(
                  padding: EdgeInsets.all(2),
                  child: SvgIcon(SvgIcons.closeSmallPrimary),
                )
              : const SvgIcon(SvgIcons.editSmall),
        ),
      ),
    );
  }
}
