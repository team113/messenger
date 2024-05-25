import 'package:flutter/material.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '../../../../../widget/markdown.dart';

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              18,
            ),
            decoration: BoxDecoration(
              border: border,
              borderRadius: style.cardRadius,
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (header != null)
                  Center(
                    child: MarkdownWidget(
                      header!,
                      style: style.systemMessageStyle,
                    ),
                  ),
                if (header != null && description != null)
                  const SizedBox(height: 8),
                if (description != null)
                  MarkdownWidget(
                    description!,
                    style: style.systemMessageStyle,
                  ),
                if (span != null)
                  Text.rich(span!, style: style.systemMessageStyle),
                const SizedBox(height: 8),
                Center(
                  child: WidgetButton(
                    onPressed: onPressed,
                    child: Text(
                      action ?? 'btn_ok'.l10n,
                      style: style.systemMessageStyle
                          .copyWith(color: style.colors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
