import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import 'embossed_text.dart';

class DonateWidget extends StatelessWidget {
  const DonateWidget({
    super.key,
    this.donate = 0,
    this.header = const [],
    this.footer = const [],
    this.timestamp,
    this.transaction,
    this.title = '',
    this.onTitlePressed,
    this.height = 100,
  });

  final int donate;
  final List<Widget> header;
  final List<Widget> footer;
  final Widget? timestamp;
  final String? transaction;

  final double height;

  final String title;
  final void Function()? onTitlePressed;

  static const Color font = Color.fromRGBO(243, 205, 1, 1);

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final bar = Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        // gradient: outerGradient,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // transform: GradientRotation(3.6),
          colors: [
            Color(0xFFF9C924),
            Color(0xFFE4AF18),
            Color(0xFFFFF98C),
            Color(0xFFFFD440),
            // background: linear-gradient(180deg, #F9C924 0%, #E4AF18 32%, #FFF98C 68%, #FFD440 100%);
            // Color(0xFFECC440),
            // Color(0xFFFFFA8A),
            // Color(0xFFDDAC17),
            // Color(0xFFFFFF95),
            // background: linear-gradient(69.74deg, #ECC440 0%, #FFFA8A 32%, #DDAC17 68%, #FFFF95 100%);
          ],
          stops: [0, 0.32, 0.68, 1],
        ),
      ),
      child: Stack(
        children: [
          //             Positioned.fill(
          //               child: Container(
          //                 decoration: BoxDecoration(
          //                   borderRadius: BorderRadius.circular(8),
          //                   gradient: const LinearGradient(
          //                     transform: GradientRotation(-0.2),
          //                     begin: Alignment(-1, 0),
          //                     end: Alignment(1, 0),
          // // background: linear-gradient(79.22deg, #ECB800 4.81%, #FFDD64 19.3%, #C89C00 45.69%, #C99D01 54.15%, #E8B500 66.65%, #DFAE00 77.89%, #F2BD00 85.19%, #FFDD66 94.58%);
          //                     colors: [
          //                       Color(0xFFECB800),
          //                       Color(0xFFFFDD64),
          //                       Color(0xFFC89C00),
          //                       Color(0xFFC99D01),
          //                       Color(0xFFE8B500),
          //                       Color(0xFFDFAE00),
          //                       Color(0xFFF2BD00),
          //                       Color(0xFFFFDD66),
          //                     ],
          //                     stops: [
          //                       0.0481,
          //                       0.193,
          //                       0.4569,
          //                       0.5415,
          //                       0.6665,
          //                       0.7789,
          //                       0.8519,
          //                       0.9458,
          //                     ],
          //                   ),
          //                 ),
          //                 width: double.infinity,
          //                 height: double.infinity,
          //               ),
          //             ),
          // Основной градиент:
          // radial-gradient(73.88% 112.28% at 6.65% -23.76%, #FFFFFF 0%, rgba(255, 255, 255, 0) 100%);
          // Positioned.fill(
          //   child: Container(
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(8),
          //       gradient: const RadialGradient(
          //         radius: 3,
          //         center: Alignment(-1, -1),
          //         colors: [
          //           Color.fromARGB(255, 250, 231, 162),
          //           Color(0x00FFDD66),
          //         ],
          //         stops: [0, 1],
          //       ),
          //     ),
          //     width: double.infinity,
          //     height: double.infinity,
          //   ),
          // ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SvgImage.asset(
                'assets/images/bar2.svg',
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              ),
            ),
          ),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 6 * (height / 100)),
                  // if (header.isEmpty) const SizedBox(height: 16 + 2),
                  // ...header,
                  Row(
                    children: [
                      Flexible(
                        child: WidgetButton(
                          onPressed: onTitlePressed,
                          child: SelectionContainer.disabled(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 9, 0),
                              child: EmbossedText(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                small: true,
                                style: style.boldBody.copyWith(
                                  color: DonateWidget.font,
                                  fontSize:
                                      style.boldBody.fontSize! * (height / 100),
                                  // color: color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...'$donate'.embossedDigits(
                          style: style.boldBody.copyWith(
                            fontSize: 32 * (height / 100),
                            color: font,
                          ),
                        ),
                        const SizedBox(width: 0),
                        Transform.translate(
                          // offset: const Offset(0, -3),
                          offset: const Offset(0, 0),
                          child: EmbossedText(
                            '¤',
                            style: style.boldBody.copyWith(
                              fontSize: 32 * (height / 100),
                              // fontFamily: 'Gapopa',
                              color: font,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ...footer,
                  SizedBox(height: 26 * (height / 100)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: timestamp ??
                    EmbossedText(
                      'GIFT',
                      small: true,
                      style: style.systemMessageStyle.copyWith(
                        // color: const Color(0xFFA98010),
                        // color: const Color(0xFFFFFE8A),
                        color: DonateWidget.font,
                        fontSize: 11 * (height / 100),
                      ),
                    ),
              ),
            ],
          ),
        ],
      ),
    );

    if (transaction == null) {
      return bar;
    }

    return Tooltip(
      message: 'Transaction #$transaction',
      decoration: BoxDecoration(
        color: style.contextMenuBackgroundColor,
        borderRadius: style.contextMenuRadius,
        border: Border.all(
          color: style.colors.secondaryHighlightDarkest,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: style.colors.onBackgroundOpacity20,
            blurStyle: BlurStyle.outer,
          )
        ],
      ),
      padding: const EdgeInsets.all(8),
      textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: style.colors.onBackground,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
      child: bar,
    );
  }
}

extension EmbossedDigits on String {
  List<Widget> embossedDigits({
    TextStyle? style,
  }) {
    final List<Widget> list = [];
    for (int i = length - 1; i >= 0; --i) {
      int j = length - 1 - i;

      if (j % 3 == 0) {
        list.add(const SizedBox(width: 3));
      }

      list.add(
        EmbossedText(
          this[i],
          style: style,
        ),
      );
    }

    return list.reversed.toList();
  }
}
