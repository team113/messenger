import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';

import 'round_button.dart';

/// [RoundFloatingButton] optionally displaying its [hint] according to the
/// specified [hinted] and [expanded].
class CallButtonWidget extends StatelessWidget {
  const CallButtonWidget({
    super.key,
    required this.asset,
    this.assetWidth = 60,
    this.onPressed,
    this.hint,
    this.hinted = true,
    this.expanded = false,
    this.withBlur = false,
    this.color,
    this.border,
  });

  /// Asset to display.
  final String? asset;

  /// Width of the [asset].
  final double assetWidth;

  /// Callback, called when this [CallButtonWidget] is pressed.
  final void Function()? onPressed;

  /// Text that will show above the button on a hover.
  final String? hint;

  /// Indicator whether [hint] should be displayed above the button, or under it
  /// otherwise.
  final bool hinted;

  /// Indicator whether the [hint] should be always displayed under the button.
  final bool expanded;

  /// Indicator whether background should be blurred.
  final bool withBlur;

  /// Background color of this [CallButtonWidget].
  final Color? color;

  /// Border style of this [CallButtonWidget].
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return RoundFloatingButton(
      asset: asset,
      assetWidth: assetWidth,
      color: color ?? style.colors.onSecondaryOpacity50,
      hint: !expanded && hinted ? hint : null,
      text: expanded ? hint : null,
      withBlur: withBlur,
      border: border,
      onPressed: onPressed,
    );
  }
}
