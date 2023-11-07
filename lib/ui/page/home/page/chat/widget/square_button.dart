import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/call/widget/conditional_backdrop.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';

class SquareButton extends StatelessWidget {
  const SquareButton(
    this.icon, {
    super.key,
    this.onPressed,
  });

  final SvgData icon;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    // return AnimatedButton(
    //   onPressed: onPressed,
    //   child: Padding(
    //     padding: const EdgeInsets.all(8.0),
    //     child: SvgIcon(icon),
    //   ),
    // );

    final style = Theme.of(context).style;

    return AnimatedButton(
      onPressed: onPressed,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            CustomBoxShadow(
              blurRadius: 8,
              color: style.colors.onBackgroundOpacity13,
              blurStyle: BlurStyle.outer.workaround,
            ),
          ],
        ),
        child: ConditionalBackdropFilter(
          condition: false,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: style.cardColor,
              // borderRadius: BorderRadius.circular(8),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Transform.scale(scale: 0.75, child: SvgIcon(icon)),
            ),
          ),
        ),
      ),
    );
  }
}
