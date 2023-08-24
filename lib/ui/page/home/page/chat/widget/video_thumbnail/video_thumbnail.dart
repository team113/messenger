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

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '/themes.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/worker/cache.dart';
import '/util/backoff.dart';
import '/util/platform_utils.dart';

/// Thumbnail displaying the first frame of the provided video.
class VideoThumbnail extends StatefulWidget {
  /// Constructs a [VideoThumbnail] from the provided [url].
  const VideoThumbnail.url(
    this.url, {
    super.key,
    this.checksum,
    this.height,
    this.width,
    this.onError,
  }) : bytes = null;

  /// Constructs a [VideoThumbnail] from the provided [bytes].
  const VideoThumbnail.bytes(
    this.bytes, {
    super.key,
    this.height,
    this.width,
    this.onError,
  })  : url = null,
        checksum = null;

  /// URL of the video to display.
  final String? url;

  /// SHA-256 checksum of the video to display.
  final String? checksum;

  /// Byte data of the video to display.
  final Uint8List? bytes;

  /// Optional height this [VideoThumbnail] occupies.
  final double? height;

  /// Optional width this [VideoThumbnail] occupies.
  final double? width;

  /// Callback, called on the video loading errors.
  final Future<void> Function()? onError;

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

/// State of a [VideoThumbnail], used to initialize and dispose a
/// [VideoController].
class _VideoThumbnailState extends State<VideoThumbnail> {
  /// [VideoController] to display the first frame of the video.
  final VideoController _controller = VideoController(Player());

  /// [CancelToken] for cancelling the [VideoThumbnail.url] header fetching.
  CancelToken? _cancelToken;

  @override
  void initState() {
    _initVideo();
    super.initState();
  }

  @override
  void dispose() {
    _controller.player.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoThumbnail oldWidget) {
    if (oldWidget.bytes != widget.bytes || oldWidget.url != widget.url) {
      _initVideo();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: StreamBuilder(
        stream: _controller.player.stream.width,
        builder: (_, __) {
          double width = 0;
          double height = 0;

          if (widget.width != null && widget.height != null) {
            width = widget.width!;
            height = widget.height!;
          } else if (_controller.player.state.width != null) {
            width = _controller.player.state.width!.toDouble();
            height = _controller.player.state.height!.toDouble();

            if (widget.height != null) {
              width = width * widget.height! / height;
              height = widget.height!;
            }
          }

          if (_controller.player.state.width != null) {
            return SizedBox(
              width: width,
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width:
                            _controller.player.state.width?.toDouble() ?? 1920,
                        height:
                            _controller.player.state.height?.toDouble() ?? 1080,
                        child: IgnorePointer(
                          child: Video(
                            controller: _controller,
                            fit: BoxFit.cover,
                            controls: (_) => const SizedBox(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ContextMenuInterceptor(child: const SizedBox()),

                  // [Container] for receiving pointer events over this
                  // [VideoThumbnail], since the [ContextMenuInterceptor] above
                  // intercepts them.
                  Container(color: style.colors.transparent),
                ],
              ),
            );
          } else {
            return SizedBox(
              width: widget.width ?? 250,
              height: widget.height ?? 250,
            );
          }
        },
      ),
    );
  }

  /// Initializes the [_controller].
  Future<void> _initVideo() async {
    Uint8List? bytes = widget.bytes;
    if (bytes == null &&
        widget.checksum != null &&
        CacheWorker.instance.exists(widget.checksum!)) {
      bytes = await CacheWorker.instance.get(checksum: widget.checksum!);
    }

    try {
      if (bytes != null) {
        await _controller.player.open(await Media.memory(bytes), play: false);
      } else {
        await _controller.player.open(
          Media(widget.url!),
          play: false,
        );
      }
    } catch (_) {
      // No-op.
    }

    if (widget.url != null && bytes == null) {
      _cancelToken?.cancel();
      _cancelToken = CancelToken();

      bool shouldReload = false;

      await Backoff.run(
        () async {
          try {
            await (await PlatformUtils.dio).head(widget.url!);

            // Reinitialize the [_controller] if an unexpected error was
            // thrown.
            if (shouldReload) {
              await _controller.player.open(Media(widget.url!), play: false);
            }
          } catch (e) {
            if (e is DioException && e.response?.statusCode == 403) {
              widget.onError?.call();
              _cancelToken?.cancel();
            } else {
              shouldReload = true;
              rethrow;
            }
          }
        },
        _cancelToken,
      );
    }
  }
}
