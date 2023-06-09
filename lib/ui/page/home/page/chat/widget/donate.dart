import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';

import 'embossed_text.dart';

class DonateWidget extends StatelessWidget {
  const DonateWidget({
    super.key,
    this.donate = 0,
    this.header = const [],
    this.footer = const [],
    this.timestamp,
  });

  final int donate;
  final List<Widget> header;
  final List<Widget> footer;
  final Widget? timestamp;

  static const Color font = Color.fromRGBO(252, 228, 93, 1);

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    const List<Color> colors = [
      Color(0xFFFEE661),
      Color(0xFFE7C31E),
      Color(0xFFFFE864),
      Color(0xFFF5C635),
    ];

    const List<double> stops = [0, 0.32, 0.68, 1];

    const LinearGradient outerGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: stops,
    );

    const LinearGradient innerGradient =
        LinearGradient(colors: colors, stops: stops);

    return Tooltip(
      message: 'Transaction #5031855728915',
      child: Container(
        // width: 300,
        // constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: outerGradient,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: innerGradient,
          ),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  if (header.isEmpty) const SizedBox(height: 16 + 2),
                  ...header,
                  Row(
                    children: [
                      // if (_text == null) ...[
                      //   const SizedBox(width: 16),
                      //   Opacity(
                      //     opacity: 0,
                      //     child: Transform.translate(
                      //       offset: const Offset(0, 8),
                      //       child: _timestamp(msg, false, !_fromMe),
                      //     ),
                      //   ),
                      // ],
                      // const SizedBox(width: 6),

                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...'$donate'.embossedDigits(
                                style: style.boldBody.copyWith(
                                  fontSize: 32,
                                  color: font,
                                ),
                              ),
                              // EmbossedText(
                              //   '$donate',
                              //   style: style.boldBody.copyWith(
                              //     fontSize: 32,
                              //     color: const Color(0xFFFFFE8A),
                              //   ),
                              // ),
                              const SizedBox(width: 0),
                              Transform.translate(
                                offset: const Offset(0, -1),
                                child: EmbossedText(
                                  '¤',
                                  style: style.boldBody.copyWith(
                                    fontSize: 32,
                                    fontFamily: 'Gapopa',
                                    color: font,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Expanded(
                      //   child: SelectionText.rich(
                      //     TextSpan(
                      //       children: [
                      //         TextSpan(
                      //           text: '$donate',
                      //           style: style.boldBody.copyWith(
                      //             // color: const Color(0xFFFFF63D),
                      //             color: const Color(0xFFFFFE8A),
                      //             shadows: const [
                      //               // box-shadow: -8px -8px 16px 0px #FFF63DE5 inset;
                      //               // box-shadow: 8px -8px 16px 0px #C6A82933 inset;
                      //               // box-shadow: -1px -1px 2px 0px #C6A82980;
                      //               // box-shadow: 1px 1px 2px 0px #FFF63D4D;
                      //               Shadow(
                      //                 offset: Offset(-8, -8),
                      //                 blurRadius: 16,
                      //                 color: Color(0xE5FFF63D),
                      //               ),
                      //               Shadow(
                      //                 offset: Offset(8, -8),
                      //                 blurRadius: 16,
                      //                 color: Color(0x33C6A829),
                      //               ),
                      //               Shadow(
                      //                 offset: Offset(-1, -1),
                      //                 blurRadius: 2,
                      //                 color: Color(0x80C6A829),
                      //               ),
                      //               Shadow(
                      //                 offset: Offset(1, 1),
                      //                 blurRadius: 2,
                      //                 color: Color(0x4DFFF63D),
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //         TextSpan(
                      //           text: '¤',
                      //           style: style.boldBody.copyWith(
                      //             fontFamily: 'Gapopa',
                      //             color: const Color(0xFFA98010),
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //     textAlign: TextAlign.center,
                      //   ),
                      // ),
                    ],
                  ),
                  ...footer,
                  if (footer.isEmpty) const SizedBox(height: 16 + 2),
                  const SizedBox(height: 2),
                  const SizedBox(height: 6),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: timestamp ??
                    EmbossedText(
                      'Gift',
                      style: style.systemMessageStyle.copyWith(
                        // color: const Color(0xFFA98010),
                        color: const Color(0xFFFFFE8A),
                        fontSize: 11,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
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
