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
    this.height = _defaultHeight,
  });

  static const double _defaultHeight = 104;

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
    final style = Theme.of(context).style;

    final bar = Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF9C924),
            Color(0xFFE4AF18),
            Color(0xFFFFF98C),
            Color(0xFFFFD440),
          ],
          stops: [0, 0.32, 0.68, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const SvgImage.asset(
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
                  SizedBox(height: 6 * (height / _defaultHeight)),
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
                                style: style.fonts.medium.regular.onBackground
                                    .copyWith(
                                  color: DonateWidget.font,
                                  fontSize: style.fonts.medium.regular
                                          .onBackground.fontSize! *
                                      (height / _defaultHeight),
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
                    child: _tooltiped(
                      context,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...'$donate'.embossedDigits(
                            style: style.fonts.medium.regular.onBackground
                                .copyWith(
                              fontSize: 32 * (height / _defaultHeight),
                              color: font,
                            ),
                          ),
                          const SizedBox(width: 0),
                          Transform.translate(
                            // offset: const Offset(0, -3),
                            offset: const Offset(0, 0),
                            child: EmbossedText(
                              ' ¤',
                              style: style.fonts.medium.regular.onBackground
                                  .copyWith(
                                fontSize: 32 * (height / _defaultHeight),
                                // fontFamily: 'Gapopa',
                                color: font,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ...footer,
                  SizedBox(height: 26 * (height / _defaultHeight)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: timestamp ??
                    EmbossedText(
                      'GIFT',
                      small: true,
                      style: style.systemMessageStyle.copyWith(
                        color: DonateWidget.font,
                        fontSize: 11 * (height / _defaultHeight),
                      ),
                    ),
              ),
            ],
          ),
        ],
      ),
    );

    // if (transaction == null) {
    //   return bar;
    // }

    return bar;
  }

  Widget _tooltiped(BuildContext context, Widget child) {
    if (transaction == null) {
      return child;
    }

    final style = Theme.of(context).style;

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
            blurStyle: BlurStyle.outer.workaround,
          )
        ],
      ),
      padding: const EdgeInsets.all(8),
      textStyle: style.fonts.normal.regular.onBackground.copyWith(
        color: style.colors.onBackground,
        fontSize: style.fonts.small.regular.onBackground.fontSize,
      ),
      child: child,
    );
  }
}

extension EmbossedDigits on String {
  List<Widget> embossedDigits({TextStyle? style}) {
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