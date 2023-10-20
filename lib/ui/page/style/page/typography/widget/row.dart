import 'dart:math';

import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/widget/widget_button.dart';
import '/util/fixed_digits.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [Row] describing visually the provided [font].
class FontRow extends StatelessWidget {
  const FontRow({
    required this.font,
    required this.size,
    required this.weight,
    required this.color,
    super.key,
  });

  /// [TextStyle] to describe.
  final TextStyle font;

  /// Size naming of this [font].
  final String size;

  /// Weight naming of this [font].
  final String weight;

  /// Color naming of this [font].
  final String color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final HSLColor hsl = HSLColor.fromColor(font.color!);

    final Color detailsColor = hsl.lightness > 0.7 || hsl.alpha < 0.4
        ? const Color(0xFFC4C4C4)
        : const Color(0xFF888888);

    final Color background = hsl.lightness > 0.7 || hsl.alpha < 0.4
        ? const Color(0xFF888888)
        : const Color(0xFFFFFFFF);

    return Container(
      color: background,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: WidgetButton(
                onPressed: () async {
                  PlatformUtils.copy(text: '$size.$weight.$color');
                  MessagePopup.success('Name is copied');
                },
                child: Text(
                  '$size.$weight.$color  ',
                  style: font,
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              0,
              0,
              max(
                0,
                ((font.fontSize! - 10) / (27 - 10)) * 5,
              ),
            ),
            child: Row(
              children: [
                Text(
                  'w${font.fontWeight?.value}, ',
                  style: style.fonts.smaller.regular.onBackground
                      .copyWith(color: detailsColor),
                ).fixedDigits(),
                WidgetButton(
                  onPressed: () async {
                    PlatformUtils.copy(
                      text: font.color!.toHex(withAlpha: false),
                    );
                    MessagePopup.success('Hash is copied');
                  },
                  child: Text(
                    font.color!.toHex(withAlpha: false),
                    style: style.fonts.smaller.regular.onBackground
                        .copyWith(color: detailsColor),
                  ).fixedDigits(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
