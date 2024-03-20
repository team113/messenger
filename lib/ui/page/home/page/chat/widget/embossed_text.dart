import 'package:flutter/material.dart';

class EmbossedText extends StatelessWidget {
  const EmbossedText(
    String this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.small = false,
  }) : span = null;

  const EmbossedText.rich(
    InlineSpan this.span, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.small = false,
  }) : text = null;

  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  final bool small;

  /// Text to be selected.
  final String? text;

  /// [InlineSpan] to be selected.
  final InlineSpan? span;

  static const List<Shadow> smallShadows = [
    Shadow(
      offset: Offset(0.5, 0.5),
      blurRadius: 1,
      color: Color.fromRGBO(153, 130, 0, 0.6),
    ),
    Shadow(
      offset: Offset(-0.3, -0.3),
      blurRadius: 1.5,
      color: Color.fromRGBO(255, 255, 0, 0.9),
    ),
    Shadow(
      offset: Offset(1, 1),
      blurRadius: 2,
      color: Color.fromRGBO(128, 108, 0, 0.4),
    ),
    Shadow(
      offset: Offset(0.5, 0.5),
      blurRadius: 2,
      color: Color.fromRGBO(153, 130, 0, 0.9),
    ),
    Shadow(
      offset: Offset(-0.5, -0.5),
      blurRadius: 2,
      color: Color.fromRGBO(255, 255, 0, 0.9),
    ),
    Shadow(
      offset: Offset(1, 1),
      blurRadius: 2,
      color: Color.fromRGBO(172, 146, 0, 0.2),
    ),
  ];

  static const List<Shadow> shadows = [
    Shadow(
      offset: Offset(1, 1),
      blurRadius: 3,
      color: Color.fromRGBO(172, 146, 0, 0.9),
    ),
    Shadow(
      offset: Offset(-1, -1),
      blurRadius: 2,
      color: Color.fromRGBO(255, 255, 0, 0.9),
    ),
    Shadow(
      offset: Offset(1, -1),
      blurRadius: 2,
      color: Color.fromRGBO(172, 146, 0, 0.2),
    ),
    Shadow(
      offset: Offset(-1, 1),
      blurRadius: 2,
      color: Color.fromRGBO(172, 146, 0, 0.2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textStyle = (style ?? const TextStyle()).copyWith();

    final shadows = textStyle.copyWith(
      color: small
          ? const Color.fromRGBO(255, 215, 0, 1)
          : const Color.fromRGBO(243, 205, 1, 1),
      shadows: small ? EmbossedText.smallShadows : EmbossedText.shadows,
    );

    if (span != null) {
      return Stack(
        children: [
          Text.rich(
            span!,
            style: textStyle,
            textAlign: textAlign,
            overflow: overflow,
            maxLines: maxLines,
          ),
          Text.rich(
            span!,
            style: shadows,
            textAlign: textAlign,
            overflow: overflow,
            maxLines: maxLines,
          ),
        ],
      );
    }

    return Text(
      text!,
      style: shadows,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
