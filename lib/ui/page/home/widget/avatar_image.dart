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
import 'package:gif/gif.dart';

enum AnimationConfig { always, standard, never }

class AvatarImage extends StatefulWidget {
  const AvatarImage({Key? key, this.config = AnimationConfig.standard})
      : super(key: key);

  final AnimationConfig config;

  @override
  State<AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<AvatarImage>
    with TickerProviderStateMixin {
  late GifController _controller;

  void Function()? tapAnimation;

  void Function(PointerEvent)? hoverAnimation;

  late Autostart _autostart;

  @override
  void initState() {
    super.initState();
    switch (widget.config) {
      case AnimationConfig.always:
        _autostart = Autostart.loop;
        break;
      case AnimationConfig.standard:
        _autostart = Autostart.once;
        tapAnimation = _onTap;
        hoverAnimation = _onHover;
        break;
      case AnimationConfig.never:
        _autostart = Autostart.no;
        break;
    }

    _controller = GifController(vsync: this);
  }

  void _onHover(PointerEvent event) {
    if (event is PointerEnterEvent) {
      _controller.repeat();
      return;
    }
    _controller.reset();
  }

  void _onTap() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: MouseRegion(
        onEnter: (event) => _onHover(event),
        onExit: (event) => _onHover(event),
        child: Gif(
          image: const NetworkImage(
              'https://gapopa.net/files/47/17/35/83/bb/de/a3/f1/51/2d/d6/2d/6a/8f/31/ac/orig.gif'),
          controller: _controller,
          autostart: _autostart,
        ),
      ),
    );
  }
}
