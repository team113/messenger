import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '/themes.dart';

/// [Column] of the provided [colors] representing a [Color] scheme.
class ColorSchemaWidget extends StatelessWidget {
  const ColorSchemaWidget(this.colors, {super.key, this.inverted = false});

  /// Records of [Color]s and its descriptions to display.
  final Iterable<(Color, String)> colors;

  /// Indicator whether the background of this [ColorSchemaWidget] should be
  /// inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: inverted ? const Color(0xFF142839) : Colors.white,
      ),
      child: Column(
        children: colors.mapIndexed((i, e) {
          final HSLColor hsl = HSLColor.fromColor(e.$1);
          final Color text = hsl.lightness > 0.7 || hsl.alpha < 0.4
              ? Colors.black
              : Colors.white;
          final TextStyle style = fonts.bodySmall!.copyWith(color: text);

          return Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: e.$1,
              borderRadius: BorderRadius.only(
                topLeft: i == 0 ? const Radius.circular(16) : Radius.zero,
                topRight: i == 0 ? const Radius.circular(16) : Radius.zero,
                bottomLeft: i == colors.length - 1
                    ? const Radius.circular(16)
                    : Radius.zero,
                bottomRight: i == colors.length - 1
                    ? const Radius.circular(16)
                    : Radius.zero,
              ),
            ),
            child: Center(
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.$2, style: style)),
                  Text(e.$1.toHex(), style: style),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
