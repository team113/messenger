import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// TODO: Fix HTML web renderer:
//       https://github.com/flutter/flutter/issues/48417
/// Draws an inner shadow to its [child].
///
/// Example usage:
/// ```dart
/// InnerShadow(
///   blur: 14,
///   color: Color.fromARGB(255, 52, 51, 44),
///   offset: Offset(1, 12),
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
/// InnerShadow(
///   blur: 2,
///   color: Color.fromARGB(255, 221, 93, 93),
///   offset: Offset(1, 5),
///   child: Text(
///     'Hellow?',
///      style: TextStyle(
///      color: Color.fromARGB(255, 2, 2, 2),
///      fontSize: 190,
///     ),
///    ),
/// ),
/// ```
class InnerShadow extends SingleChildRenderObjectWidget {
  const InnerShadow({
    super.key,
    this.blur = 10,
    this.color = Colors.black54,
    this.offset = const Offset(10, 10),
    super.child,
  });

  /// Blur of the shadow.
  final double blur;

  /// Color of the shadow.
  final Color color;

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
    BuildContext context,
    RenderInnerShadow renderObject,
  ) {
    renderObject
      .._color = color
      .._blur = blur
      .._dx = offset.dx
      .._dy = offset.dy;
  }
}

/// [RenderObject] for [InnerShadow].
class RenderInnerShadow extends RenderProxyBox {
  /// Blur of the shadow.
  late double _blur;

  /// Color of the shadow.
  late Color _color;

  /// Offset of the shadow along the x axis.
  late double _dx;

  /// Offset of the shadow along the y axis.
  late double _dy;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    final Rect rectOuter = offset & size;

    final Canvas canvas = context.canvas..saveLayer(rectOuter, Paint());
    context.paintChild(child!, offset);

    canvas.saveLayer(rectOuter, Paint()..blendMode = BlendMode.srcATop);

    final Paint shadowPaint = Paint()
      ..colorFilter = ColorFilter.mode(_color, BlendMode.srcOut)
      ..imageFilter = ImageFilter.blur(sigmaX: _blur, sigmaY: _blur);

    canvas
      ..saveLayer(rectOuter, shadowPaint)
      ..translate(_dx, _dy);
    context.paintChild(child!, offset);
    context.canvas
      ..restore()
      ..restore()
      ..restore();
  }
}
