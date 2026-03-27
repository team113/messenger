// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '/themes.dart';
import '/ui/page/call/widget/scaler.dart';
import '/util/platform_utils.dart';
import 'enums.dart';
import 'painter.dart';

/// Widget for cropping image.
///
/// Displays the image with a crop rectangle that can be moved and resized.
class ImageCropper extends StatefulWidget {
  const ImageCropper({
    super.key,
    required this.image,
    required this.size,
    this.svg,
    this.rotation = CropRotation.up,
    this.onCropped,
  });

  /// [Uint8List] of the image to display in [Image.memory].
  final Uint8List image;

  /// [Size] of the [image].
  final Size size;

  /// [PictureInfo] of the SVG [image] to display.
  final PictureInfo? svg;

  /// [CropRotation] of the image.
  final CropRotation rotation;

  /// Callback, called when the cropped [Rect] is changed.
  final void Function(Rect)? onCropped;

  @override
  State<ImageCropper> createState() => _ImageCropperState();
}

/// State of an [ImageCropper] managing the state and behavior of the image
/// cropping.
class _ImageCropperState extends State<ImageCropper> {
  /// Current crop handle point being interacted with, if any.
  CropHandlePoint? _handle;

  /// Current [Rect] to display.
  late Rect _crop = Rect.largest;

  /// Returns the preferred aspect ratio of the [_crop].
  double get _ratio => 1;

  /// Minimum pixel size crop [Rect] can be shrunk to.
  double get _minimum => widget.size.shortestSide / 10;

  @override
  void initState() {
    CustomMouseCursors.ensureInitialized();
    _ensureSize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return RotatedBox(
      quarterTurns: widget.rotation.index,
      child: AspectRatio(
        aspectRatio: widget.size.aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final Rect real = _calculate(constraints);

            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Image itself.
                if (widget.svg != null)
                  SvgPicture.memory(
                    widget.image,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    fit: BoxFit.fill,
                  )
                else
                  Image.memory(
                    widget.image,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    fit: BoxFit.fill,
                  ),

                // Grid painter.
                Positioned.fill(
                  child: MouseRegion(
                    hitTestBehavior: HitTestBehavior.translucent,
                    cursor: SystemMouseCursors.grab,
                    child: GestureDetector(
                      onPanUpdate: (d) {
                        final Rect real = _calculate(constraints);

                        _move(
                          Offset(
                            (real.left + d.delta.dx) / constraints.maxWidth,
                            (real.top + d.delta.dy) / constraints.maxHeight,
                          ),
                        );
                      },
                      child: CustomPaint(
                        foregroundPainter: CropGridPainter(
                          crop: _crop,
                          scrimColor: style.barrierColor,
                          gridColor: style.colors.onPrimary,
                          grid: _handle != null,
                        ),
                      ),
                    ),
                  ),
                ),

                // Top left.
                Positioned(
                  top: real.top - Scaler.size / 2,
                  left: real.left - Scaler.size / 2,
                  child: _scaler(
                    cursor: switch (widget.rotation) {
                      CropRotation.up || CropRotation.down =>
                        CustomMouseCursors.resizeUpLeftDownRight,
                      CropRotation.right || CropRotation.left =>
                        CustomMouseCursors.resizeUpRightDownLeft,
                    },
                    width: Scaler.size * 2,
                    height: Scaler.size * 2,
                    onDrag: (dx, dy) {
                      dx = switch (widget.rotation) {
                        CropRotation.right => -dx,
                        CropRotation.left => dx,
                        (_) => dx,
                      };

                      dy = switch (widget.rotation) {
                        CropRotation.right => dy,
                        CropRotation.left => -dy,
                        (_) => dy,
                      };

                      final Rect real = _calculate(constraints);

                      _resize(
                        CropHandle.topLeft,
                        Offset(
                          (real.left + dx) / constraints.maxWidth,
                          (real.top + dy) / constraints.maxHeight,
                        ),
                      );
                    },
                  ),
                ),

                // Top right.
                Positioned(
                  top: real.top - Scaler.size / 2,
                  left: real.left + real.width - 3 * Scaler.size / 2,
                  child: _scaler(
                    cursor: switch (widget.rotation) {
                      CropRotation.up || CropRotation.down =>
                        CustomMouseCursors.resizeUpRightDownLeft,
                      CropRotation.right || CropRotation.left =>
                        CustomMouseCursors.resizeUpLeftDownRight,
                    },
                    width: Scaler.size * 2,
                    height: Scaler.size * 2,
                    onDrag: (dx, dy) {
                      dx = switch (widget.rotation) {
                        CropRotation.right => dx,
                        CropRotation.left => -dx,
                        (_) => dx,
                      };

                      dy = switch (widget.rotation) {
                        CropRotation.right => -dy,
                        CropRotation.left => dy,
                        (_) => dy,
                      };

                      final Rect real = _calculate(constraints);

                      _resize(
                        CropHandle.topRight,
                        Offset(
                          (real.right + dx) / constraints.maxWidth,
                          (real.top + dy) / constraints.maxHeight,
                        ),
                      );
                    },
                  ),
                ),

                // Bottom left.
                Positioned(
                  top: real.top + real.height - 3 * Scaler.size / 2,
                  left: real.left - Scaler.size / 2,
                  child: _scaler(
                    cursor: switch (widget.rotation) {
                      CropRotation.up || CropRotation.down =>
                        CustomMouseCursors.resizeUpRightDownLeft,
                      CropRotation.right || CropRotation.left =>
                        CustomMouseCursors.resizeUpLeftDownRight,
                    },
                    width: Scaler.size * 2,
                    height: Scaler.size * 2,
                    onDrag: (dx, dy) {
                      dx = switch (widget.rotation) {
                        CropRotation.right => dx,
                        CropRotation.left => -dx,
                        (_) => dx,
                      };

                      dy = switch (widget.rotation) {
                        CropRotation.right => -dy,
                        CropRotation.left => dy,
                        (_) => dy,
                      };

                      final Rect real = _calculate(constraints);

                      _resize(
                        CropHandle.bottomLeft,
                        Offset(
                          (real.left + dx) / constraints.maxWidth,
                          (real.bottom + dy) / constraints.maxHeight,
                        ),
                      );
                    },
                  ),
                ),

                // Bottom right.
                Positioned(
                  top: real.top + real.height - 3 * Scaler.size / 2,
                  left: real.left + real.width - 3 * Scaler.size / 2,
                  child: _scaler(
                    cursor: switch (widget.rotation) {
                      CropRotation.up || CropRotation.down =>
                        CustomMouseCursors.resizeUpLeftDownRight,
                      CropRotation.right || CropRotation.left =>
                        CustomMouseCursors.resizeUpRightDownLeft,
                    },
                    width: Scaler.size * 2,
                    height: Scaler.size * 2,
                    onDrag: (dx, dy) {
                      dx = switch (widget.rotation) {
                        CropRotation.right => -dx,
                        CropRotation.left => dx,
                        (_) => dx,
                      };

                      dy = switch (widget.rotation) {
                        CropRotation.right => dy,
                        CropRotation.left => -dy,
                        (_) => dy,
                      };

                      final Rect real = _calculate(constraints);

                      _resize(
                        CropHandle.bottomRight,
                        Offset(
                          (real.right + dx) / constraints.maxWidth,
                          (real.bottom + dy) / constraints.maxHeight,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Returns a [Scaler] scaling the crop area.
  Widget _scaler({
    Key? key,
    MouseCursor cursor = MouseCursor.defer,
    Function(double, double)? onDrag,
    double? width,
    double? height,
  }) {
    return MouseRegion(
      cursor: cursor,
      child: Scaler(
        key: key,
        onDragUpdate: (dx, dy) {
          onDrag?.call(
            switch (widget.rotation) {
              CropRotation.down => -dx,
              (_) => dx,
            },
            switch (widget.rotation) {
              CropRotation.down => -dy,
              (_) => dy,
            },
          );
        },
        width: width ?? Scaler.size,
        height: height ?? Scaler.size,
      ),
    );
  }

  /// Returns the total [_crop] relative to the [constraints].
  Rect _calculate(BoxConstraints constraints) {
    return Rect.fromLTWH(
      _crop.left * constraints.maxWidth,
      _crop.top * constraints.maxHeight,
      _crop.width * constraints.maxWidth,
      _crop.height * constraints.maxHeight,
    );
  }

  /// Moves the crop rectangle based on the [point].
  void _move(Offset point) {
    final Rect crop = _crop.multiply(widget.size);

    _crop = Rect.fromLTWH(point.dx, point.dy, _crop.width, _crop.height);
    _crop = Rect.fromLTWH(
      (point.dx * widget.size.width).clamp(
        0,
        max(0, widget.size.width - crop.width),
      ),
      (point.dy * widget.size.height).clamp(
        0,
        max(0, widget.size.height - crop.height),
      ),
      min(widget.size.width, crop.width),
      min(widget.size.height, crop.height),
    ).divide(widget.size);

    setState(() {});

    widget.onCropped?.call(_crop);
  }

  /// Sets the initial crop with respect to the aspect ratio.
  void _ensureSize() {
    final Rect crop = _crop.multiply(widget.size);

    double left = crop.left.clamp(0, crop.right - _minimum);
    double top = crop.top.clamp(0, crop.bottom - _minimum);
    double width = crop.width.clamp(_minimum, widget.size.width);
    double height = crop.height.clamp(_minimum, widget.size.height);

    if (width / height > _ratio) {
      width = height * _ratio;
    } else {
      height = width / _ratio;
    }

    left = widget.size.width / 2 - width / 2;
    top = widget.size.height / 2 - height / 2;

    setState(
      () => _crop = Rect.fromLTWH(left, top, width, height).divide(widget.size),
    );

    widget.onCropped?.call(_crop);
  }

  /// Resizes the crop rectangle by moving corner based on [type] and [point].
  void _resize(CropHandle type, Offset point) {
    final Rect crop = _crop.multiply(widget.size);

    double left = crop.left;
    double top = crop.top;
    double right = crop.right;
    double bottom = crop.bottom;
    double minX, maxX;
    double minY, maxY;

    switch (type) {
      case CropHandle.topLeft:
        minX = 0;
        maxX = right - _minimum;
        if (minX <= maxX) {
          left = (point.dx * widget.size.width).clamp(minX, maxX);
        }

        if (left <= minX || left >= maxX) {
          return;
        }

        minY = 0;
        maxY = bottom - _minimum;
        if (minY <= maxY) {
          top = (point.dy * widget.size.height).clamp(minY, maxY);
        }
        break;

      case CropHandle.topRight:
        minX = left + _minimum;
        maxX = widget.size.width;
        if (minX <= maxX) {
          right = (point.dx * widget.size.width).clamp(minX, maxX);
        }

        if (right <= minX || right >= maxX) {
          return;
        }

        minY = 0;
        maxY = bottom - _minimum;
        if (minY <= maxY) {
          top = (point.dy * widget.size.height).clamp(minY, maxY);
        }
        break;

      case CropHandle.bottomRight:
        minX = left + _minimum;
        maxX = widget.size.width;
        if (minX <= maxX) {
          right = (point.dx * widget.size.width).clamp(minX, maxX);
        }

        if (right <= minX || right >= maxX) {
          return;
        }

        minY = top + _minimum;
        maxY = widget.size.height;
        if (minY <= maxY) {
          bottom = (point.dy * widget.size.height).clamp(minY, maxY);
        }
        break;

      case CropHandle.bottomLeft:
        minX = 0;
        maxX = right - _minimum;
        if (minX <= maxX) {
          left = (point.dx * widget.size.width).clamp(minX, maxX);
        }

        if (left <= minX || left >= maxX) {
          return;
        }

        minY = top + _minimum;
        maxY = widget.size.height;
        if (minY <= maxY) {
          bottom = (point.dy * widget.size.height).clamp(minY, maxY);
        }
        break;
    }

    final double height = bottom - top;

    switch (type) {
      case CropHandle.topLeft:
      case CropHandle.bottomLeft:
        left = right - height * _ratio;
        break;

      case CropHandle.topRight:
      case CropHandle.bottomRight:
        right = left + height * _ratio;
        break;
    }

    setState(
      () => _crop = Rect.fromLTRB(left, top, right, bottom).divide(widget.size),
    );

    widget.onCropped?.call(_crop);
  }
}
