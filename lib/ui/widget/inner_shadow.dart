import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Example usage:
/// ```dart
/// InnerShadow(
///   innerColor: Color.fromARGB(255, 52, 51, 44),
///   offset: Offset(1, 12),
///   blur: 14,
///   child: Container(
///     decoration: BoxDecoration(
///       borderRadius: BorderRadius.all(Radius.circular(8)),
///       color: Color.fromARGB(255, 113, 94, 218),
///     ),
///     height: 100,
///   ),
/// ),
/// ```
/// ```dart
///  InnerShadow(
///                   blur: 2,
///                   innerColor: Color.fromARGB(255, 221, 93, 93),
///                   offset: Offset(1, 5),
///                   child: Text(
///                     'Hellow?',
///                     style: TextStyle(
///                         color: Color.fromARGB(255, 2, 2, 2), fontSize: 190),
///                   ),
///                 )
/// ```

/// Draws an inner shadow to its [child].
///
/// The shadow color is taken from the [child]'s styles.
/// If you need to change the color of the shadow,
/// change the color of the [child] in styles.
class InnerShadow extends SingleChildRenderObjectWidget {
  const InnerShadow({
    super.key,
    this.blur = 10,
    required this.innerColor,
    this.offset = const Offset(10, 10),
    Widget? child,
  }) : super(child: child);

  /// Аdds blur to shadow.
  final double blur;

  /// Color of the [child].
  final Color innerColor;

  /// Offset of the shadow.
  final Offset offset;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final RenderInnerShadow renderObject = RenderInnerShadow();
    updateRenderObject(context, renderObject);
    return renderObject;
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderInnerShadow renderObject) {
    renderObject
      ..innerColor = innerColor
      ..blur = blur
      ..dx = offset.dx
      ..dy = offset.dy;
  }
}

/// [RenderObject] for [InnerShadow].
class RenderInnerShadow extends RenderProxyBox {
  late double blur;
  late Color innerColor;
  late double dx;
  late double dy;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    final Rect rectOuter = offset & size;

    final Canvas canvas = context.canvas
      ..saveLayer(
        rectOuter,
        Paint(),
      );
    context.paintChild(
      child!,
      offset,
    );

    final Paint shadowPaint = Paint()
      ..imageFilter = ImageFilter.blur(sigmaX: blur, sigmaY: blur)
      ..colorFilter = ColorFilter.mode(innerColor, BlendMode.srcATop);

    canvas
      ..saveLayer(rectOuter, shadowPaint)
      ..translate(dx, dy);

    context.paintChild(child!, offset);
    context.canvas
      ..restore()
      ..restore();
  }
}
