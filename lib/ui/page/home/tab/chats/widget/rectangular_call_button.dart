import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';

/// Widget which returns a custom-styled rounded rectangular button.
class RectangularCallButton extends StatelessWidget {
  const RectangularCallButton({
    super.key,
    this.isActive = true,
    this.child,
    this.onPressed,
  });

  /// Indicator whether this [RectangularCallButton] is active or not.
  final bool isActive;

  /// [Widget] to display inside this [RectangularCallButton].
  final Widget? child;

  /// Callback, called when this [RectangularCallButton] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

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
                if (child != null) child!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
