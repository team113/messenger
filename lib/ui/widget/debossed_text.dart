import 'package:flutter/material.dart';

/// Widget [DebossedText] displays [text] with "pressed" effect.
class DebossedText extends StatelessWidget {
  const DebossedText({
    super.key,
    required this.text,
    required this.textColor,
    this.gradient,
    this.style = const TextStyle(),
  });

  /// [text] to be displayed.
  final String text;

  /// Color of the [text] if no gradient is provided.
  final Color textColor;

  /// Gradient of the [text] instead of [textColor].
  final LinearGradient? gradient;

  /// Styles of the [text].
  final TextStyle? style;

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
    if (gradient != null) {
      return Stack(children: [
        Text(
          text,
          style: style?.copyWith(
              //shadows: shadows,
              ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => gradient!.createShader(bounds),
          child: Text(
            text,
            style: style?.copyWith(),
          ),
        ),
      ]);
    }
    return Text(
      text,
      style: style?.copyWith(
        shadows: shadows,
        color: textColor,
      ),
    );
  }
}
