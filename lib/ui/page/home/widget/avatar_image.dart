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
import 'package:gif/gif.dart';

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
  const AvatarImage({
    Key? key,
    required this.animate,
    required this.imageUrl,
    this.config = AnimationConfig.standard,
  }) : super(key: key);

  /// Image link
  final String imageUrl;

  /// Flag for [AvatarImage] animation
  final bool animate;

  /// Customizing animation behavior
  ///
  /// By default matters [AnimationConfig.standard]
  final AnimationConfig config;

  @override
  State<AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<AvatarImage>
    with TickerProviderStateMixin {
  /// Initial animation behavior for [Gif]
  late Autostart _autostart;

  /// [_controller] for [Gif]
  late GifController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GifController(vsync: this);

    switch (widget.config) {
      case AnimationConfig.always:
        _autostart = Autostart.loop;
        break;
      case AnimationConfig.standard:
        _autostart = Autostart.once;
        break;
      case AnimationConfig.never:
        _autostart = Autostart.no;
        break;
    }
  }

  @override
  void didUpdateWidget(covariant AvatarImage oldWidget) {
    if (!mounted) return;
    if (widget.animate && widget.config == AnimationConfig.standard) {
      _controller.repeat();
    } else {
      _controller.reset();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.config == AnimationConfig.standard
          ? _controller.forward(from: 0)
          : null,
      child: MouseRegion(
        onHover: (_) => widget.config == AnimationConfig.standard
            ? _controller.repeat()
            : null,
        onExit: (_) => widget.config == AnimationConfig.standard
            ? _controller.reset()
            : null,
        child: Gif(
          fit: BoxFit.cover,
          image: NetworkImage(
            widget.imageUrl,
          ),
          controller: _controller,
          autostart: _autostart,
        ),
      ),
    );
  }
}
