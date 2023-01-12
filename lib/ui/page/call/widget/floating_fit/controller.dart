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

/// Controller of an [FloatingFit].
class FloatingFitController extends GetxController {
  FloatingFitController({required this.relocateRect});

  /// [Rect] to relocate the floating panel.
  final Rx<Rect?>? relocateRect;

  /// Indicator whether the floating panel is being scaled.
  final RxBool floatingScaled = RxBool(false);

  /// Indicator whether the floating panel is being dragged.
  final RxBool floatingDragged = RxBool(false);

  /// Secondary view current left position.
  final RxnDouble floatingLeft = RxnDouble(null);

  /// Secondary view current top position.
  final RxnDouble floatingTop = RxnDouble(null);

  /// Secondary view current right position.
  final RxnDouble floatingRight = RxnDouble(10);

  /// Secondary view current bottom position.
  final RxnDouble floatingBottom = RxnDouble(10);

  /// Secondary view current width.
  late final RxDouble floatingWidth;

  /// Secondary view current height.
  late final RxDouble floatingHeight;

  /// [floatingWidth] or [floatingHeight] of the floating panel before its
  /// scaling.
  double? floatingUnscaledSize;

  /// [Offset] the floating panel has relative to the pan gesture position.
  Offset? floatingPanningOffset;

  /// [GlobalKey] of the floating panel.
  final GlobalKey floatingKey = GlobalKey();

  /// [floatingBottom] value before the floating panel got relocated with the
  /// [relocateFloating] method.
  double? floatingBottomShifted = 10;

  /// Indicator whether the [relocateFloating] is already invoked during the
  /// current frame.
  bool _floatingRelocated = false;

  /// [Worker] reacting on the [relocateRect] changes relocating floating panel.
  Worker? _relocateWorker;

  /// Max width of the floating panel in percentage of the call width.
  static const double _maxFWidth = 0.80;

  /// Max height of the floating panel in percentage of the call height.
  static const double _maxFHeight = 0.80;

  /// Min width of the floating panel in pixels.
  static const double _minFWidth = 125;

  /// Min height of the floating panel in pixels.
  static const double _minFHeight = 125;

  /// Returns actual size of the [FloatingFit] this controller is bound to.
  Size size = Size.zero;

  @override
  void onInit() {
    super.onInit();

    double floatingSize = (size.shortestSide *
            (size.aspectRatio > 2 || size.aspectRatio < 0.5 ? 0.45 : 0.33))
        .clamp(_minFHeight, 250);
    floatingWidth = RxDouble(floatingSize);
    floatingHeight = RxDouble(floatingSize);

    if (relocateRect != null) {
      _relocateWorker = ever(relocateRect!, (_) => relocateFloating());
    }
  }

  @override
  void onClose() {
    super.onClose();
    _relocateWorker?.dispose();
  }

  /// Relocates the floating panel accounting the possible intersections.
  void relocateFloating() {
    if (floatingDragged.isFalse &&
        floatingScaled.isFalse &&
        !_floatingRelocated) {
      _floatingRelocated = true;

      final Rect? floatingBounds = floatingKey.globalPaintBounds;
      Rect intersect =
          floatingBounds?.intersect(relocateRect?.value ?? Rect.zero) ??
              Rect.zero;

      intersect = Rect.fromLTWH(
        intersect.left,
        intersect.top,
        intersect.width,
        intersect.height + 10,
      );

      if (intersect.width > 0 && intersect.height > 0) {
        // Intersection is non-zero, so move the floating panel up.
        if (floatingBottom.value != null) {
          floatingBottom.value = floatingBottom.value! + intersect.height;
        } else {
          floatingTop.value = floatingTop.value! - intersect.height;
        }

        applyFloatingConstraints();
      } else if ((intersect.height < 0 || intersect.width < 0) &&
          floatingBottomShifted != null) {
        // Intersection is less than zero and the floating panel is higher than
        // it was before, so move it to its original position.
        double bottom = floatingBottom.value ??
            size.height - floatingTop.value! - floatingHeight.value;
        if (bottom > floatingBottomShifted!) {
          double difference = bottom - floatingBottomShifted!;
          if (floatingBottom.value != null) {
            if (difference.abs() < intersect.height.abs() ||
                intersect.width < 0) {
              floatingBottom.value = floatingBottomShifted;
            } else {
              floatingBottom.value = floatingBottom.value! + intersect.height;
            }
          } else {
            if (difference.abs() < intersect.height.abs() ||
                intersect.width < 0) {
              floatingTop.value =
                  size.height - floatingHeight.value - floatingBottomShifted!;
            } else {
              floatingTop.value = floatingTop.value! - intersect.height;
            }
          }

          applyFloatingConstraints();
        }
      }

      SchedulerBinding.instance
          .addPostFrameCallback((_) => _floatingRelocated = false);
    }
  }

  /// Calculates the appropriate [floatingLeft], [floatingRight],
  /// [floatingTop] and [floatingBottom] values according to the nearest edge.
  void updateFloatingAttach() {
    floatingLeft.value ??=
        size.width - floatingWidth.value - (floatingRight.value ?? 0);
    floatingTop.value ??=
        size.height - floatingHeight.value - (floatingBottom.value ?? 0);

    List<MapEntry<Alignment, double>> alignments = [
      MapEntry(
        Alignment.topLeft,
        Point(
          floatingLeft.value!,
          floatingTop.value!,
        ).squaredDistanceTo(const Point(0, 0)),
      ),
      MapEntry(
        Alignment.topRight,
        Point(
          floatingLeft.value! + floatingWidth.value,
          floatingTop.value!,
        ).squaredDistanceTo(Point(size.width, 0)),
      ),
      MapEntry(
        Alignment.bottomLeft,
        Point(
          floatingLeft.value!,
          floatingTop.value! + floatingHeight.value,
        ).squaredDistanceTo(Point(0, size.height)),
      ),
      MapEntry(
        Alignment.bottomRight,
        Point(
          floatingLeft.value! + floatingWidth.value,
          floatingTop.value! + floatingHeight.value,
        ).squaredDistanceTo(Point(size.width, size.height)),
      ),
    ]..sort((e1, e2) => e1.value.compareTo(e2.value));

    Alignment align = alignments.first.key;
    double left = floatingLeft.value!;
    double top = floatingTop.value!;

    floatingTop.value = null;
    floatingLeft.value = null;
    floatingRight.value = null;
    floatingBottom.value = null;

    if (align == Alignment.topLeft) {
      floatingTop.value = top;
      floatingLeft.value = left;
    } else if (align == Alignment.topRight) {
      floatingTop.value = top;
      floatingRight.value = floatingWidth.value + left <= size.width
          ? floatingRight.value = size.width - left - floatingWidth.value
          : 0;
    } else if (align == Alignment.bottomLeft) {
      floatingLeft.value = left;
      floatingBottom.value = top + floatingHeight.value <= size.height
          ? size.height - top - floatingHeight.value
          : 0;
    } else if (align == Alignment.bottomRight) {
      floatingRight.value = floatingWidth.value + left <= size.width
          ? size.width - left - floatingWidth.value
          : 0;
      floatingBottom.value = top + floatingHeight.value <= size.height
          ? size.height - top - floatingHeight.value
          : 0;
    }

    floatingBottomShifted =
        floatingBottom.value ?? size.height - top - floatingHeight.value;
    relocateFloating();
  }

  /// Calculates the [floatingPanningOffset] based on the provided [offset].
  void calculateFloatingPanning(Offset offset) {
    Offset position =
        (floatingKey.currentContext?.findRenderObject() as RenderBox?)
                ?.localToGlobal(Offset.zero) ??
            Offset.zero;

    floatingPanningOffset = Offset(
      offset.dx - position.dx,
      offset.dy - position.dy,
    );
  }

  /// Sets the [floatingLeft] and [floatingTop] correctly to the provided
  /// [offset].
  void updateFloatingOffset(Offset offset) {
    floatingLeft.value = offset.dx - floatingPanningOffset!.dx;
    floatingTop.value = offset.dy - floatingPanningOffset!.dy;

    if (floatingLeft.value! < 0) {
      floatingLeft.value = 0;
    }

    if (floatingTop.value! < 0) {
      floatingTop.value = 0;
    }
  }

  /// Applies constraints to the [floatingWidth], [floatingHeight],
  /// [floatingLeft] and [floatingTop].
  void applyFloatingConstraints() {
    floatingWidth.value = _applyFWidth(floatingWidth.value);
    floatingHeight.value = _applyFHeight(floatingHeight.value);
    floatingLeft.value = _applyFLeft(floatingLeft.value);
    floatingRight.value = _applyFRight(floatingRight.value);
    floatingTop.value = _applyFTop(floatingTop.value);
    floatingBottom.value = _applyFBottom(floatingBottom.value);
  }

  /// Scales the floating panel by the provided [scale].
  void scaleFloating(double scale) {
    _scaleFWidth(scale);
    _scaleFHeight(scale);
  }

  /// Scales the [floatingWidth] according to the provided [scale].
  void _scaleFWidth(double scale) {
    double width = _applyFWidth(floatingUnscaledSize! * scale);
    if (width != floatingWidth.value) {
      double widthDifference = width - floatingWidth.value;
      floatingWidth.value = width;
      floatingLeft.value =
          _applyFLeft(floatingLeft.value! - widthDifference / 2);
      floatingPanningOffset =
          floatingPanningOffset?.translate(widthDifference / 2, 0);
    }
  }

  /// Scales the [floatingHeight] according to the provided [scale].
  void _scaleFHeight(double scale) {
    double height = _applyFHeight(floatingUnscaledSize! * scale);
    if (height != floatingHeight.value) {
      double heightDifference = height - floatingHeight.value;
      floatingHeight.value = height;
      floatingTop.value = _applyFTop(floatingTop.value! - heightDifference / 2);
      floatingPanningOffset =
          floatingPanningOffset?.translate(0, heightDifference / 2);
    }
  }

  /// Returns corrected according to floating constraints [width] value.
  double _applyFWidth(double width) {
    if (_minFWidth > size.width * _maxFWidth) {
      return size.width * _maxFWidth;
    } else if (width > size.width * _maxFWidth) {
      return (size.width * _maxFWidth);
    } else if (width < _minFWidth) {
      return _minFWidth;
    }
    return width;
  }

  /// Returns corrected according to floating constraints [height] value.
  double _applyFHeight(double height) {
    if (_minFHeight > size.height * _maxFHeight) {
      return size.height * _maxFHeight;
    } else if (height > size.height * _maxFHeight) {
      return size.height * _maxFHeight;
    } else if (height < _minFHeight) {
      return _minFHeight;
    }
    return height;
  }

  /// Returns corrected according to floating constraints [left] value.
  double? _applyFLeft(double? left) {
    if (left != null) {
      if (left + floatingWidth.value > size.width) {
        return size.width - floatingWidth.value;
      } else if (left < 0) {
        return 0;
      }
    }

    return left;
  }

  /// Returns corrected according to floating constraints [right] value.
  double? _applyFRight(double? right) {
    if (right != null) {
      if (right + floatingWidth.value > size.width) {
        return size.width - floatingWidth.value;
      } else if (right < 0) {
        return 0;
      }
    }

    return right;
  }

  /// Returns corrected according to floating constraints [top] value.
  double? _applyFTop(double? top) {
    if (top != null) {
      if (top + floatingHeight.value > size.height) {
        return size.height - floatingHeight.value;
      } else if (top < 0) {
        return 0;
      }
    }

    return top;
  }

  /// Returns corrected according to floating constraints [bottom] value.
  double? _applyFBottom(double? bottom) {
    if (bottom != null) {
      if (bottom + floatingHeight.value > size.height) {
        return size.height - floatingHeight.value;
      } else if (bottom < 0) {
        return 0;
      }
    }

    return bottom;
  }
}
