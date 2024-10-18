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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '/util/platform_utils.dart';
import '/api/backend/schema.dart' show CropAreaInput, PointInput;
import '/ui/widget/modal_popup.dart';
import 'controller.dart';
import 'widget/image_cropper/enums.dart';
import 'widget/image_cropper/widget.dart';

/// View for cropping avatar image.
///
/// Intended to be displayed with the [show] method.
class CropAvatarView extends StatefulWidget {
  const CropAvatarView(this.image, {super.key});

  final PlatformFile image;

  /// Displays a [CropAvatarView] wrapped in a [ModalPopup].
  static Future<CropAreaInput?> show<T>(
      BuildContext context, PlatformFile image) {
    return ModalPopup.show<CropAreaInput?>(
      context: context,
      isDismissible: false,
      child: CropAvatarView(image),
    );
  }

  @override
  State<CropAvatarView> createState() => _CropAvatarViewState();
}

class _CropAvatarViewState extends State<CropAvatarView> {
  /// Controller for the [ImageCropper].
  late final CropController controller;

  @override
  void initState() {
    controller = CropController(aspectRatio: 1);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ImageCropper(
          controller: controller,
          image: Image.memory(widget.image.bytes!),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.rotate_90_degrees_ccw_outlined),
              onPressed: _rotateLeft,
            ),
            IconButton(
              icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
              onPressed: _rotateRight,
            ),
            TextButton(
              onPressed: _onDone,
              child: const Text('Done'),
            ),
          ],
        ),
      ],
    );
  }

  /// Rotates the image 90 degrees to the left.
  Future<void> _rotateLeft() async => controller.rotateLeft();

  /// Rotates the image 90 degrees to the right.
  Future<void> _rotateRight() async => controller.rotateRight();

  /// Callback for when the user is done cropping the image
  Future<void> _onDone() async {
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
      angle: controller.rotation.angle,
    );
    context.popModal(cropArea);
  }
}
