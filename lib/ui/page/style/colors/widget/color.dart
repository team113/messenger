import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/style/widget/caption.dart';

import '../../../../../util/message_popup.dart';
import '../../../../widget/widget_button.dart';

class CustomColor extends StatelessWidget {
  const CustomColor(
    this.isDarkMode,
    this.color, {
    super.key,
    this.subtitle = '',
    this.title = '',
  });

  final bool isDarkMode;

  final Color color;

  final String title;

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    // final HSLColor hsl = HSLColor.fromColor(color);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Row(
            children: [
              const SizedBox(width: 17),
              Text(
                color.toHex(),
                textAlign: TextAlign.start,
                style: fonts.bodySmall!.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: subtitle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: WidgetButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: color.toHex()));
                MessagePopup.success('label_copied'.l10n);
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (!isDarkMode)
                      BoxShadow(
                        color: style.colors.secondary.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Row(
            children: [
              const SizedBox(width: 17),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.left,
                  style: fonts.labelSmall!.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
