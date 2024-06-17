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
    this.color,
    List<Shadow>? shadows,
  })  : shadows = shadows ??
            const [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 3,
                color: Color(0xE4AC9200),
              ),
              Shadow(
                offset: Offset(-1, -1),
                blurRadius: 2,
                color: Color(0xE4FFFF00),
              ),
              Shadow(
                offset: Offset(1, -1),
                blurRadius: 2,
                color: Color(0x33AC9200),
              ),
              Shadow(
                offset: Offset(-1, 1),
                blurRadius: 2,
                color: Color(0x33AC9200),
              ),
            ],
        span = null;

  const EmbossedText.rich(
    InlineSpan this.span, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.small = false,
    this.color,
    this.shadows = const [
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
    ],
  }) : text = null;

  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  final List<Shadow> shadows;
  final Color? color;
  final bool small;

  /// Text to be selected.
  final String? text;

  /// [InlineSpan] to be selected.
  final InlineSpan? span;

  static const List<Shadow> smallShadows = [
    Shadow(
      offset: Offset(0.5, 0.5),
      blurRadius: 1,
      color: Color(0x99998200),
    ),
    Shadow(
      offset: Offset(-0.3, -0.3),
      blurRadius: 1.5,
      color: Color(0xE4FFFF00),
    ),
    Shadow(
      offset: Offset(1, 1),
      blurRadius: 2,
      color: Color(0x66806C00),
    ),
    Shadow(
      offset: Offset(0.5, 0.5),
      blurRadius: 2,
      color: Color(0xE4998200),
    ),
    Shadow(
      offset: Offset(-0.5, -0.5),
      blurRadius: 2,
      color: Color(0xE4FEFEF9),
    ),
    Shadow(
      offset: Offset(1, 1),
      blurRadius: 2,
      color: Color(0x33AC9200),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textStyle = (style ?? const TextStyle()).copyWith();

    final shadows = textStyle.copyWith(
      color: color ??
          (small
              ? const Color.fromRGBO(255, 215, 0, 1)
              : const Color.fromRGBO(243, 205, 1, 1)),
      shadows: small ? EmbossedText.smallShadows : this.shadows,
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
