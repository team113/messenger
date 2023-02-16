// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

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
