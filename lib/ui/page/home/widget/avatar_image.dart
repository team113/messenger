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
import 'package:get/get.dart';
import 'package:gif/gif.dart';

enum AnimationConfig { always, standard, never }

class AvatarImageController extends GetxController {
  AvatarImageController({
    Key? key,
  });

  late Rx<GifController> gifController;
  Function(PointerEvent)? onHover;
  Function()? onTap;

  void setGifController(GifController controller) {
    gifController = Rx<GifController>(controller);
  }

  void setOnHover() => onHover = _onHover;

  void setOnTap() => onTap = _onTap;

  void _onHover(PointerEvent event) {
    if (event is PointerEnterEvent) {
      gifController.value.repeat();
      return;
    }
    gifController.value.reset();
  }

  void _onTap() {
    gifController.value.forward(from: 0);
  }
}

class AvatarImage extends StatefulWidget {
  AvatarImage(
      {Key? key,
      AvatarImageController? controller,
      this.config = AnimationConfig.standard})
      : controller = controller ?? AvatarImageController(),
        super(key: key);

  final AnimationConfig config;
  final AvatarImageController controller;

  @override
  State<AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<AvatarImage>
    with TickerProviderStateMixin {
  late Autostart _autostart;

  @override
  void initState() {
    super.initState();
    widget.controller.setGifController(GifController(vsync: this));
    switch (widget.config) {
      case AnimationConfig.always:
        _autostart = Autostart.loop;
        break;
      case AnimationConfig.standard:
        _autostart = Autostart.once;
        widget.controller.setOnHover();
        widget.controller.setOnTap();
        break;
      case AnimationConfig.never:
        _autostart = Autostart.no;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: widget.controller,
      builder: (AvatarImageController c) => GestureDetector(
        onTap: c.onTap,
        child: MouseRegion(
          onEnter: c.onHover,
          onExit: c.onHover,
          child: Gif(
            image: const NetworkImage(
                'https://gapopa.net/files/47/17/35/83/bb/de/a3/f1/51/2d/d6/2d/6a/8f/31/ac/orig.gif'),
            controller: c.gifController.value,
            autostart: _autostart,
          ),
        ),
      ),
    );
  }
}
