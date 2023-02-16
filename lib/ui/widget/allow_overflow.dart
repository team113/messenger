import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// [Widget] allowing its [child] to overflow as it pleases.
class AllowOverflow extends SingleChildRenderObjectWidget {
  const AllowOverflow({super.key, super.child});

  @override
  RenderAllowOverflow createRenderObject(BuildContext context) {
    return RenderAllowOverflow(
      textDirection: Directionality.maybeOf(context),
      alignment: Alignment.center,
      constraintsTransform: ConstraintsTransformBox.unconstrained,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderConstraintsTransformBox renderObject,
  ) {
    renderObject.textDirection = Directionality.maybeOf(context);
  }
}

/// [RenderAligningShiftedBox] rendering its [child] unconstrained.
class RenderAllowOverflow extends RenderConstraintsTransformBox {
  RenderAllowOverflow({
    required super.alignment,
    required super.textDirection,
    required super.constraintsTransform,
    super.child,
  }) : _constraintsTransform = constraintsTransform;

  /// [BoxConstraintsTransform] returning the [BoxConstraints] to apply to this
  /// [RenderAllowOverflow].
  final BoxConstraintsTransform _constraintsTransform;

  @override
  double computeMinIntrinsicHeight(double width) {
    return super.computeMinIntrinsicHeight(
      _constraintsTransform(BoxConstraints(maxWidth: width)).maxWidth,
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return super.computeMaxIntrinsicHeight(
      _constraintsTransform(BoxConstraints(maxWidth: width)).maxWidth,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return super.computeMinIntrinsicWidth(
      _constraintsTransform(BoxConstraints(maxHeight: height)).maxHeight,
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return super.computeMaxIntrinsicWidth(
      _constraintsTransform(BoxConstraints(maxHeight: height)).maxHeight,
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final Size? childSize =
        child?.getDryLayout(_constraintsTransform(constraints));
    return childSize == null
        ? constraints.smallest
        : constraints.constrain(childSize);
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    final RenderBox? child = this.child;
    if (child != null) {
      final BoxConstraints childConstraints =
          _constraintsTransform(constraints);

      assert(
        childConstraints.isNormalized,
        '$childConstraints is not normalized',
      );

      child.layout(childConstraints, parentUsesSize: true);
      size = constraints.constrain(child.size);
      alignChild();
    } else {
      size = constraints.smallest;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // There's no point in drawing the child if we're empty, or there is no
    // child.
    if (child == null || size.isEmpty) {
      return;
    }

    super.paint(context, offset);
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) => null;
}
