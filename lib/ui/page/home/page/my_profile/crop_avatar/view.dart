// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:get/get.dart';

import '/api/backend/schema.dart' show CropAreaInput, PointInput;
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/image_cropper/enums.dart';
import 'widget/image_cropper/widget.dart';

/// View for cropping avatar image.
///
/// Intended to be displayed with the [show] method.
class CropAvatarView extends StatelessWidget {
  const CropAvatarView(this.image, {super.key});

  final Image image;

  /// Displays a [CropAvatarView] wrapped in a [ModalPopup].
  static Future<CropAreaInput?> show<T>(BuildContext context, Image image) {
    return ModalPopup.show<CropAreaInput?>(
      context: context,
      isDismissible: false,
      desktopPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      child: CropAvatarView(image),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;
    return GetBuilder(
      init: CropController(image: image, aspectRatio: 1),
      builder: (controller) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ImageCropper(
              controller: controller,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 30,
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: 0,
                    child: TextButton(
                      onPressed: () {
                        context.popModal();
                      },
                      child: Text(
                        'btn_cancel'.l10n,
                        style: style.fonts.medium.regular.primary,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      WidgetButton(
                        onPressed: () {
                          _rotateLeft(controller);
                        },
                        child: const Icon(Icons.rotate_90_degrees_ccw_outlined),
                      ),
                      const SizedBox(width: 20),
                      WidgetButton(
                        onPressed: () {
                          _rotateRight(controller);
                        },
                        child: const Icon(Icons.rotate_90_degrees_cw_outlined),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    child: TextButton(
                      onPressed: () {
                        _onDone(context, controller);
                      },
                      child: Text(
                        'btn_done'.l10n,
                        style: style.fonts.medium.regular.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Rotates the image 90 degrees to the left.
  Future<void> _rotateLeft(CropController controller) async =>
      controller.rotateLeft();

  /// Rotates the image 90 degrees to the right.
  Future<void> _rotateRight(CropController controller) async =>
      controller.rotateRight();

  /// Callback for when the user is done cropping the image
  Future<void> _onDone(BuildContext context, CropController controller) async {
    final Rect cropSize = controller.cropSize;
    final CropAreaInput cropArea = CropAreaInput(
      bottomRight: PointInput(
        x: cropSize.right.toInt(),
        y: cropSize.bottom.toInt(),
      ),
      topLeft: PointInput(
        x: cropSize.left.toInt(),
        y: cropSize.top.toInt(),
      ),
      angle: controller.rotation.value.angle,
    );
    context.popModal(cropArea);
  }
}
