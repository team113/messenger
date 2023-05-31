import 'dart:math';

import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import 'buttons.dart';

class WrapButtons extends StatelessWidget {
  const WrapButtons(
    this.constraints, {
    super.key,
    this.buttons = const [],
  });

  final BoxConstraints constraints;
  final List<ChatButton> buttons;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final int total = ((constraints.maxWidth - 220) / 50).floor() + 1;
    int count = ((constraints.maxWidth - 220) / 36).floor() + 1;
    int columns = (buttons.length / count).floor() + 1;

    if (count % columns == 0) {
      count ~/= columns;
    } else {
      count ~/= columns;
    }

    print('count $count columns $columns');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(columns, (i) {
        final List<ChatButton> sub = buttons.sublist(
          i * count,
          i == columns - 1 && total % columns != 0
              ? buttons.length
              : min((i * count) + count, buttons.length),
        );

        print(
          '(${i * count}, ${min((i * count) + count, buttons.length)}) $sub',
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: sub.map((e) {
            return WidgetButton(
              onPressed: () => e.onPressed?.call(true),
              child: MouseRegion(
                onEnter: (_) => e.onHovered?.call(true),
                // onExit: (_) => e.onHovered?.call(false),
                opaque: false,
                child: SizedBox(
                  key: e.key,
                  width: 36 + 4 + 4,
                  height: 56,
                  child: Center(
                    child: e.icon == null
                        ? Transform.translate(
                            offset: e.offset,
                            child: SvgImage.asset(
                              'assets/icons/${e.asset}.svg',
                              width: e.assetWidth,
                              height: e.assetHeight,
                            ),
                          )
                        : Icon(
                            e.icon,
                            size: 28,
                            color: style.colors.primary,
                          ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }
}
