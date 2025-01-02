// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '/themes.dart';

/// Button-styled volume [Icon] controlling the [controller].
class VolumeButton extends StatelessWidget {
  const VolumeButton(
    this.controller, {
    super.key,
    this.height,
    this.margin,
    this.padding,
    this.onTap,
    this.onEnter,
  });

  /// [VideoController] controlling the [Video] player functionality.
  final VideoController controller;

  /// Height of this [VolumeButton].
  final double? height;

  /// Optional margin of this [VolumeButton].
  final EdgeInsetsGeometry? margin;

  /// Optional padding of this [VolumeButton].
  final EdgeInsetsGeometry? padding;

  /// Callback, called when a mouse pointer has entered this [VolumeButton].
  final void Function(PointerEnterEvent)? onEnter;

  /// Callback, called when this [VolumeButton] is tapped.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: onEnter,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          margin: margin,
          padding: padding,
          child: StreamBuilder(
            stream: controller.player.stream.volume,
            initialData: controller.player.state.volume,
            builder: (_, volume) {
              return Icon(
                volume.data! > 0 ? Icons.volume_up : Icons.volume_off,
                color: style.colors.onPrimary,
                size: 18,
              );
            },
          ),
        ),
      ),
    );
  }
}
