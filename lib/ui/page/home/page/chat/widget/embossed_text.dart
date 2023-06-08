import 'package:flutter/material.dart';

class EmbossedText extends StatelessWidget {
  const EmbossedText(
    String this.text, {
    super.key,
    this.style,
    this.textAlign,
  }) : span = null;

  const EmbossedText.rich(
    InlineSpan this.span, {
    super.key,
    this.style,
    this.textAlign,
  }) : text = null;

  final TextStyle? style;
  final TextAlign? textAlign;

  /// Text to be selected.
  final String? text;

  /// [InlineSpan] to be selected.
  final InlineSpan? span;

  @override
  Widget build(BuildContext context) {
    final textStyle = (style ?? const TextStyle()).copyWith(
        //background: linear-gradient(90deg, #F9C924 0%, #E4AF18 32%, #FFF98C 68%, #FFD440 100%);
        // foreground: Paint()
        //   ..shader = ui.Gradient.linear(
        //     const Offset(0, 0),
        //     const Offset(150, 0),
        //     const [
        //       Color(0xFFF9C924),
        //       Color(0xFFE4AF18),
        //       Color(0xFFFFF98C),
        //       Color(0xFFFFD440),
        //     ],
        //     [0, 0.32, 0.68, 1],
        //   ),
        );

    final shadows = textStyle.copyWith(
      color: Colors.transparent,
      // foreground: null,
      shadows: const [
        // 6
        // box-shadow: 1px 1px 3px 0px #947900E5 inset;
        // box-shadow: -1px -1px 2px 0px #FFE100E5 inset;
        // box-shadow: 1px -1px 2px 0px #94790033 inset;
        // box-shadow: -1px 1px 2px 0px #94790033 inset;
        Shadow(
          offset: Offset(1, 1),
          blurRadius: 3,
          color: Color(0xE5947900),
        ),
        Shadow(
          offset: Offset(-1, -1),
          blurRadius: 2,
          color: Color(0xE5FFE100),
        ),
        Shadow(
          offset: Offset(1, -1),
          blurRadius: 2,
          color: Color(0x33947900),
        ),
        Shadow(
          offset: Offset(-1, 1),
          blurRadius: 2,
          color: Color(0x33947900),
        ),

        // 5
        // box-shadow: 1px 1px 3px 0px #867424E5;
        // box-shadow: -1px -1px 2px 0px #FFFF60E5;
        // box-shadow: 1px -1px 2px 0px #86742433;
        // box-shadow: -1px 1px 2px 0px #86742433;
        // Shadow(
        //   offset: Offset(1, 1),
        //   blurRadius: 3,
        //   color: Color(0xE5867424),
        // ),
        // Shadow(
        //   offset: Offset(-1, -1),
        //   blurRadius: 2,
        //   color: Color(0xE5FFFF60),
        // ),
        // Shadow(
        //   offset: Offset(1, -1),
        //   blurRadius: 2,
        //   color: Color(0x33867424),
        // ),
        // Shadow(
        //   offset: Offset(-1, 1),
        //   blurRadius: 2,
        //   color: Color(0x33867424),
        // ),

        // 4
        // box-shadow: 3px 3px 2px 0px #5B470440 inset;
        // Shadow(
        //   offset: Offset(3, -3),
        //   blurRadius: 2,
        //   color: Color(0x405B4704),
        // ),

        // 3
        // box-shadow: 1px -1px 3px 0px #D6B02BE5 inset;
        // box-shadow: -1px 1px 2px 0px #FFEE3AE5 inset;
        // box-shadow: 1px 1px 2px 0px #D6B02B33 inset;
        // box-shadow: -1px -1px 2px 0px #D6B02B33 inset;
        // Shadow(
        //   offset: Offset(1, -1),
        //   blurRadius: 3,
        //   color: Color(0xE5D6B02B),
        // ),
        // Shadow(
        //   offset: Offset(-1, 1),
        //   blurRadius: 2,
        //   color: Color(0xE5FFEE3A),
        // ),
        // Shadow(
        //   offset: Offset(1, 1),
        //   blurRadius: 2,
        //   color: Color(0x33D6B02B),
        // ),
        // Shadow(
        //   offset: Offset(-1, 1),
        //   blurRadius: 2,
        //   color: Color(0x33D6B02B),
        // ),

        // box-shadow: 1px 1px 0.5px 0px #5B470440 inset;
        // 2
        // Shadow(
        //   offset: Offset(1, 1),
        //   blurRadius: 0.5,
        //   color: Color(0x405B4704),
        // ),

        // 1
        // box-shadow: -8px -8px 16px 0px #FFF63DE5 inset;
        // box-shadow: 8px -8px 16px 0px #C6A82933 inset;
        // box-shadow: -1px -1px 2px 0px #C6A82980;
        // box-shadow: 1px 1px 2px 0px #FFF63D4D;
        // Shadow(
        //   offset: Offset(-8, -8),
        //   blurRadius: 16,
        //   color: Color(0xE5FFF63D),
        // ),
        // Shadow(
        //   offset: Offset(8, -8),
        //   blurRadius: 16,
        //   color: Color(0x33C6A829),
        // ),
        // Shadow(
        //   offset: Offset(-1, -1),
        //   blurRadius: 2,
        //   color: Color(0x80C6A829),
        // ),
        // Shadow(
        //   offset: Offset(1, 1),
        //   blurRadius: 2,
        //   color: Color(0x4DFFF63D),
        // ),
      ],
    );

    if (span != null) {
      return Stack(
        children: [
          Text.rich(span!, style: textStyle, textAlign: textAlign),
          Text.rich(span!, style: shadows, textAlign: textAlign),
        ],
      );
    }

    return Stack(
      children: [
        Text(text!, style: shadows, textAlign: textAlign),
        Text(text!, style: textStyle, textAlign: textAlign),
      ],
    );
  }
}
