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
    this.headline,
    this.headlineColor,
    this.underline,
    this.background,
    this.fade = false,
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

  final Widget? underline;

  final Color? background;
  final Color? headlineColor;

  /// Maximum width this [Block] should occupy.
  final double maxWidth;

  final bool fade;

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
        // color: style.colors.secondary,
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
              : const BoxConstraints(maxWidth: 400),
          // constraints: (context.isNarrow || unconstrained)
          //     ? const BoxConstraints.tightForFinite()
          //     : const BoxConstraints(maxWidth: 400),
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
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: crossAxisAlignment,
                          children: [
                            if (title != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      0,
                                      12,
                                      6,
                                    ),
                                    child: Text(
                                      title!,
                                      textAlign: TextAlign.center,
                                      style:
                                          style.fonts.big.regular.onBackground,
                                    ),
                                  ),
                                ),
                              ),
                            ...children,
                          ],
                        ),
                        IgnorePointer(
                          child: AnimatedSwitcher(
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            duration: const Duration(milliseconds: 300),
                            layoutBuilder: (current, previous) {
                              List<Widget> children = previous;

                              if (current != null) {
                                if (previous.isEmpty) {
                                  children = [current];
                                } else {
                                  children = [
                                    Positioned(
                                      left: 0.0,
                                      right: 0.0,
                                      child: Container(child: previous[0]),
                                    ),
                                    current,
                                  ];
                                }
                              }

                              return Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.topCenter,
                                children: children,
                              );
                            },
                            // child: Column(
                            //   key: Key('${expanded.length}'),
                            //   crossAxisAlignment: crossAxisAlignment,
                            //   mainAxisSize: MainAxisSize.min,
                            //   children: [
                            //     Container(
                            //       width: double.infinity,
                            //       color: style.colors.transparent,
                            //     ),
                            //     ...expanded,
                            //   ],
                            // ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (headline != null)
                  Positioned(
                    child: Text(
                      headline!,
                      style: style.fonts.small.regular.onBackground.copyWith(
                        color: headlineColor ??
                            style.colors.secondaryHighlightDarkest,
                      ),
                    ),
                  ),
                if (underline != null)
                  Positioned(top: 0, right: 0, child: underline!),
                if (fade)
                  Positioned.fill(
                    child: Column(
                      children: [
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          height: 100,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0, 0.7, 0.9, 1],
                              colors: [
                                Color(0x00FFFFFF),
                                Color(0xFFFFFFFF),
                                Color(0xFFFFFFFF),
                                Color(0xFFFFFFFF),
                              ],
                            ),
                          ),
                        ),
                      ],
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
