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
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:messenger/config.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/safe_scrollbar.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/platform_utils.dart';

import '/themes.dart';
import '/ui/page/style/widget/scrollable_column.dart';

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

    Iterable<(TextStyle, String)> fonts = [
      (style.fonts.displayLarge, 'onBackground'),
      (style.fonts.displayLargeOnPrimary, 'onPrimary'),
      (style.fonts.displayMedium, 'onBackground'),
      (style.fonts.displayMediumSecondary, 'secondary'),
      (style.fonts.displaySmall, 'onBackground'),
      (style.fonts.displaySmallOnPrimary, 'onPrimary'),
      (style.fonts.displaySmallSecondary, 'secondary'),
      (style.fonts.headlineLarge, 'onBackground'),
      (style.fonts.headlineLargeOnPrimary, 'onPrimary'),
      (style.fonts.headlineMedium, 'onBackground'),
      (style.fonts.headlineMediumOnPrimary, 'onPrimary'),
      (style.fonts.headlineSmall, 'onBackground'),
      (style.fonts.headlineSmallOnPrimary, 'onPrimary'),
      (
        style.fonts.headlineSmallOnPrimary.copyWith(
          shadows: [
            Shadow(blurRadius: 6, color: style.colors.onBackground),
            Shadow(blurRadius: 6, color: style.colors.onBackground),
          ],
        ),
        'onPrimary',
      ),
      (style.fonts.headlineSmallSecondary, 'secondary'),
      (style.fonts.titleLarge, 'onBackground'),
      (style.fonts.titleLargeOnPrimary, 'onPrimary'),
      (style.fonts.titleLargeSecondary, 'secondary'),
      (style.fonts.titleMedium, 'onBackground'),
      (style.fonts.titleMediumDanger, 'danger'),
      (style.fonts.titleMediumOnPrimary, 'onPrimary'),
      (style.fonts.titleMediumPrimary, 'primary'),
      (style.fonts.titleMediumSecondary, 'secondary'),
      (style.fonts.titleSmall, 'onBackground'),
      (style.fonts.titleSmallOnPrimary, 'onPrimary'),
      (style.fonts.labelLarge, 'onBackground'),
      (style.fonts.labelLargeOnPrimary, 'onPrimary'),
      (style.fonts.labelLargePrimary, 'primary'),
      (style.fonts.labelLargeSecondary, 'secondary'),
      (style.fonts.labelMedium, 'onBackground'),
      (style.fonts.labelMediumOnPrimary, 'onPrimary'),
      (style.fonts.labelMediumPrimary, 'primary'),
      (style.fonts.labelMediumSecondary, 'secondary'),
      (style.fonts.labelSmall, 'onBackground'),
      (style.fonts.labelSmallOnPrimary, 'onPrimary'),
      (style.fonts.labelSmallPrimary, 'primary'),
      (style.fonts.labelSmallSecondary, 'secondary'),
      (style.fonts.bodyLarge, 'onBackground'),
      (style.fonts.bodyLargePrimary, 'primary'),
      (style.fonts.bodyLargeSecondary, 'secondary'),
      (style.fonts.bodyMedium, 'onBackground'),
      (style.fonts.bodyMediumOnPrimary, 'onPrimary'),
      (style.fonts.bodyMediumPrimary, 'primary'),
      (style.fonts.bodyMediumSecondary, 'secondary'),
      (style.fonts.bodySmall, 'onBackground'),
      (style.fonts.bodySmallOnPrimary, 'onPrimary'),
      (style.fonts.bodySmallPrimary, 'primary'),
      (style.fonts.bodySmallSecondary, 'secondary'),
      (style.fonts.bodyTiny, 'onBackground'),
      (style.fonts.bodyTinyOnPrimary, 'onPrimary'),
    ];

    fonts = fonts.sorted(
      (a, b) => b.$1.fontSize?.compareTo(a.$1.fontSize ?? 0) ?? 0,
    );

    final List<(FontWeight, String, String)> families = [
      (
        FontWeight.w400,
        'Noto Sans Display Regular + Gapopa',
        'NotoSansDisplayG-Regular.ttf'
      ),
      (
        FontWeight.w700,
        'Noto Sans Display Bold + Gapopa',
        'NotoSansDisplayG-Bold.ttf'
      ),
    ];

    final Map<double, List<(TextStyle, String)>> styles = {};

    for (var f in fonts) {
      final List<(TextStyle, String)>? list = styles[f.$1.fontSize];
      if (list != null) {
        list.add(f);
      } else {
        styles[f.$1.fontSize!] = [f];
      }
    }

    for (var k in styles.keys) {
      styles[k]?.sort(
        (a, b) => b.$1.fontWeight!.index.compareTo(a.$1.fontWeight!.index),
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
                      '123¤G, G¤123, The quick brown fox jumps over the lazy dog${', the quick brown fox jumps over the lazy dog' * 10}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style.fonts.displayLarge.copyWith(
                        color: style.colors.onBackground,
                        fontWeight: e.$1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    WidgetButton(
                      onPressed: () async {
                        String? to;

                        if (!PlatformUtils.isWeb) {
                          to = await FilePicker.platform.saveFile(
                            fileName: e.$3,
                            lockParentWindow: true,
                          );

                          if (to == null) {
                            return;
                          }
                        }

                        await PlatformUtils.download(
                          '${Config.origin}/assets/assets/${e.$3}',
                          e.$3,
                          null,
                          path: to,
                        );

                        MessagePopup.success('${e.$3} downloaded');
                      },
                      child: Text(
                        e.$2,
                        style: style.fonts.labelSmallPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
              const SizedBox(height: 16),
              Text(
                'Font height is ${style.fonts.bodyLarge.height}, word spacing is ${style.fonts.bodyLarge.wordSpacing}, letter spacing is ${style.fonts.bodyLarge.letterSpacing}',
                style: style.fonts.labelMedium,
              ),
            ],
          ),
          ...styles.keys.map((e) {
            final String name = switch (e) {
              27 => 'Largest',
              24 => 'Larger',
              18 => 'Large',
              17 => 'Medium',
              15 => 'Normal',
              13 => 'Small',
              11 => 'Smaller',
              9 => 'Smallest',
              _ => '',
            };

            return Block(
              title: '$name (${e.toInt()} pt)',
              unconstrained: true,
              children: [
                ...styles[e]!.map((f) {
                  final String weight = switch (f.$1.fontWeight) {
                    FontWeight.w900 => 'heavy',
                    FontWeight.w800 => 'extraBold',
                    FontWeight.w700 => 'bold',
                    FontWeight.w600 => 'semiBold',
                    FontWeight.w500 => 'medium',
                    FontWeight.w400 => 'regular',
                    FontWeight.w300 => 'light',
                    FontWeight.w200 => 'extraLight',
                    FontWeight.w100 => 'thin',
                    _ => '',
                  };

                  final HSLColor hsl = HSLColor.fromColor(f.$1.color!);

                  final Color textColor = hsl.lightness > 0.7 || hsl.alpha < 0.4
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF000000);
                  final Color background =
                      hsl.lightness > 0.7 || hsl.alpha < 0.4
                          ? const Color(0xFF888888)
                          : const Color(0xFFFFFFFF);

                  return Container(
                    color: background,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '123¤G, G¤123 ${name.toLowerCase()}.$weight.${f.$2}',
                            style: f.$1,
                            textAlign: TextAlign.start,
                          ),
                        ),

                        // TODO: If not enough space, then this should be
                        //       display under the `Expanded`, or something.
                        Text(
                          'w${f.$1.fontWeight?.value}',
                          style: TextStyle(color: textColor),
                        ).fixedDigits(all: true),
                        Text(', ', style: TextStyle(color: textColor)),
                        WidgetButton(
                          onPressed: () async {
                            Clipboard.setData(
                              ClipboardData(
                                text: f.$1.color!.toHex(withAlpha: false),
                              ),
                            );

                            MessagePopup.success('Hash is copied');
                          },
                          child: Text(
                            f.$1.color!.toHex(withAlpha: false),
                            style: TextStyle(color: textColor),
                          ).fixedDigits(all: true),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
