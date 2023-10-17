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

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';

/// View for adding and confirming an [UserEmail].
///
/// Intended to be displayed with the [show] method.
class CropAvatarView extends StatelessWidget {
  const CropAvatarView(
      {super.key, required this.fileData, required this.imageBytes});

  /// .
  final fileData;
  final imageBytes;

  /// .
  static Future<T?> show<T>(
      BuildContext context, var fileData, var imageBytes) async {
    return ModalPopup.show(
        context: context,
        child: CropAvatarView(
          fileData: fileData,
          imageBytes: imageBytes,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double height = size.height;
    final double width = size.width;

    final style = Theme.of(context).style;

    final aspectRatio = fileData.width / fileData.height;

    final imageWidget = Image.memory(
      imageBytes,
      width: aspectRatio < 1 ? 380 / aspectRatio : 380,
      height: aspectRatio > 1 ? 380 / aspectRatio : 380,
      fit: BoxFit.fill,
    );

    imageWidget.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) {
        //print("Фактическая height изображения: $realHeight");
        //print("Фактическая width изображения: $realWidth");
        print("Высота экрана: $height");
        print("Ширина экрана: $width");
      }),
    );

    final Widget header = ModalPopupHeader(
      text: 'Crop',
    );
// Text(
//               widget.label ?? 'btn_proceed'.l10n,
//               style: style.fonts.bodyMediumOnPrimary,
//             ),
    return Container(
      width: 300,
      height: 600,
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                header,
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      child: imageWidget,
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        color: Colors.red,
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _CropMenu(),
          ),
        ],
      ),
    );
  }
}

class _CropMenu extends StatelessWidget {
  const _CropMenu({super.key});

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
            icon: Icon(Icons.rotate_90_degrees_ccw),
            onPressed: () {
              // setState(() {
              //   rotateAngle -= pi/2;
              //   final double tempHeight = newMaxHeight;
              //   newMaxHeight = newMaxWidth;
              //   newMaxWidth = tempHeight;
              // });
            },
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
            onPressed: () {
              // setState(() {
              //   rotateAngle += pi/2;

              // });
            },
          ),
          const SizedBox(width: 20),
          OutlinedRoundedButton(
            onPressed: () {},
            title: Text(
              'btn_proceed'.l10n,
            ),
          )
        ],
      ),
    );
  }
}
