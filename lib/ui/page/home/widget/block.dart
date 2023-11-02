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
    this.padding = const EdgeInsets.fromLTRB(32, 16, 32, 16),
    this.children = const [],
    this.unconstrained = false,
    this.color,
    this.headlineColor,
    this.headline,
    this.expanded = const [],
    this.fade = false,
    this.margin,
  });

  /// Optional header of this [Block].
  final String? title;

  /// Indicator whether this [Block] should be highlighted.
  final bool highlight;

  /// [CrossAxisAlignment] to apply to the [children].
  final CrossAxisAlignment crossAxisAlignment;

  final List<Widget> expanded;

  /// Indicator whether this [Block] should occupy the whole space, if `true`,
  /// or be fixed width otherwise.
  ///
  /// If not specified, then [MobileExtensionOnContext.isNarrow] is used.
  final bool? unconstrained;

  /// Padding to apply to the [children].
  final EdgeInsets padding;

  /// [Widget]s to display.
  final List<Widget> children;

  final String? headline;

  final Color? color;
  final Color? headlineColor;

  final bool fade;
  final double? margin;

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
          padding: EdgeInsets.fromLTRB(
            8,
            margin ?? (headline == null ? 4 : 32),
            8,
            4,
          ),

          constraints: (unconstrained ?? context.isNarrow)
              ? null
              : const BoxConstraints(maxWidth: 400),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: color ?? style.messageColor,
              focusedBorder: border,
              errorBorder: border,
              enabledBorder: border,
              disabledBorder: border,
              focusedErrorBorder: border,
              contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                          crossAxisAlignment: crossAxisAlignment,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (title != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      title!,
                                      textAlign: TextAlign.center,
                                      style: style.fonts.big.regular.onBackground,
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
                            child: Column(
                              key: Key('${expanded.length}'),
                              crossAxisAlignment: crossAxisAlignment,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: double.infinity,
                                  color: style.colors.transparent,
                                ),
                                ...expanded,
                              ],
                            ),
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
                      style: style.fonts.small.regular.secondaryHighlightDarkest.copyWith(
                        color: headlineColor,
                      ),
                    ),
                  ),
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
