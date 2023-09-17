import 'package:flutter/material.dart';

/// Widget [DebossedText] displays [text] with "pressed" effect.
class DebossedText extends StatelessWidget {
  const DebossedText({
    super.key,
    required this.text,
    required this.textColor,
    this.gradient,
    this.styles = const TextStyle(),
  });

  /// [text] to be displayed.
  final String text;

  /// Color of the [text] if no gradient is provided.
  final Color textColor;

  /// Gradient of the [text] instead of [textColor].
  final Gradient? gradient;

  /// Styles of the [text].
  final TextStyle? styles;

  /// Shadows of the [text] that create the effect of debossed text.
  final shadows = const [
    Shadow(
      color: Colors.white,
      blurRadius: 2,
      offset: Offset(0.5, 0.5),
    ),
    Shadow(
      color: Colors.black,
      blurRadius: 2,
      offset: Offset(-0.5, -0.5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // creates a [Paint] object for gradient [text].
    final Paint paint = Paint()
      ..shader =
          gradient?.createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

    return Text(
      text,
      style: styles?.copyWith(
        shadows: shadows,
        foreground: gradient != null ? paint : null,
        color: gradient == null ? textColor : null,
      ),
    );
  }
}
