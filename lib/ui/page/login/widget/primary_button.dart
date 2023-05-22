import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/widget/outlined_rounded_button.dart';

/// Primary styled [OutlinedRoundedButton].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    this.title = '',
    this.onPressed,
  });

  /// Text to display.
  final String title;

  /// Callback, called when this button is tapped or activated other way.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return OutlinedRoundedButton(
      key: key,
      maxWidth: double.infinity,
      title: Text(
        title,
        style: TextStyle(
          color: onPressed == null
              ? style.colors.onBackground
              : style.colors.onPrimary,
        ),
      ),
      onPressed: onPressed,
      color: style.colors.primary,
    );
  }
}
