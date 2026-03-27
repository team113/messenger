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

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/ongoing_call.dart';
import '/ui/widget/progress_indicator.dart';
import '/util/platform_utils.dart';

/// Real-time WebRTC video stream representation of its [renderer].
///
/// Wrapper around a [VideoView] with some additional decorations.
class RtcVideoView extends StatefulWidget {
  const RtcVideoView(
    this.renderer, {
    super.key,
    this.source = MediaSourceKind.device,
    this.borderRadius,
    this.enableContextMenu = true,
    this.fit,
    this.onFit,
    this.border,
    this.respectAspectRatio = false,
    this.offstageUntilDetermined = false,
    this.framelessBuilder,
  });

  /// Renderer to display WebRTC video stream from.
  final RtcVideoRenderer renderer;

  /// [MediaSourceKind] of this [RtcVideoView].
  final MediaSourceKind source;

  /// [BoxFit] mode of this video.
  final BoxFit? fit;

  /// Callback, called when [BoxFit] is determined.
  final void Function(BoxFit)? onFit;

  /// Border radius of this video.
  final BorderRadius? borderRadius;

  /// Builder building the background when the video's size is not determined.
  final Widget Function()? framelessBuilder;

  /// Indicator whether this video should take exactly the size of its
  /// [renderer]'s video stream.
  final bool respectAspectRatio;

  /// Indicator whether this video should be placed in an [Offstage] until its
  /// size is determined.
  final bool offstageUntilDetermined;

  /// Indicator whether default context menu is enabled over this video or not.
  ///
  /// Only effective under the web, since only web has default context menu.
  final bool enableContextMenu;

  /// Optional border to apply to this [RtcVideoView].
  final Border? border;

  /// Calculates an optimal [BoxFit] mode for the provided [renderer].
  static BoxFit determineBoxFit(
    RtcVideoRenderer renderer,
    MediaSourceKind source,
    BoxConstraints constraints,
    BuildContext context,
  ) {
    if (source == MediaSourceKind.display ||
        (renderer.width.value == 0 && renderer.height.value == 0)) {
      return BoxFit.contain;
    } else {
      bool contain = false;

      final double aspectRatio = renderer.width.value / renderer.height.value;

      if (context.isMobile) {
        // Video is horizontal.
        if (aspectRatio >= 1) {
          double width = constraints.maxWidth;
          double height =
              renderer.height.value *
              (constraints.maxWidth / renderer.width.value);
          double factor = constraints.maxHeight / height;
          contain = factor >= 3.0;
          if (factor < 1) {
            width =
                renderer.width.value *
                (constraints.maxHeight / renderer.height.value);
            height = constraints.maxHeight;
            factor = constraints.maxWidth / width;
            contain = factor >= 2.5;
          }
        }
        // Video is vertical.
        else {
          double width =
              renderer.width.value *
              (constraints.maxHeight / renderer.height.value);
          double height = constraints.maxHeight;
          double factor = constraints.maxWidth / width;
          contain = factor >= 3.9;
          if (factor < 1) {
            width = constraints.maxWidth;
            height =
                renderer.height.value *
                (constraints.maxWidth / renderer.width.value);
            factor = constraints.maxHeight / height;
            contain = factor >= 3.0;
          }
        }
      } else {
        // Video is horizontal.
        if (aspectRatio >= 1) {
          double width = constraints.maxWidth;
          double height =
              renderer.height.value *
              (constraints.maxWidth / renderer.width.value);
          double factor = constraints.maxHeight / height;
          contain = factor >= 2.41;
          if (factor < 1) {
            width =
                renderer.width.value *
                (constraints.maxHeight / renderer.height.value);
            height = constraints.maxHeight;
            factor = constraints.maxWidth / width;
            contain = factor >= 1.5;
          }
        }
        // Video is vertical.
        else {
          double width =
              renderer.width.value *
              (constraints.maxHeight / renderer.height.value);
          double height = constraints.maxHeight;
          double factor = constraints.maxWidth / width;
          contain = factor >= 2.0;
          if (factor < 1) {
            width = constraints.maxWidth;
            height =
                renderer.height.value *
                (constraints.maxWidth / renderer.width.value);
            factor = constraints.maxHeight / height;
            contain = factor >= 2.2;
          }
        }
      }

      return contain ? BoxFit.contain : BoxFit.cover;
    }
  }

  @override
  State<RtcVideoView> createState() => _RtcVideoViewState();
}

/// State of a [RtcVideoView] used to rebuild itself on size determination.
class _RtcVideoViewState extends State<RtcVideoView> {
  /// [GlobalKey] of the [VideoView].
  final GlobalKey _videoKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final Widget video = VideoView(
      widget.renderer.inner,
      key: _videoKey,
      mirror: widget.renderer.mirror,
      objectFit: VideoViewObjectFit.cover,
      enableContextMenu: widget.enableContextMenu,
    );

    // Returns [AspectRatio] of [video] if [respectAspectRatio] or [video]
    // otherwise.
    Widget aspected(BoxFit? fit) {
      if (widget.respectAspectRatio && fit != BoxFit.cover) {
        return Obx(() {
          if (!widget.renderer.canPlay.value) {
            if (widget.framelessBuilder != null) {
              return widget.framelessBuilder!();
            }

            return Stack(
              children: [
                video,
                const Center(child: CustomProgressIndicator.big()),
              ],
            );
          }

          if (widget.renderer.height.value == 0) {
            return video;
          }

          return AspectRatio(
            aspectRatio:
                widget.renderer.width.value / widget.renderer.height.value,
            child: video,
          );
        });
      }

      if (fit == BoxFit.contain) {
        return Obx(() {
          if (widget.renderer.height.value == 0) {
            return video;
          }

          return AspectRatio(
            aspectRatio:
                widget.renderer.width.value / widget.renderer.height.value,
            child: video,
          );
        });
      }

      return video;
    }

    // Returns [ClipRRect] of [aspected] if [borderRadius] is not `null` or
    // [aspected] otherwise.
    Widget clipped(BoxFit? fit) => widget.borderRadius == null
        ? aspected(fit)
        : ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: aspected(fit),
          );

    // Returns outlined [Container] with [clipped] if [outline] is not null or
    // [clipped] otherwise.
    Widget outlined(BoxFit? fit) => AnimatedContainer(
      duration: 200.milliseconds,
      decoration: BoxDecoration(
        border: widget.border,
        borderRadius: widget.borderRadius?.add(BorderRadius.circular(4)),
      ),
      child: clipped(fit),
    );

    final Widget builder = LayoutBuilder(
      builder: (context, constraints) {
        RtcVideoRenderer renderer = widget.renderer;

        BoxFit? fit;
        if (widget.source != MediaSourceKind.display) {
          fit = widget.fit;
        }

        // Calculate the default [BoxFit] if there's no explicit fit.
        fit ??= RtcVideoView.determineBoxFit(
          renderer,
          widget.source,
          constraints,
          context,
        );

        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (fit != null) {
            widget.onFit?.call(fit);
          }
        });

        return outlined(fit);
      },
    );

    // Wait for the size to be determined if necessary.
    if (widget.offstageUntilDetermined) {
      return Obx(() {
        if (!widget.renderer.canPlay.value) {
          return Stack(
            children: [
              video,
              if (widget.framelessBuilder != null) widget.framelessBuilder!(),
              const Center(child: CustomProgressIndicator.big()),
            ],
          );
        }

        return builder;
      });
    }

    return builder;
  }
}
