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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/safe_scrollbar.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/themes.dart';
import '/ui/page/style/widget/builder_wrap.dart';
import '/ui/page/style/widget/header.dart';
import '/ui/page/style/widget/scrollable_column.dart';
import 'widget/family.dart';
import 'widget/font.dart';
import 'widget/style.dart';

/// View of the [StyleTab.typography] page.
class TypographyView extends StatefulWidget {
  const TypographyView({
    super.key,
    this.inverted = false,
    this.dense = false,
  });

  /// Indicator whether this view should have its colors inverted.
  final bool inverted;

  /// Indicator whether this view should be compact, meaning minimal [Padding]s.
  final bool dense;

  @override
  State<TypographyView> createState() => _TypographyViewState();
}

class _TypographyViewState extends State<TypographyView> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    // final Iterable<(TextStyle, String)> styles = [
    //   (style.fonts.displayLarge, 'displayLarge'),
    //   (style.fonts.displayMedium, 'displayMedium'),
    //   (style.fonts.displaySmall, 'displaySmall'),
    //   (style.fonts.headlineLarge, 'headlineLarge'),
    //   (style.fonts.headlineMedium, 'headlineMedium'),
    //   (style.fonts.headlineSmall, 'headlineSmall'),
    //   (style.fonts.titleLarge, 'titleLarge'),
    //   (style.fonts.titleMedium, 'titleMedium'),
    //   (style.fonts.titleSmall, 'titleSmall'),
    //   (style.fonts.labelLarge, 'labelLarge'),
    //   (style.fonts.labelMedium, 'labelMedium'),
    //   (style.fonts.labelSmall, 'labelSmall'),
    //   (style.fonts.bodyLarge, 'bodyLarge'),
    //   (style.fonts.bodyMedium, 'bodyMedium'),
    //   (style.fonts.bodySmall, 'bodySmall'),
    // ];

    Iterable<(TextStyle, String)> fonts = [
      (style.fonts.displayLarge, 'displayLarge'),
      (style.fonts.displayLargeOnPrimary, 'displayLargeOnPrimary'),
      (style.fonts.displayMedium, 'displayMedium'),
      (style.fonts.displayMediumSecondary, 'displayMediumSecondary'),
      (style.fonts.displaySmall, 'displaySmall'),
      (style.fonts.displaySmallOnPrimary, 'displaySmallOnPrimary'),
      (style.fonts.displaySmallSecondary, 'displaySmallSecondary'),
      (style.fonts.headlineLarge, 'headlineLarge'),
      (style.fonts.headlineLargeOnPrimary, 'headlineLarge'),
      (style.fonts.headlineMedium, 'headlineMedium'),
      (style.fonts.headlineMediumOnPrimary, 'headlineMedium'),
      (style.fonts.headlineSmall, 'headlineSmall'),
      (style.fonts.headlineSmallOnPrimary, 'headlineSmallOnPrimary'),
      (
        style.fonts.headlineSmallOnPrimary.copyWith(
          shadows: [
            Shadow(blurRadius: 6, color: style.colors.onBackground),
            Shadow(blurRadius: 6, color: style.colors.onBackground),
          ],
        ),
        'headlineSmallOnPrimary (shadows)',
      ),
      (style.fonts.headlineSmallSecondary, 'headlineSmall'),
      (style.fonts.titleLarge, 'titleLarge'),
      (style.fonts.titleLargeOnPrimary, 'titleLarge'),
      (style.fonts.titleLargeSecondary, 'titleLarge'),
      (style.fonts.titleMedium, 'titleMedium'),
      (style.fonts.titleMediumDanger, 'titleMediumDanger'),
      (style.fonts.titleMediumOnPrimary, 'titleMediumOnPrimary'),
      (style.fonts.titleMediumPrimary, 'titleMediumPrimary'),
      (style.fonts.titleMediumSecondary, 'titleMediumSecondary'),
      (style.fonts.titleSmall, 'titleSmall'),
      (style.fonts.titleSmallOnPrimary, 'titleSmallOnPrimary'),
      (style.fonts.labelLarge, 'labelLarge'),
      (style.fonts.labelLargeOnPrimary, 'labelLargeOnPrimary'),
      (style.fonts.labelLargePrimary, 'labelLargePrimary'),
      (style.fonts.labelLargeSecondary, 'labelLargeSecondary'),
      (style.fonts.labelMedium, 'labelMedium'),
      (style.fonts.labelMediumOnPrimary, 'labelMediumOnPrimary'),
      (style.fonts.labelMediumPrimary, 'labelMediumPrimary'),
      (style.fonts.labelMediumSecondary, 'labelMediumSecondary'),
      (style.fonts.labelSmall, 'labelSmall'),
      (style.fonts.labelSmallOnPrimary, 'labelSmallOnPrimary'),
      (style.fonts.labelSmallPrimary, 'labelSmallPrimary'),
      (style.fonts.labelSmallSecondary, 'labelSmallSecondary'),
      (style.fonts.bodyLarge, 'bodyLarge'),
      (style.fonts.bodyLargePrimary, 'bodyLargePrimary'),
      (style.fonts.bodyLargeSecondary, 'bodyLargeSecondary'),
      (style.fonts.bodyMedium, 'bodyMedium'),
      (style.fonts.bodyMediumOnPrimary, 'bodyMediumOnPrimary'),
      (style.fonts.bodyMediumPrimary, 'bodyMediumPrimary'),
      (style.fonts.bodyMediumSecondary, 'bodyMediumSecondary'),
      (style.fonts.bodySmall, 'bodySmall'),
      (style.fonts.bodySmallOnPrimary, 'bodySmallOnPrimary'),
      (style.fonts.bodySmallPrimary, 'bodySmallPrimary'),
      (style.fonts.bodySmallSecondary, 'bodySmallSecondary'),
    ];

    fonts = fonts.sorted(
      (a, b) => b.$1.fontSize?.compareTo(a.$1.fontSize ?? 0) ?? 0,
    );

    final List<(FontWeight, String)> families = [
      (FontWeight.w300, 'SFUI-Light'),
      (FontWeight.w400, 'SFUI-Regular'),
      (FontWeight.w700, 'SFUI-Bold'),
    ];

    final Map<double, List<TextStyle>> styles = {};

    for (var f in fonts) {
      final List<TextStyle>? list = styles[f.$1.fontSize];
      if (list != null) {
        list.add(f.$1);
      } else {
        styles[f.$1.fontSize!] = [f.$1];
      }
    }

    for (var k in styles.keys) {
      styles[k]?.sort(
        (a, b) => b.fontWeight!.index.compareTo(a.fontWeight!.index),
      );
    }

    return SafeScrollbar(
      controller: _scrollController,
      margin: const EdgeInsets.only(top: CustomAppBar.height - 10),
      child: ScrollableColumn(
        controller: _scrollController,
        children: [
          const SizedBox(height: 16 + 5),
          Block(
            unconstrained: true,
            title: 'Font families',
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...families.map((e) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The quick brown fox jumps over the lazy dog${', the quick brown fox jumps over the lazy dog' * 10}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style.fonts.displayLarge.copyWith(
                        color: style.colors.onBackground,
                        fontWeight: e.$1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    WidgetButton(
                      onPressed: () {},
                      child: Text(
                        e.$2,
                        style: style.fonts.labelSmallPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
            ],
          ),

          ...styles.keys.map((e) {
            return Block(
              title: 'Font $e',
              unconstrained: true,
              children: [
                ...styles[e]!.map((f) {
                  final HSLColor hsl = HSLColor.fromColor(f.color!);

                  final Color textColor = hsl.lightness > 0.7 || hsl.alpha < 0.4
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF000000);
                  final Color background =
                      hsl.lightness > 0.7 || hsl.alpha < 0.4
                          ? const Color(0xFF000000)
                          : const Color(0xFFFFFFFF);

                  return Container(
                    color: background,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'bold.onBackground',
                            style: f,
                            textAlign: TextAlign.start,
                          ),
                        ),
                        Text(
                          'w${f.fontWeight?.value}, ${f.color!.toHex(withAlpha: false)}',
                          style: TextStyle(color: textColor),
                        ).fixedDigits(all: true),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),

          // Block(
          //   title: 'Font 27',
          //   unconstrained: true,
          //   children: [
          //     Container(
          //       width: double.infinity,
          //       padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          //       child: Row(
          //         children: [
          //           Expanded(
          //             child: Text(
          //               'bold.onBackground',
          //               style: style.fonts.displayLarge,
          //               textAlign: TextAlign.start,
          //             ),
          //           ),
          //           const Text('w700, #FF0F0F0'),
          //         ],
          //       ),
          //     ),
          //     Container(
          //       width: double.infinity,
          //       padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          //       child: Row(
          //         children: [
          //           Expanded(
          //             child: Text(
          //               'bold.primary',
          //               style: style.fonts.displayLarge
          //                   .copyWith(color: style.colors.primary),
          //               textAlign: TextAlign.start,
          //             ),
          //           ),
          //           const Text('w700, #FF0F0F0'),
          //         ],
          //       ),
          //     ),
          //     Container(
          //       width: double.infinity,
          //       padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          //       child: Row(
          //         children: [
          //           Expanded(
          //             child: Text(
          //               'regular.onBackground',
          //               style: style.fonts.displayLarge
          //                   .copyWith(fontWeight: FontWeight.normal),
          //               textAlign: TextAlign.start,
          //             ),
          //           ),
          //           const Text('w400, #FF0F0F0'),
          //         ],
          //       ),
          //     ),
          //     Container(
          //       width: double.infinity,
          //       color: Colors.black,
          //       padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          //       child: Row(
          //         children: [
          //           Expanded(
          //             child: Text(
          //               'light.onBackground',
          //               style: style.fonts.displayLarge.copyWith(
          //                 fontWeight: FontWeight.w300,
          //                 color: style.colors.background,
          //               ),
          //               textAlign: TextAlign.start,
          //             ),
          //           ),
          //           const Text(
          //             'w300, #FF0F0F0',
          //             style: TextStyle(color: Colors.white),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),

          Block(
            title: 'Fonts',
            unconstrained: true,
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Text(
                  'bold27',
                  style: style.fonts.displayLarge,
                  textAlign: TextAlign.start,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(48, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'bold27.onBackground',
                        style: style.fonts.displayLarge,
                        textAlign: TextAlign.start,
                      ),
                    ),
                    const Text('#FF0F0F0'),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(48, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'bold27.primary',
                        style: style.fonts.displayLarge
                            .copyWith(color: style.colors.primary),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    const Text('#FF0F0F0'),
                  ],
                ),
              ),

              // ...fonts.map((e) {
              //   final HSLColor hsl = HSLColor.fromColor(e.$1.color!);
              //   final Color background = hsl.lightness > 0.7 || hsl.alpha < 0.4
              //       ? const Color(0xFF000000)
              //       : const Color(0xFFFFFFFF);

              //   return Container(
              //     color: background,
              //     width: double.infinity,
              //     padding: const EdgeInsets.all(8),
              //     child: Row(
              //       children: [
              //         Expanded(
              //           child: Text(
              //             // e.$2,
              //             e.$2 == 'displayLarge' ? 'bold27\$onBackround' : e.$2,
              //             style: e.$1,
              //             textAlign: TextAlign.start,
              //           ),
              //         ),
              //       ],
              //     ),
              //   );
              // }),
            ],
          ),

          // Block(
          //   title: 'Families',
          //   unconstrained: true,
          //   // padding: EdgeInsets.zero,
          //   children: [
          //     BuilderWrap(
          //       families,
          //       inverted: widget.inverted,
          //       dense: widget.dense,
          //       (e) => FontFamily(
          //         e,
          //         inverted: widget.inverted,
          //         dense: widget.dense,
          //       ),
          //     ),
          //   ],
          // ),
          // Block(
          //   title: 'Families',
          //   unconstrained: true,
          //   // padding: EdgeInsets.zero,
          //   children: [
          //     BuilderWrap(
          //       families,
          //       inverted: widget.inverted,
          //       dense: widget.dense,
          //       (e) => FontFamily(
          //         e,
          //         inverted: widget.inverted,
          //         dense: widget.dense,
          //       ),
          //     ),
          //   ],
          // ),
          // const Header('Typography'),
          // const SubHeader('Families'),
          // BuilderWrap(
          //   families,
          //   inverted: widget.inverted,
          //   dense: widget.dense,
          //   (e) =>
          //       FontFamily(e, inverted: widget.inverted, dense: widget.dense),
          // ),
          const SubHeader('Fonts'),
          BuilderWrap(
            fonts,
            inverted: widget.inverted,
            dense: widget.dense,
            (e) =>
                FontWidget(e, inverted: widget.inverted, dense: widget.dense),
          ),
          // const SubHeader('Typefaces'),
          // BuilderWrap(
          //   styles,
          //   inverted: widget.inverted,
          //   dense: widget.dense,
          //   (e) => FontWidget(
          //     (
          //       e.$1.copyWith(
          //         color: widget.inverted
          //             ? const Color(0xFFFFFFFF)
          //             : const Color(0xFF000000),
          //       ),
          //       e.$2,
          //     ),
          //     inverted: widget.inverted,
          //     dense: widget.dense,
          //   ),
          // ),
          const SubHeader('Styles'),
          BuilderWrap(
            [
              (style.fonts.displayLarge, 'displayLarge'),
              (style.fonts.displayMedium, 'displayMedium'),
              (style.fonts.displaySmall, 'displaySmall'),
              (style.fonts.headlineLarge, 'headlineLarge'),
              (style.fonts.headlineMedium, 'headlineMedium'),
              (style.fonts.headlineSmall, 'headlineSmall'),
              (style.fonts.titleLarge, 'titleLarge'),
              (style.fonts.titleMedium, 'titleMedium'),
              (style.fonts.titleSmall, 'titleSmall'),
              (style.fonts.labelLarge, 'labelLarge'),
              (style.fonts.labelMedium, 'labelMedium'),
              (style.fonts.labelSmall, 'labelSmall'),
              (style.fonts.bodyLarge, 'bodyLarge'),
              (style.fonts.bodyMedium, 'bodyMedium'),
              (style.fonts.bodySmall, 'bodySmall'),
            ],
            inverted: widget.inverted,
            dense: widget.dense,
            (e) => FontStyleWidget(e, inverted: widget.inverted),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
