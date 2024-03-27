import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/donate.dart';
import 'package:messenger/ui/page/home/page/chat/widget/embossed_text.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/util/fixed_digits.dart';
import 'package:messenger/util/platform_utils.dart';

class NominalCard extends StatelessWidget {
  const NominalCard({
    super.key,
    this.amount = 0,
  });

  final int amount;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final String asset = switch (amount) {
      == 0 => 'card_custom',
      <= 100 => 'card_100',
      <= 500 => 'card_500',
      <= 1000 => 'card_1000',
      <= 5000 => 'card_5000',
      // <= 10000 => 'card_10000',
      (_) => 'card_10000',
    };

    final Color color = switch (amount) {
      == 0 => Colors.white,
      <= 100 => const Color.fromRGBO(185, 179, 169, 1).lighten(0.05),
      <= 500 => const Color.fromRGBO(99, 146, 121, 1).lighten(0.05),
      <= 1000 => const Color.fromRGBO(179, 96, 133, 1).lighten(0.05),
      <= 5000 => const Color.fromRGBO(77, 65, 219, 1).lighten(0.1),
      // <= 10000 => const Color.fromRGBO(99, 146, 121, 1),
      (_) => const Color.fromRGBO(64, 64, 64, 1).lighten(0.2),
    };

    final List<Shadow> light = [
      Shadow(
        offset: const Offset(1, 1),
        blurRadius: 1,
        color: color.lighten(0.05),
      ),
      Shadow(
        offset: const Offset(-0.5, -0.5),
        blurRadius: 1,
        color: color.lighten(0.05),
      ),
    ];

    final List<Shadow> dark = [
      Shadow(
        offset: const Offset(1, -1),
        blurRadius: 2,
        color: color.darken(0.3),
      ),
      Shadow(
        offset: const Offset(-1, 1),
        blurRadius: 2,
        color: color.darken(0.3),
      ),
    ];

    final List<Shadow> shadows = [
      if (PlatformUtils.isWeb) ...[
        ...dark,
        ...light,
      ] else ...[
        ...light,
        ...dark,
      ],
    ];

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 32.27 / 20.26,
          child: SvgImage.asset('assets/images/$asset.svg'),
        ),
        Positioned.fill(
          child: FittedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 96),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...'1234 1234 1234 1234'.embossedDigits(
                        style: style.fonts.medium.regular.onBackground.copyWith(
                          fontSize: 32,
                        ),
                        color: color,
                        shadows: shadows,
                      ),
                    ],
                  ),
                  // child: EmbossedText.rich(
                  //   '1234 1234 1234 1234'.embossedDigits(),
                  //   style: style.fonts.largest.regular.onBackground
                  //       .copyWith(fontSize: 27),
                  //   color: color,
                  //   shadows: shadows,
                  // ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(27, 0, 24, 0),
                  child: EmbossedText(
                    'FIRST LAST',
                    style: style.fonts.largest.regular.onBackground
                        .copyWith(fontSize: 18),
                    color: color,
                    shadows: shadows,
                  ),
                )
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: FittedBox(
            // fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(27, 0, 27, 64),
              child: Text(
                '¤ ${amount.withSpaces()}',
                style: style.fonts.largest.regular.onBackground.copyWith(
                  fontSize: 42,
                  // color: style.colors.onPrimary,
                  color: amount == 0
                      ? style.colors.onBackground
                      : style.colors.onPrimary,
                ),
              ).fixedDigits(all: true, size: 11),
              // child: EmbossedText(
              //   '¤ ${amount.withSpaces()}',
              //   style: style.fonts.largest.regular.onBackground
              //       .copyWith(fontSize: 42),
              //   color: Colors.white,
              //   shadows: shadows,
              // ),
            ),
          ),
        ),

        // Positioned.fill(
        //   child: Center(
        //     child: EmbossedText(
        //       '¤${amount.withSpaces()}',
        //       style: style.fonts.largest.regular.onBackground
        //           .copyWith(fontSize: 38),
        //       color: color,
        //       shadows: shadows,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

extension on num {
  String withSpaces() {
    return NumberFormat('#,##0').format(this);
  }
}
