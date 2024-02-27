import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// [WidgetButton] of squared [Container] with an [icon] and a [label].
class QuickButton extends StatelessWidget {
  const QuickButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  /// [SvgData] to display as an icon.
  final SvgData icon;

  /// Label to display.
  final String label;

  /// Callback, called when this button is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return WidgetButton(
      onPressed: onPressed,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: style.cardColor,
          border: style.cardBorder,
          borderRadius: style.cardRadius,
        ),
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgIcon(icon),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                  child: FittedBox(
                    child: Text(
                      label,
                      style: style.fonts.small.regular.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
