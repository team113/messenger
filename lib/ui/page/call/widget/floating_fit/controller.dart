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
import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart' show VideoView;
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/routes.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

export 'view.dart';

/// Controller of an [OngoingCall] overlay.
class FloatingFitController extends GetxController {
  FloatingFitController({required this.relocateRect});

  final Rx<Rect?>? relocateRect;

  /// Indicator whether the secondary view is being scaled.
  final RxBool secondaryScaled = RxBool(false);

  /// Indicator whether the secondary view is being dragged.
  final RxBool secondaryDragged = RxBool(false);

  /// Indicator whether the secondary view is being manipulated in any way, be
  /// that scaling or panning.
  final RxBool secondaryManipulated = RxBool(false);

  /// Secondary view current left position.
  final RxnDouble secondaryLeft = RxnDouble(null);

  /// Secondary view current top position.
  final RxnDouble secondaryTop = RxnDouble(null);

  /// Secondary view current right position.
  final RxnDouble secondaryRight = RxnDouble(10);

  /// Secondary view current bottom position.
  final RxnDouble secondaryBottom = RxnDouble(10);

  /// Secondary view current width.
  late final RxDouble secondaryWidth;

  /// Secondary view current height.
  late final RxDouble secondaryHeight;

  /// [secondaryWidth] or [secondaryHeight] of the secondary view before its
  /// scaling.
  double? secondaryUnscaledSize;

  /// [Offset] the secondary view has relative to the pan gesture position.
  Offset? secondaryPanningOffset;

  /// [GlobalKey] of the secondary view.
  final GlobalKey secondaryKey = GlobalKey();

  /// [secondaryBottom] value before the secondary view got relocated with the
  /// [relocateSecondary] method.
  double? secondaryBottomShifted = 10;

  /// Indicator whether the [relocateSecondary] is already invoked during the
  /// current frame.
  bool _secondaryRelocated = false;

  /// [Worker] reacting on the [relocateRect] changes relocating secondary view.
  Worker? relocateWorker;

  /// Max width of the secondary view in percentage of the call width.
  static const double _maxSWidth = 0.80;

  /// Max height of the secondary view in percentage of the call height.
  static const double _maxSHeight = 0.80;

  /// Min width of the secondary view in pixels.
  static const double _minSWidth = 125;

  /// Min height of the secondary view in pixels.
  static const double _minSHeight = 125;

  /// Returns actual size of the call view.
  Size size = Size.zero;

  @override
  void onInit() {
    super.onInit();

    double secondarySize = (size.shortestSide *
            (size.aspectRatio > 2 || size.aspectRatio < 0.5 ? 0.45 : 0.33))
        .clamp(_minSHeight, 250);
    secondaryWidth = RxDouble(secondarySize);
    secondaryHeight = RxDouble(secondarySize);

    if (relocateRect != null) {
      relocateWorker = ever(relocateRect!, (_) => relocateSecondary());
    }
  }

  @override
  void onClose() {
    super.onClose();
    relocateWorker?.dispose();
  }

  /// Relocates the secondary view accounting the possible intersections.
  void relocateSecondary() {
    if (secondaryDragged.isFalse &&
        secondaryScaled.isFalse &&
        !_secondaryRelocated) {
      _secondaryRelocated = true;

      final Rect? secondaryBounds = secondaryKey.globalPaintBounds;
      Rect intersect =
          secondaryBounds?.intersect(relocateRect?.value ?? Rect.zero) ??
              Rect.zero;
      print(secondaryBounds);
      print(relocateRect?.value);

      intersect = Rect.fromLTWH(
        intersect.left,
        intersect.top,
        intersect.width,
        intersect.height + 10,
      );

      print(intersect.width);
      print(intersect.height);

      if (intersect.width > 0 && intersect.height > 0) {
        // Intersection is non-zero, so move the secondary panel up.
        if (secondaryBottom.value != null) {
          secondaryBottom.value = secondaryBottom.value! + intersect.height;
        } else {
          secondaryTop.value = secondaryTop.value! - intersect.height;
        }

        applySecondaryConstraints();
      } else if ((intersect.height < 0 || intersect.width < 0) &&
          secondaryBottomShifted != null) {
        // Intersection is less than zero and the secondary panel is higher than
        // it was before, so move it to its original position.
        double bottom = secondaryBottom.value ??
            size.height - secondaryTop.value! - secondaryHeight.value;
        if (bottom > secondaryBottomShifted!) {
          double difference = bottom - secondaryBottomShifted!;
          if (secondaryBottom.value != null) {
            if (difference.abs() < intersect.height.abs() ||
                intersect.width < 0) {
              secondaryBottom.value = secondaryBottomShifted;
            } else {
              secondaryBottom.value = secondaryBottom.value! + intersect.height;
            }
          } else {
            if (difference.abs() < intersect.height.abs() ||
                intersect.width < 0) {
              secondaryTop.value =
                  size.height - secondaryHeight.value - secondaryBottomShifted!;
            } else {
              secondaryTop.value = secondaryTop.value! - intersect.height;
            }
          }

          applySecondaryConstraints();
        }
      }

      SchedulerBinding.instance
          .addPostFrameCallback((_) => _secondaryRelocated = false);
    }
  }

  /// Calculates the appropriate [secondaryLeft], [secondaryRight],
  /// [secondaryTop] and [secondaryBottom] values according to the nearest edge.
  void updateSecondaryAttach() {
    secondaryLeft.value ??=
        size.width - secondaryWidth.value - (secondaryRight.value ?? 0);
    secondaryTop.value ??=
        size.height - secondaryHeight.value - (secondaryBottom.value ?? 0);

    List<MapEntry<Alignment, double>> alignments = [
      MapEntry(
        Alignment.topLeft,
        Point(
          secondaryLeft.value!,
          secondaryTop.value!,
        ).squaredDistanceTo(const Point(0, 0)),
      ),
      MapEntry(
        Alignment.topRight,
        Point(
          secondaryLeft.value! + secondaryWidth.value,
          secondaryTop.value!,
        ).squaredDistanceTo(Point(size.width, 0)),
      ),
      MapEntry(
        Alignment.bottomLeft,
        Point(
          secondaryLeft.value!,
          secondaryTop.value! + secondaryHeight.value,
        ).squaredDistanceTo(Point(0, size.height)),
      ),
      MapEntry(
        Alignment.bottomRight,
        Point(
          secondaryLeft.value! + secondaryWidth.value,
          secondaryTop.value! + secondaryHeight.value,
        ).squaredDistanceTo(Point(size.width, size.height)),
      ),
    ]..sort((e1, e2) => e1.value.compareTo(e2.value));

    Alignment align = alignments.first.key;
    double left = secondaryLeft.value!;
    double top = secondaryTop.value!;

    secondaryTop.value = null;
    secondaryLeft.value = null;
    secondaryRight.value = null;
    secondaryBottom.value = null;

    if (align == Alignment.topLeft) {
      secondaryTop.value = top;
      secondaryLeft.value = left;
    } else if (align == Alignment.topRight) {
      secondaryTop.value = top;
      secondaryRight.value = secondaryWidth.value + left <= size.width
          ? secondaryRight.value = size.width - left - secondaryWidth.value
          : 0;
    } else if (align == Alignment.bottomLeft) {
      secondaryLeft.value = left;
      secondaryBottom.value = top + secondaryHeight.value <= size.height
          ? size.height - top - secondaryHeight.value
          : 0;
    } else if (align == Alignment.bottomRight) {
      secondaryRight.value = secondaryWidth.value + left <= size.width
          ? size.width - left - secondaryWidth.value
          : 0;
      secondaryBottom.value = top + secondaryHeight.value <= size.height
          ? size.height - top - secondaryHeight.value
          : 0;
    }

    secondaryBottomShifted =
        secondaryBottom.value ?? size.height - top - secondaryHeight.value;
    relocateSecondary();
  }

  /// Calculates the [secondaryPanningOffset] based on the provided [offset].
  void calculateSecondaryPanning(Offset offset) {
    Offset position =
        (secondaryKey.currentContext?.findRenderObject() as RenderBox?)
                ?.localToGlobal(Offset.zero) ??
            Offset.zero;

    secondaryPanningOffset = Offset(
      offset.dx - position.dx,
      offset.dy - position.dy,
    );
  }

  /// Sets the [secondaryLeft] and [secondaryTop] correctly to the provided
  /// [offset].
  void updateSecondaryOffset(Offset offset) {
    secondaryLeft.value = offset.dx - secondaryPanningOffset!.dx;
    secondaryTop.value = offset.dy - secondaryPanningOffset!.dy;

    if (secondaryLeft.value! < 0) {
      secondaryLeft.value = 0;
    }

    if (secondaryTop.value! < 0) {
      secondaryTop.value = 0;
    }
  }

  /// Applies constraints to the [secondaryWidth], [secondaryHeight],
  /// [secondaryLeft] and [secondaryTop].
  void applySecondaryConstraints() {
    secondaryWidth.value = _applySWidth(secondaryWidth.value);
    secondaryHeight.value = _applySHeight(secondaryHeight.value);
    secondaryLeft.value = _applySLeft(secondaryLeft.value);
    secondaryRight.value = _applySRight(secondaryRight.value);
    secondaryTop.value = _applySTop(secondaryTop.value);
    secondaryBottom.value = _applySBottom(secondaryBottom.value);
  }

  /// Scales the secondary view by the provided [scale].
  void scaleSecondary(double scale) {
    _scaleSWidth(scale);
    _scaleSHeight(scale);
  }

  /// Scales the [secondaryWidth] according to the provided [scale].
  void _scaleSWidth(double scale) {
    double width = _applySWidth(secondaryUnscaledSize! * scale);
    if (width != secondaryWidth.value) {
      double widthDifference = width - secondaryWidth.value;
      secondaryWidth.value = width;
      secondaryLeft.value =
          _applySLeft(secondaryLeft.value! - widthDifference / 2);
      secondaryPanningOffset =
          secondaryPanningOffset?.translate(widthDifference / 2, 0);
    }
  }

  /// Scales the [secondaryHeight] according to the provided [scale].
  void _scaleSHeight(double scale) {
    double height = _applySHeight(secondaryUnscaledSize! * scale);
    if (height != secondaryHeight.value) {
      double heightDifference = height - secondaryHeight.value;
      secondaryHeight.value = height;
      secondaryTop.value =
          _applySTop(secondaryTop.value! - heightDifference / 2);
      secondaryPanningOffset =
          secondaryPanningOffset?.translate(0, heightDifference / 2);
    }
  }

  /// Returns corrected according to secondary constraints [width] value.
  double _applySWidth(double width) {
    if (_minSWidth > size.width * _maxSWidth) {
      return size.width * _maxSWidth;
    } else if (width > size.width * _maxSWidth) {
      return (size.width * _maxSWidth);
    } else if (width < _minSWidth) {
      return _minSWidth;
    }
    return width;
  }

  /// Returns corrected according to secondary constraints [height] value.
  double _applySHeight(double height) {
    if (_minSHeight > size.height * _maxSHeight) {
      return size.height * _maxSHeight;
    } else if (height > size.height * _maxSHeight) {
      return size.height * _maxSHeight;
    } else if (height < _minSHeight) {
      return _minSHeight;
    }
    return height;
  }

  /// Returns corrected according to secondary constraints [left] value.
  double? _applySLeft(double? left) {
    if (left != null) {
      if (left + secondaryWidth.value > size.width) {
        return size.width - secondaryWidth.value;
      } else if (left < 0) {
        return 0;
      }
    }

    return left;
  }

  /// Returns corrected according to secondary constraints [right] value.
  double? _applySRight(double? right) {
    if (right != null) {
      if (right + secondaryWidth.value > size.width) {
        return size.width - secondaryWidth.value;
      } else if (right < 0) {
        return 0;
      }
    }

    return right;
  }

  /// Returns corrected according to secondary constraints [top] value.
  double? _applySTop(double? top) {
    if (top != null) {
      if (top + secondaryHeight.value > size.height) {
        return size.height - secondaryHeight.value;
      } else if (top < 0) {
        return 0;
      }
    }

    return top;
  }

  /// Returns corrected according to secondary constraints [bottom] value.
  double? _applySBottom(double? bottom) {
    if (bottom != null) {
      if (bottom + secondaryHeight.value > size.height) {
        return size.height - secondaryHeight.value;
      } else if (bottom < 0) {
        return 0;
      }
    }

    return bottom;
  }
}

/// X-axis scale mode.
enum ScaleModeX { left, right }

/// Y-axis scale mode.
enum ScaleModeY { top, bottom }

/// Separate call entity participating in a call.
class Participant {
  Participant(
    this.member, {
    Track? video,
    Track? audio,
    RxUser? user,
  })  : user = Rx(user),
        video = Rx(video),
        audio = Rx(audio);

  /// [CallMember] this [Participant] represents.
  final CallMember member;

  /// [User] this [Participant] represents.
  final Rx<RxUser?> user;

  /// Reactive video track of this [Participant].
  final Rx<Track?> video;

  /// Reactive audio track of this [Participant].
  final Rx<Track?> audio;

  /// [GlobalKey] of this [Participant]'s [VideoView].
  final GlobalKey videoKey = GlobalKey();

  /// Returns the [MediaSourceKind] of this [Participant].
  MediaSourceKind get source =>
      video.value?.source ?? audio.value?.source ?? MediaSourceKind.Device;
}
