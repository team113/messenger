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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show CropAreaInput, PointInput;
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/image_cropper/enums.dart';
import 'widget/image_cropper/widget.dart';

/// View for cropping an image specified as the [Uint8List].
///
/// Intended to be displayed with [show] method.
class CropAvatarView extends StatelessWidget {
  const CropAvatarView(this.image, {super.key});

  /// [Uint8List] of the encoded image.
  final Uint8List image;

  /// Displays a [CropAvatarView] wrapped in a [ModalPopup].
  static Future<CropAreaInput?> show<T>(BuildContext context, Uint8List image) {
    final Size size = MediaQuery.sizeOf(context);

    return ModalPopup.show<CropAreaInput?>(
      context: context,
      isDismissible: false,
      desktopPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      modalConstraints: BoxConstraints(maxWidth: size.width * 0.6),
      child: CropAvatarView(image),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: Key('CropAvatarView'),
      init: CropController(image),
      builder: (CropController c) {
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Center(
                child: Obx(() {
                  if (c.size.isEmpty) {
                    return const CustomProgressIndicator();
                  }

                  return ImageCropper(
                    image: image,
                    size: c.size,
                    svg: c.svg,
                    rotation: c.rotation.value,
                    onCropped: (crop) => c.crop.value = crop,
                  );
                }),
              ),
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
                      onPressed: context.popModal,
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
                        onPressed: c.rotateLeft,
                        child: Icon(
                          Icons.rotate_90_degrees_ccw_outlined,
                          color: style.colors.primary,
                        ),
                      ),
                      const SizedBox(width: 20),
                      WidgetButton(
                        onPressed: c.rotateRight,
                        child: Icon(
                          Icons.rotate_90_degrees_cw_outlined,
                          color: style.colors.primary,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    child: TextButton(
                      key: Key('DoneButton'),
                      onPressed: () => _close(context, c),
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

  /// Pops this modal with [CropAreaInput] data.
  void _close(BuildContext context, CropController c) {
    context.popModal(
      CropAreaInput(
        bottomRight: PointInput(
          x: c.real.right.toInt(),
          y: c.real.bottom.toInt(),
        ),
        topLeft: PointInput(x: c.real.left.toInt(), y: c.real.top.toInt()),
        angle: c.rotation.value.angle,
      ),
    );
  }
}
