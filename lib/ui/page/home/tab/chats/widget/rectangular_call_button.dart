import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_item.dart';

import 'periodic_builder.dart';

/// Widget which returns a custom-styled rounded rectangular button.
class RectangularCallButton extends StatelessWidget {
  const RectangularCallButton({
    super.key,
    this.duration = const Duration(seconds: 52),
    this.isActive = true,
    this.onPressed,
  });

  /// [Duration] to display inside this [RectangularCallButton].
  final Duration duration;

  /// Indicator whether this [RectangularCallButton] is active or not.
  final bool isActive;

  /// Callback, called when this [RectangularCallButton] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: style.colors.onPrimary, width: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        elevation: 0,
        type: MaterialType.button,
        borderRadius: BorderRadius.circular(20),
        color: isActive ? style.colors.dangerColor : style.colors.primary,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.call_end : Icons.call,
                  size: 16,
                  color: style.colors.onPrimary,
                ),
                const SizedBox(width: 6),
                PeriodicBuilder(
                  period: const Duration(seconds: 1),
                  builder: (_) {
                    final String text = duration.hhMmSs();

                    return Text(
                      text,
                      style: fonts.bodyMedium!.copyWith(
                        color: style.colors.onPrimary,
                      ),
                    ).fixedDigits();
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
