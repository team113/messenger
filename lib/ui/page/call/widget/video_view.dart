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
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/ongoing_call.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';

/// Real-time WebRTC video stream representation of its [renderer].
///
/// Wrapper around a [VideoView] with some additional decorations.
class RtcVideoView extends StatefulWidget {
  const RtcVideoView(
    this.renderer, {
    super.key,
    this.source = MediaSourceKind.Device,
    this.borderRadius,
    this.enableContextMenu = true,
    this.fit,
    this.label,
    this.mirror = false,
    this.muted = false,
    this.border,
    this.respectAspectRatio = false,
    this.offstageUntilDetermined = false,
    this.onSizeDetermined,
    this.framelessBuilder,
  });

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

  /// Optional border to apply to this [RtcVideoView].
  final Border? border;

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
      autoRotate: !widget.mirror,
    );

    // Wait for the size to be determined if necessary.
    if (widget.offstageUntilDetermined) {
      if (widget.renderer.height == 0) {
        _waitTilSizeDetermined();
        return Stack(
          children: [
            Offstage(child: video),
            if (widget.framelessBuilder != null) widget.framelessBuilder!(),
            const Center(child: CustomProgressIndicator(size: 64))
          ],
        );
      }
    }

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
            Outlined(
              fit,
              borderRadius: widget.borderRadius,
              border: widget.border,
              respectAspectRatio: widget.respectAspectRatio,
              renderer: renderer,
              framelessBuilder: widget.framelessBuilder,
              video: video,
              waitTilSizeDetermined: () => _waitTilSizeDetermined(),
            ),
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
                            SvgImage.asset(
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

/// [Widget] which returns [AspectRatio] of [video] if [respectAspectRatio]
/// or [video] otherwise.
class Aspected extends StatelessWidget {
  const Aspected(
    this.fit, {
    super.key,
    required this.respectAspectRatio,
    required this.renderer,
    required this.video,
    this.framelessBuilder,
    this.waitTilSizeDetermined,
  });

  /// [BoxFit] specifies how the [video] should be fit inside the widget.
  final BoxFit? fit;

  /// Indicator whether the aspect ratio of the video should be maintained.
  final bool respectAspectRatio;

  /// Video renderer used to display the video.
  final RtcVideoRenderer renderer;

  /// Video [Widget] to be displayed.
  final Widget video;

  /// Callback called when the [video]'s frame size is not yet determined.
  final Widget Function()? framelessBuilder;

  /// Callback called when waiting for the [video]'s frame size to be determined.
  final void Function()? waitTilSizeDetermined;

  @override
  Widget build(BuildContext context) {
    if (respectAspectRatio && fit != BoxFit.cover) {
      if (renderer.inner.videoHeight == 0) {
        waitTilSizeDetermined;
        if (framelessBuilder != null) {
          return framelessBuilder!();
        }

        return Stack(
          children: [
            Offstage(child: video),
            const Center(child: CustomProgressIndicator(size: 64))
          ],
        );
      }

      return AspectRatio(
        aspectRatio: renderer.inner.videoWidth / renderer.inner.videoHeight,
        child: video,
      );
    }

    if (fit == BoxFit.contain) {
      if (renderer.inner.videoHeight == 0) {
        return video;
      }

      return AspectRatio(
        aspectRatio: renderer.inner.videoWidth / renderer.inner.videoHeight,
        child: video,
      );
    }

    return video;
  }
}

/// [Widget] which returns [ClipRRect] of [Aspected] if [borderRadius] is
/// not null or [Aspected] otherwise.
class Clipped extends StatelessWidget {
  const Clipped(
    this.fit, {
    super.key,
    required this.respectAspectRatio,
    required this.renderer,
    required this.video,
    this.borderRadius,
    this.framelessBuilder,
    this.waitTilSizeDetermined,
  });

  /// [BoxFit] specifies how the [video] should be fit inside the widget.
  final BoxFit? fit;

  /// Border radius of this video.
  final BorderRadius? borderRadius;

  /// Indicator whether the [video]'s aspect ratio should be respected or not.
  final bool respectAspectRatio;

  /// [RtcVideoRenderer] that renders the video stream.
  final RtcVideoRenderer renderer;

  /// [Widget] to display the video stream.
  final Widget video;

  /// [Function] that returns a widget to be displayed before the video stream
  /// is available.
  final Widget Function()? framelessBuilder;

  /// [Function] to call when waiting for the video stream size to be
  /// determined.
  final void Function()? waitTilSizeDetermined;

  @override
  Widget build(BuildContext context) => borderRadius == null
      ? Aspected(
          fit,
          respectAspectRatio: respectAspectRatio,
          renderer: renderer,
          video: video,
          framelessBuilder: framelessBuilder,
          waitTilSizeDetermined: waitTilSizeDetermined,
        )
      : ClipRRect(
          borderRadius: borderRadius,
          child: Aspected(
            fit,
            respectAspectRatio: respectAspectRatio,
            renderer: renderer,
            video: video,
            framelessBuilder: framelessBuilder,
            waitTilSizeDetermined: waitTilSizeDetermined,
          ));
}

/// [Widget] which returns outlined [Container] with [Clipped] if [Outlined] is
/// not null or [Clipped] otherwise.
class Outlined extends StatelessWidget {
  const Outlined(
    this.fit, {
    super.key,
    required this.respectAspectRatio,
    required this.renderer,
    required this.video,
    this.borderRadius,
    this.border,
    this.framelessBuilder,
    this.waitTilSizeDetermined,
  });

  /// [BorderRadius] of this [video].
  final BorderRadius? borderRadius;

  /// [Border] to apply to [RtcVideoView].
  final Border? border;

  /// [BoxFit] specifies how the [video] should be fit inside the widget.
  final BoxFit? fit;

  /// Indicator whether the [video]'s aspect ratio should be respected or not.
  final bool respectAspectRatio;

  /// [RtcVideoRenderer] to display.
  final RtcVideoRenderer renderer;

  /// [Widget] representing the video to display.
  final Widget video;

  /// [Function] that returns the widget to display when the video is not
  /// yet rendering.
  final Widget Function()? framelessBuilder;

  /// [Function] that waits until the size of the widget is determined.
  final void Function()? waitTilSizeDetermined;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: 200.milliseconds,
        decoration: BoxDecoration(
          border: border,
          borderRadius: borderRadius?.add(BorderRadius.circular(4)),
        ),
        child: Clipped(
          fit,
          borderRadius: borderRadius,
          respectAspectRatio: respectAspectRatio,
          renderer: renderer,
          framelessBuilder: framelessBuilder,
          video: video,
          waitTilSizeDetermined: waitTilSizeDetermined,
        ),
      );
}
