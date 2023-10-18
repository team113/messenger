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
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import 'controller.dart';

/// View for avatar cropping mechanism.
///
/// Intended to be displayed with the [show] method.
class CropAvatarView extends StatelessWidget {
  const CropAvatarView({
    super.key,
    required this.originalImageWidth,
    required this.originalImageHeight,
    required this.imageBytes,
    required this.updateAvatar,
    required this.imageFile,
  });

  /// .
  final Function updateAvatar;

  /// .
  final int originalImageWidth;

  /// .
  final int originalImageHeight;

  /// .
  final Uint8List imageBytes;

  /// .
  final XFile imageFile;

  /// .
  static Future<T?> show<T>(
    BuildContext context,
    int originalImageWidth,
    int originalImageHeight,
    Uint8List imageBytes,
    Function updateAvatar,
    XFile imageFile,
  ) async {
    return ModalPopup.show(
        context: context,
        child: CropAvatarView(
          originalImageWidth: originalImageWidth,
          originalImageHeight: originalImageHeight,
          imageBytes: imageBytes,
          updateAvatar: updateAvatar,
          imageFile: imageFile,
        ));
  }

  @override
  Widget build(BuildContext context) {
    //final Size size = MediaQuery.of(context).size;
    //final double height = size.height;
    //final double width = size.width;
    const double maxWidth = 350;
    const double maxHeight = 350;

    final aspectRatio = originalImageWidth / originalImageHeight;
    final imageWidth = aspectRatio < 1 ? maxWidth * aspectRatio : maxWidth;
    final imageHeight = aspectRatio > 1 ? maxHeight / aspectRatio : maxHeight;

    //final style = Theme.of(context).style;

    final imageWidget = Image.memory(
      imageBytes,
      width: imageWidth,
      height: imageHeight,
      fit: BoxFit.fill,
    );
    // final previewTile = AvatarWidget.fromContact(
    //   null,
    //   avatar: imageWidget as Avatar,
    // );

    Widget header = ModalPopupHeader(text: 'label_avatar_crop'.l10n);

    return GetBuilder(
        init: CropAvatarController(
          updateAvatar: updateAvatar,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
        ),
        builder: (CropAvatarController c) {
          return Obx(() {
            return SizedBox(
              width: 300,
              height: 600,
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        header,
                        const SizedBox(height: 50),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              child: Transform.rotate(
                                angle: c.rotateAngle.value,
                                child: imageWidget,
                              ),
                            ),
                            DarkenLayer(
                              imageWidth: imageWidth,
                              imageHeight: imageHeight,
                            ),
                            Positioned(
                              left: c.cropAreaOffsetX.value,
                              top: c.cropAreaOffsetY.value,
                              child: SizedBox(
                                width: c.cropAreaWidth.value,
                                height: c.cropAreaHeight.value,
                                child: MouseRegion(
                                  //cursor: SystemMouseCursors.zoomOut,
                                  child: GestureDetector(
                                    onPanUpdate: (details) {
                                      c.cropAreaOffsetX.value =
                                          (details.delta.dx +
                                                  c.cropAreaOffsetX.value)
                                              .clamp(
                                                  0,
                                                  imageWidth -
                                                      c.cropAreaWidth.value);

                                      c.cropAreaOffsetY.value =
                                          (details.delta.dy +
                                                  c.cropAreaOffsetY.value)
                                              .clamp(
                                                  0,
                                                  imageHeight -
                                                      c.cropAreaHeight.value);
                                    },
                                    child: CustomPaint(
                                      painter: CropAreaPainter(
                                          cropAreaWidth: c.cropAreaWidth.value),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: c.cropAreaOffsetX.value +
                                  c.cropAreaWidth.value -
                                  40,
                              top: c.cropAreaOffsetY.value +
                                  c.cropAreaHeight.value -
                                  40,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  c.cropAreaWidth.value =
                                      imageHeight - c.cropAreaOffsetY.value ==
                                                  c.cropAreaHeight.value &&
                                              details.delta.dx > 0
                                          ? c.cropAreaWidth.value
                                          : (c.cropAreaWidth.value +
                                                  details.delta.dx)
                                              .clamp(
                                                  100,
                                                  imageWidth -
                                                      c.cropAreaOffsetX.value);
                                  if (c.cropAreaWidth.value ==
                                      imageWidth - c.cropAreaOffsetX.value) {
                                    return;
                                  }

                                  c.cropAreaHeight.value =
                                      (c.cropAreaHeight.value +
                                              details.delta.dx)
                                          .clamp(
                                              100,
                                              imageHeight -
                                                  c.cropAreaOffsetY.value);
                                },
                                child: ClipPath(
                                  clipper: ResizeAreaClipper(),
                                  child: Container(
                                    color: Colors.white,
                                    width: 50,
                                    height: 50,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _CropMenu(
                      onRotateCw: c.onRotateCw,
                      onRotateCcw: c.onRotateCcw,
                      uploadAvatar: c.uploadAvatar,
                      imageFile: imageFile,
                      imageBytes: imageBytes,
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }
}

/// Menu to interact with the image.
class _CropMenu extends StatelessWidget {
  _CropMenu({
    required this.onRotateCw,
    required this.onRotateCcw,
    required this.uploadAvatar,
    required this.imageFile,
    required this.imageBytes,
  });

  final Function onRotateCw;
  final Function onRotateCcw;
  final Function uploadAvatar;
  final XFile imageFile;
  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_ccw),
            onPressed: () {
              onRotateCcw();
            },
          ),
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
            onPressed: () {
              onRotateCw();
            },
          ),
          const SizedBox(width: 10),
          OutlinedRoundedButton(
            onPressed: () {
              uploadAvatar(
                imageFile,
                imageBytes,
              );
            },
            title: Text(
              'btn_proceed'.l10n,
            ),
          )
        ],
      ),
    );
  }
}

class ResizeAreaClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height * 0.9);
    path.lineTo(size.width * 0.9, size.height * 0.9);
    path.lineTo(size.width * 0.9, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

/// [DarkenLayer] creates a darkening effect.
class DarkenLayer extends StatelessWidget {
  const DarkenLayer({
    super.key,
    required this.imageWidth,
    required this.imageHeight,
  });
  final double imageWidth;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(imageWidth, imageHeight),
      painter: DarkenPainter(),
    );
  }
}

/// Painter for [DarkenLayer].
class DarkenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..blendMode = BlendMode.srcOver;

    canvas.drawRect(
      Rect.fromPoints(
        const Offset(0, 0),
        Offset(size.width, size.height),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

/// Painter for [CropArea].
class CropAreaPainter extends CustomPainter {
  CropAreaPainter({required this.cropAreaWidth});

  final double cropAreaWidth;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..blendMode = BlendMode.overlay;
    Paint squarePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..blendMode = BlendMode.overlay;

    canvas.drawRect(
      Rect.fromPoints(
        const Offset(0, 0),
        Offset(size.width, size.height),
      ),
      squarePaint,
    );

    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), cropAreaWidth / 2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
