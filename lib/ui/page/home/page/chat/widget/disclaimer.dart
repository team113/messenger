import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/widget/markdown.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';

class DisclaimerWidget extends StatelessWidget {
  const DisclaimerWidget({
    super.key,
    this.border,
    this.onPressed,
    this.description,
    this.action,
    this.span,
    this.accepted = false,
    this.name,
    this.header,
  });

  final bool accepted;
  final Border? border;
  final void Function()? onPressed;
  final String? name;
  final String? header;
  final String? description;
  final InlineSpan? span;
  final String? action;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      margin: const EdgeInsets.only(top: 0, bottom: 0, left: 8, right: 8),
      decoration: BoxDecoration(
        borderRadius: style.cardRadius,
        boxShadow: const [
          CustomBoxShadow(blurRadius: 8, color: Color(0x22000000)),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: border,
          borderRadius: style.cardRadius,
          color: Colors.white,
        ),
        width: context.isNarrow ? double.infinity : 400,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (header != null)
                    Center(
                      child: MarkdownWidget(
                        header!,
                        style: style.fonts.big.regular.onBackground,
                      ),
                    ),
                  if (header != null && description != null)
                    Container(
                      color: style.colors.secondaryHighlightDarkest,
                      height: 1,
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(10, 16, 10, 16),
                    ),
                  if (description != null)
                    Center(
                      child: MarkdownWidget(
                        description!,
                        style: style.fonts.normal.regular.secondary,
                      ),
                    ),
                  if (span != null)
                    Text.rich(
                      span!,
                      style: style.fonts.normal.regular.secondary,
                    ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: WidgetButton(
                onPressed: onPressed,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(12, 14, 14, 8),
                  child: SvgIcon(SvgIcons.closeSmallPrimary),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
