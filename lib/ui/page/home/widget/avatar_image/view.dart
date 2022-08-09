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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gif/gif.dart';
import 'package:messenger/ui/page/home/widget/avatar_image/controller.dart';

/// Animation behavior type
enum AnimationConfig {
  /// Animation loops and custom actions disabled
  always,

  /// Animation plays once and then only plays when clicked or hovered
  standard,

  /// Animation not playing and custom actions disabled
  never,
}

/// User image with or not animation
class AvatarImage extends StatefulWidget {
  AvatarImage(
      {Key? key,
      AvatarImageController? controller,
      this.config = AnimationConfig.standard,
      required this.imageUrl,})
      : controller = controller ?? AvatarImageController(),
        super(key: key);

  /// Image link
  final String imageUrl;
  /// Customizing animation behavior
  ///
  /// Defines behavior [controller]
  /// By default matters [AnimationConfig.standard]
  final AnimationConfig config;

  /// [AvatarImage]'s controller
  final AvatarImageController controller;

  @override
  State<AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<AvatarImage>
    with TickerProviderStateMixin {
  /// Initial animation behavior for [Gif]
  late Autostart _autostart;

  @override
  void initState() {
    super.initState();
    widget.controller.gifController ??= Rx(GifController(vsync: this));
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
  void didChangeDependencies() {
    widget.controller.gifController ??= Rx(GifController(vsync: this));
    super.didChangeDependencies();
  }
  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: widget.controller,
      builder: (AvatarImageController c){
        return GestureDetector(
          onTap: c.onTap,
          child: MouseRegion(
            onHover: c.onHover,
            onExit: c.onHover,
            child: Gif(
              fit: BoxFit.fill,
              image: NetworkImage(widget.imageUrl,),
              controller: c.gifController?.value ,
              autostart: _autostart,
            ),
          ),
        );
      },
    );
  }
}
