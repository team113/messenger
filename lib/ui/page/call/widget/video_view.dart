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
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/ongoing_call.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';

/// Real-time WebRTC video stream representation of its [renderer].
///
/// Wrapper around a [VideoView] with some additional decorations.
class RtcVideoView extends StatefulWidget {
  const RtcVideoView(
    this.renderer, {
    Key? key,
    this.source = MediaSourceKind.Device,
    this.borderRadius,
    this.enableContextMenu = true,
    this.fit,
    this.label,
    this.mirror = false,
    this.muted = false,
    this.outline,
    this.respectAspectRatio = false,
    this.offstageUntilDetermined = false,
    this.onSizeDetermined,
    this.framelessBuilder,
  }) : super(key: key);

  /// Renderer to display WebRTC video stream from.
  final RtcVideoRenderer renderer;

  /// [MediaSourceKind] of this [RtcVideoView].
  final MediaSourceKind source;

  /// Indicator whether this video should be horizontally mirrored or not.
  final bool mirror;

  /// [BoxFit] mode of this video.
  final BoxFit? fit;

  /// Indicator whether this video should display `muted` icon or not.
  final bool muted;

  /// Optional label of this video.
  final String? label;

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

  /// Callback, called when the video's size is determined.
  final Function? onSizeDetermined;

  /// Indicator whether default context menu is enabled over this video or not.
  ///
  /// Only effective under the web, since only web has default context menu.
  final bool enableContextMenu;

  /// Optional outline of this video.
  final Color? outline;

  /// Calculates an optimal [BoxFit] mode for the provided [renderer].
  static BoxFit determineBoxFit(
    RtcVideoRenderer renderer,
    MediaSourceKind source,
    BoxConstraints constraints,
    BuildContext context,
  ) {
    if (source == MediaSourceKind.Display ||
        (renderer.width == 0 && renderer.height == 0)) {
      return BoxFit.contain;
    } else {
      bool contain = false;

      if (context.isMobile) {
        // Video is horizontal.
        if (renderer.aspectRatio >= 1) {
          double width = constraints.maxWidth;
          double height =
              renderer.height * (constraints.maxWidth / renderer.width);
          double factor = constraints.maxHeight / height;
          contain = factor >= 3.0;
          if (factor < 1) {
            width = renderer.width * (constraints.maxHeight / renderer.height);
            height = constraints.maxHeight;
            factor = constraints.maxWidth / width;
            contain = factor >= 2.5;
          }
        }
        // Video is vertical.
        else {
          double width =
              renderer.width * (constraints.maxHeight / renderer.height);
          double height = constraints.maxHeight;
          double factor = constraints.maxWidth / width;
          contain = factor >= 3.9;
          if (factor < 1) {
            width = constraints.maxWidth;
            height = renderer.height * (constraints.maxWidth / renderer.width);
            factor = constraints.maxHeight / height;
            contain = factor >= 3.0;
          }
        }
      } else {
        // Video is horizontal.
        if (renderer.aspectRatio >= 1) {
          double width = constraints.maxWidth;
          double height =
              renderer.height * (constraints.maxWidth / renderer.width);
          double factor = constraints.maxHeight / height;
          contain = factor >= 2.41;
          if (factor < 1) {
            width = renderer.width * (constraints.maxHeight / renderer.height);
            height = constraints.maxHeight;
            factor = constraints.maxWidth / width;
            contain = factor >= 1.5;
          }
        }
        // Video is vertical.
        else {
          double width =
              renderer.width * (constraints.maxHeight / renderer.height);
          double height = constraints.maxHeight;
          double factor = constraints.maxWidth / width;
          contain = factor >= 2.0;
          if (factor < 1) {
            width = constraints.maxWidth;
            height = renderer.height * (constraints.maxWidth / renderer.width);
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
    Widget video = VideoView(
      widget.renderer.inner,
      key: _videoKey,
      mirror: widget.mirror,
      objectFit: VideoViewObjectFit.cover,
      enableContextMenu: widget.enableContextMenu,
    );

    // Wait for the size to be determined if necessary.
    if (widget.offstageUntilDetermined) {
      if (widget.renderer.height == 0) {
        _waitTilSizeDetermined();
        return Stack(
          children: [
            Offstage(child: video),
            if (widget.framelessBuilder != null) widget.framelessBuilder!(),
            const Center(child: CircularProgressIndicator())
          ],
        );
      }
    }

    // Returns [AspectRatio] of [video] if [respectAspectRatio] or [video]
    // otherwise.
    Widget aspected(BoxFit? fit) {
      if (widget.respectAspectRatio && fit != BoxFit.cover) {
        if (widget.renderer.inner.videoHeight == 0) {
          _waitTilSizeDetermined();
          if (widget.framelessBuilder != null) {
            return widget.framelessBuilder!();
          }

          return Stack(
            children: [
              Offstage(child: video),
              const Center(child: CircularProgressIndicator())
            ],
          );
        }

        return AspectRatio(
          aspectRatio: widget.renderer.inner.videoWidth /
              widget.renderer.inner.videoHeight,
          child: video,
        );
      }

      if (fit == BoxFit.contain) {
        if (widget.renderer.inner.videoHeight == 0) {
          return video;
        }

        return AspectRatio(
          aspectRatio: widget.renderer.inner.videoWidth /
              widget.renderer.inner.videoHeight,
          child: video,
        );
      }

      return video;
    }

    // Returns [ClipRRect] of [aspected] if [borderRadius] is not `null` or
    // [aspected] otherwise.
    Widget clipped(BoxFit? fit) => widget.borderRadius == null
        ? aspected(fit)
        : ClipRRect(borderRadius: widget.borderRadius, child: aspected(fit));

    // Returns outlined [Container] with [clipped] if [outline] is not null or
    // [clipped] otherwise.
    Widget outlined(BoxFit? fit) => Container(
          decoration: widget.outline == null
              ? null
              : BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: widget.outline!),
                  borderRadius: widget.borderRadius,
                ),
          child: clipped(fit),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        RtcVideoRenderer renderer = widget.renderer;

        BoxFit? fit;
        if (widget.source != MediaSourceKind.Display) {
          fit = widget.fit;
        }

        // Calculate the default [BoxFit] if there's no explicit fit.
        fit ??= RtcVideoView.determineBoxFit(
          renderer,
          widget.source,
          constraints,
          context,
        );

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            outlined(fit),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: widget.muted || widget.label != null
                  ? Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 6.3),
                      margin: const EdgeInsets.only(bottom: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: const Color(0xDD818181),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.muted) const SizedBox(width: 1),
                          if (widget.muted)
                            SvgLoader.asset(
                              'assets/icons/microphone_off_small.svg',
                              width: 11,
                            ),
                          Flexible(
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: widget.label != null
                                  ? Padding(
                                      padding: EdgeInsets.only(
                                          left: widget.muted ? 6 : 1),
                                      child: Text(
                                        widget.label!,
                                        style: context.theme.outlinedButtonTheme
                                            .style!.textStyle!
                                            .resolve({
                                          MaterialState.disabled
                                        })!.copyWith(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.clip,
                                      ),
                                    )
                                  : const SizedBox(width: 1, height: 25),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: 1, height: 1),
            ),
          ],
        );
      },
    );
  }

  /// Recursively waits for the [RtcVideoRenderer]'s size to be determined and
  /// requests a rebuild when it becomes determined.
  void _waitTilSizeDetermined() {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        if (widget.renderer.inner.videoHeight == 0) {
          _waitTilSizeDetermined();
        } else {
          setState(() => widget.onSizeDetermined?.call());
        }
      }
    });
  }
}
