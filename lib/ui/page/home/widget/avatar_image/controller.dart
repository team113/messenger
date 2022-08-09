// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:gif/gif.dart';
import 'package:messenger/ui/page/home/widget/avatar_image/view.dart';

/// Controller of an [AvatarImage] widget.
class AvatarImageController extends GetxController {
  AvatarImageController({
    Key? key,
  });

  /// [Gif]'s controller in [AvatarImage]
  Rx<GifController?>? gifController;

  /// Hover callback for [MouseRegion]
  Function(PointerEvent)? onHover;

  /// Tap callback
  Function()? onTap;

  // /// Defining a [GifController] for the [Gif] that we will control
  // void setGifController(GifController controller) {
  //   gifController = Rx<GifController>(controller);
  // }

  /// [onHover] callback
  void setOnHover() => onHover = _onHover;

  /// [onTap] callback
  void setOnTap() => onTap = _onTap;

  ///Default [gifController] behavior on hover
  void _onHover(PointerEvent event) {
    if (event is PointerHoverEvent) {
      gifController!.value!.repeat();
      return;
    }
    gifController!.value!.reset();
  }

  ///Default [gifController] behavior on tap
  void _onTap() {
    gifController!.value!.forward(from: 0);
  }
}
