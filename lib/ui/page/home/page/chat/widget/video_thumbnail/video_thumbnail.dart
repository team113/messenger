// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:io';

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
  })  : bytes = null,
        path = null;

  /// Constructs a [VideoThumbnail] from the provided [bytes].
  const VideoThumbnail.bytes(
    this.bytes, {
    super.key,
    this.height,
    this.width,
    this.onError,
  })  : url = null,
        checksum = null,
        path = null;

  /// Constructs a [VideoThumbnail] from the provided file [path].
  const VideoThumbnail.file(
    this.path, {
    super.key,
    this.height,
    this.width,
    this.onError,
  })  : url = null,
        checksum = null,
        bytes = null;

  /// URL of the video to display.
  final String? url;

  /// SHA-256 checksum of the video to display.
  final String? checksum;

  /// Byte data of the video to display.
  final Uint8List? bytes;

  /// Path to the video [File] to display.
  final String? path;

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
  /// [Player] opening and maintaining the video to use in [_controller].
  final Player _player = Player();

  /// [VideoController] to display the first frame of the video.
  late final VideoController _controller = VideoController(
    _player,
    configuration: const VideoControllerConfiguration(
      enableHardwareAcceleration: true,
    ),
  );

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
        stream: _player.stream.width,
        builder: (_, __) {
          double width = 300;
          double height = 300;

          if (widget.width != null && widget.height != null) {
            width = widget.width!;
            height = widget.height!;
          } else if (_player.state.width != null) {
            width = _player.state.width!.toDouble();
            height = _player.state.height!.toDouble();

            if (widget.height != null) {
              width = width * widget.height! / height;
              height = widget.height!;
            }
          }

          return SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: SizedBox(
                    width: _player.state.width?.toDouble() ?? width,
                    height: _player.state.height?.toDouble() ?? height,
                    child: IgnorePointer(
                      child: Video(
                        controller: _controller,
                        fit: BoxFit.cover,
                        controls: (_) => const SizedBox(),
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
        },
      ),
    );
  }

  /// Initializes the [_controller].
  Future<void> _initVideo() async {
    Uint8List? bytes = widget.bytes;
    File? file;

    if (widget.path != null) {
      file = File(widget.path!);
    }

    if (bytes == null &&
        file == null &&
        widget.checksum != null &&
        CacheWorker.instance.exists(widget.checksum!)) {
      final CacheEntry cache = await CacheWorker.instance.get(
        checksum: widget.checksum!,
        responseType: CacheResponseType.file,
      );

      bytes = cache.bytes;
      file = cache.file;
    } else if (bytes != null) {
      file = await CacheWorker.instance.add(bytes) ?? file;
    }

    try {
      if (file != null) {
        await _player.open(Media(file.path), play: false);
      } else if (bytes != null) {
        await _player.open(await Media.memory(bytes), play: false);
      } else {
        await _player.open(Media(widget.url!), play: false);
      }
    } catch (_) {
      // No-op.
    }

    if (widget.url != null && bytes == null) {
      _cancelToken?.cancel();
      _cancelToken = CancelToken();

      bool shouldReload = false;

      try {
        await Backoff.run(
          () async {
            try {
              await (await PlatformUtils.dio).head(widget.url!);

              // Reinitialize the [_controller] if an unexpected error was
              // thrown.
              if (shouldReload) {
                await _player.open(Media(widget.url!), play: false);
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
      } on OperationCanceledException {
        // No-op.
      }
    }
  }
}
