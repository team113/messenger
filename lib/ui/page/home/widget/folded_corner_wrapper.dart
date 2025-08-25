import 'package:flutter/material.dart';

import '../../../../themes.dart';
import 'avatar.dart';

class FoldedCornerWrapper extends StatelessWidget {
  const FoldedCornerWrapper({
    super.key,
    required this.fold,
    required this.child,
    this.radius,
  });

  /// Whether to apply the folded-corner clipping.
  final bool fold;

  /// The widget that will be clipped or displayed as-is.
  final Widget child;

  /// The radius of the folded corner.
  ///
  /// Defaults to `10` when [fold] is `true` but [radius] is `null`.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return ClipPath(
      clipper: fold ? _FoldClipper(radius ?? 10) : null,
      child: Stack(
        children: [
          child,
          if (fold)
            Container(
              width: radius ?? 10,
              height: radius ?? 10,
              decoration: BoxDecoration(
                color: style.colors.primaryHighlightShiniest.darken(0.1),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  CustomBoxShadow(
                    color: style.colors.secondaryHighlightDarkest,
                    blurStyle: BlurStyle.outer.workaround,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// [CustomClipper] clipping a top-left corner.
class _FoldClipper extends CustomClipper<Path> {
  const _FoldClipper(this.radius);

  /// Radius of the corner being clipped.
  final double radius;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, radius)
      ..lineTo(radius, 0);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
