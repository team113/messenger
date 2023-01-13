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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '/ui/page/home/widget/gallery_popup.dart';

export 'view.dart';

/// Controller of a [FloatingFit].
class FloatingFitController extends GetxController {
  FloatingFitController({this.intersection});

  /// Optional reactive [Rect] relocating the floating panel on its
  /// intersections.
  final Rx<Rect?>? intersection;

  /// Indicator whether the floating panel is being scaled.
  final RxBool scaled = RxBool(false);

  /// Indicator whether the floating panel is being dragged.
  final RxBool dragged = RxBool(false);

  /// Secondary view current left position.
  final RxnDouble left = RxnDouble(null);

  /// Secondary view current top position.
  final RxnDouble top = RxnDouble(null);

  /// Secondary view current right position.
  final RxnDouble right = RxnDouble(10);

  /// Secondary view current bottom position.
  final RxnDouble bottom = RxnDouble(10);

  /// Secondary view current width.
  late final RxDouble width;

  /// Secondary view current height.
  late final RxDouble height;

  /// Actual size of the [FloatingFit] this controller is bound to.
  Size size = Size.zero;

  /// [width] or [height] of the floating panel before its scaling.
  double? unscaledSize;

  /// [Offset] the floating panel has relative to the pan gesture position.
  Offset? offset;

  /// [GlobalKey] of the floating panel.
  final GlobalKey floatingKey = GlobalKey();

  /// [bottom] value before the floating panel got relocated with the [relocate]
  /// method.
  double? bottomShifted = 10;

  /// Indicator whether the [relocate] is already invoked during the current
  /// frame.
  bool _floatingRelocated = false;

  /// [Worker] reacting on the [intersection] changes relocating floating panel.
  Worker? _relocateWorker;

  /// Max width of the floating panel in percentage of the layout width.
  static const double _maxWidth = 0.80;

  /// Max height of the floating panel in percentage of the layout height.
  static const double _maxHeight = 0.80;

  /// Min width of the floating panel in pixels.
  static const double _minWidth = 125;

  /// Min height of the floating panel in pixels.
  static const double _minHeight = 125;

  @override
  void onInit() {
    double floatingSize = (size.shortestSide *
            (size.aspectRatio > 2 || size.aspectRatio < 0.5 ? 0.45 : 0.33))
        .clamp(_minHeight, 250);
    width = RxDouble(floatingSize);
    height = RxDouble(floatingSize);

    if (intersection != null) {
      _relocateWorker = ever(intersection!, (_) => relocate());
    }

    super.onInit();
  }

  @override
  void onClose() {
    _relocateWorker?.dispose();
    super.onClose();
  }

  /// Relocates the floating panel accounting the possible intersections.
  void relocate() {
    if (dragged.isFalse && scaled.isFalse && !_floatingRelocated) {
      _floatingRelocated = true;

      final Rect? floatingBounds = floatingKey.globalPaintBounds;
      Rect intersect =
          floatingBounds?.intersect(intersection?.value ?? Rect.zero) ??
              Rect.zero;

      intersect = Rect.fromLTWH(
        intersect.left,
        intersect.top,
        intersect.width,
        intersect.height + 10,
      );

      if (intersect.width > 0 && intersect.height > 0) {
        // Intersection is non-zero, so move the floating panel up.
        if (bottom.value != null) {
          bottom.value = bottom.value! + intersect.height;
        } else {
          top.value = top.value! - intersect.height;
        }

        applyConstraints();
      } else if ((intersect.height < 0 || intersect.width < 0) &&
          bottomShifted != null) {
        // Intersection is less than zero and the floating panel is higher than
        // it was before, so move it to its original position.
        double bottom =
            this.bottom.value ?? size.height - top.value! - height.value;
        if (bottom > bottomShifted!) {
          double difference = bottom - bottomShifted!;
          if (this.bottom.value != null) {
            if (difference.abs() < intersect.height.abs() ||
                intersect.width < 0) {
              this.bottom.value = bottomShifted;
            } else {
              this.bottom.value = this.bottom.value! + intersect.height;
            }
          } else {
            if (difference.abs() < intersect.height.abs() ||
                intersect.width < 0) {
              top.value = size.height - height.value - bottomShifted!;
            } else {
              top.value = top.value! - intersect.height;
            }
          }

          applyConstraints();
        }
      }

      SchedulerBinding.instance
          .addPostFrameCallback((_) => _floatingRelocated = false);
    }
  }

  /// Calculates the appropriate [left], [right], [top] and [bottom] values
  /// according to the nearest edge.
  void updateAttach() {
    this.left.value ??= size.width - width.value - (right.value ?? 0);
    this.top.value ??= size.height - height.value - (bottom.value ?? 0);

    List<MapEntry<Alignment, double>> alignments = [
      MapEntry(
        Alignment.topLeft,
        Point(
          this.left.value!,
          this.top.value!,
        ).squaredDistanceTo(const Point(0, 0)),
      ),
      MapEntry(
        Alignment.topRight,
        Point(
          this.left.value! + width.value,
          this.top.value!,
        ).squaredDistanceTo(Point(size.width, 0)),
      ),
      MapEntry(
        Alignment.bottomLeft,
        Point(
          this.left.value!,
          this.top.value! + height.value,
        ).squaredDistanceTo(Point(0, size.height)),
      ),
      MapEntry(
        Alignment.bottomRight,
        Point(
          this.left.value! + width.value,
          this.top.value! + height.value,
        ).squaredDistanceTo(Point(size.width, size.height)),
      ),
    ]..sort((e1, e2) => e1.value.compareTo(e2.value));

    Alignment align = alignments.first.key;
    double left = this.left.value!;
    double top = this.top.value!;

    this.top.value = null;
    this.left.value = null;
    right.value = null;
    bottom.value = null;

    if (align == Alignment.topLeft) {
      this.top.value = top;
      this.left.value = left;
    } else if (align == Alignment.topRight) {
      this.top.value = top;
      right.value = width.value + left <= size.width
          ? right.value = size.width - left - width.value
          : 0;
    } else if (align == Alignment.bottomLeft) {
      this.left.value = left;
      bottom.value = top + height.value <= size.height
          ? size.height - top - height.value
          : 0;
    } else if (align == Alignment.bottomRight) {
      right.value = width.value + left <= size.width
          ? size.width - left - width.value
          : 0;
      bottom.value = top + height.value <= size.height
          ? size.height - top - height.value
          : 0;
    }

    bottomShifted = bottom.value ?? size.height - top - height.value;
    relocate();
  }

  /// Calculates the [offset] based on the provided [offset].
  void calculatePanning(Offset offset) {
    Offset position =
        (floatingKey.currentContext?.findRenderObject() as RenderBox?)
                ?.localToGlobal(Offset.zero) ??
            Offset.zero;

    offset = Offset(
      offset.dx - position.dx,
      offset.dy - position.dy,
    );
  }

  /// Sets the [left] and [top] correctly to the provided
  /// [offset].
  void updateOffset(Offset offset) {
    left.value = offset.dx - this.offset!.dx;
    top.value = offset.dy - this.offset!.dy;

    if (left.value! < 0) {
      left.value = 0;
    }

    if (top.value! < 0) {
      top.value = 0;
    }
  }

  /// Applies constraints to the [width], [height], [left] and [top].
  void applyConstraints() {
    width.value = _applyWidth(width.value);
    height.value = _applyHeight(height.value);
    left.value = _applyLeft(left.value);
    right.value = _applyRight(right.value);
    top.value = _applyTop(top.value);
    bottom.value = _applyBottom(bottom.value);
  }

  /// Scales the floating panel by the provided [scale].
  void scaleFloating(double scale) {
    _scaleWidth(scale);
    _scaleHeight(scale);
  }

  /// Scales the [width] according to the provided [scale].
  void _scaleWidth(double scale) {
    double width = _applyWidth(unscaledSize! * scale);
    if (width != this.width.value) {
      double widthDifference = width - this.width.value;
      this.width.value = width;
      left.value = _applyLeft(left.value! - widthDifference / 2);
      offset = offset?.translate(widthDifference / 2, 0);
    }
  }

  /// Scales the [height] according to the provided [scale].
  void _scaleHeight(double scale) {
    double height = _applyHeight(unscaledSize! * scale);
    if (height != this.height.value) {
      double heightDifference = height - this.height.value;
      this.height.value = height;
      top.value = _applyTop(top.value! - heightDifference / 2);
      offset = offset?.translate(0, heightDifference / 2);
    }
  }

  /// Returns corrected according to floating constraints [width] value.
  double _applyWidth(double width) {
    if (_minWidth > size.width * _maxWidth) {
      return size.width * _maxWidth;
    } else if (width > size.width * _maxWidth) {
      return (size.width * _maxWidth);
    } else if (width < _minWidth) {
      return _minWidth;
    }
    return width;
  }

  /// Returns corrected according to floating constraints [height] value.
  double _applyHeight(double height) {
    if (_minHeight > size.height * _maxHeight) {
      return size.height * _maxHeight;
    } else if (height > size.height * _maxHeight) {
      return size.height * _maxHeight;
    } else if (height < _minHeight) {
      return _minHeight;
    }
    return height;
  }

  /// Returns corrected according to floating constraints [left] value.
  double? _applyLeft(double? left) {
    if (left != null) {
      if (left + width.value > size.width) {
        return size.width - width.value;
      } else if (left < 0) {
        return 0;
      }
    }

    return left;
  }

  /// Returns corrected according to floating constraints [right] value.
  double? _applyRight(double? right) {
    if (right != null) {
      if (right + width.value > size.width) {
        return size.width - width.value;
      } else if (right < 0) {
        return 0;
      }
    }

    return right;
  }

  /// Returns corrected according to floating constraints [top] value.
  double? _applyTop(double? top) {
    if (top != null) {
      if (top + height.value > size.height) {
        return size.height - height.value;
      } else if (top < 0) {
        return 0;
      }
    }

    return top;
  }

  /// Returns corrected according to floating constraints [bottom] value.
  double? _applyBottom(double? bottom) {
    if (bottom != null) {
      if (bottom + height.value > size.height) {
        return size.height - height.value;
      } else if (bottom < 0) {
        return 0;
      }
    }

    return bottom;
  }
}
