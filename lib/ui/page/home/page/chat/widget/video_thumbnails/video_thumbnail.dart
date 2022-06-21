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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import 'src/interface.dart'
    if (dart.library.io) 'src/io.dart'
    if (dart.library.html) 'src/web.dart';

/// Thumbnail displaying the first frame of the provided video.
///
/// At least one of [path] or [bytes] arguments must be specified and non-empty.
class VideoThumbnail extends StatefulWidget {
  const VideoThumbnail._({
    Key? key,
    this.path,
    this.bytes,
    this.height,
  })  : assert(
            (path != null && bytes == null) || (path == null && bytes != null)),
        super(key: key);

  /// Constructs a [VideoThumbnail] from the provided [path].
  factory VideoThumbnail.path({
    required String path,
    double? height,
    Key? key,
  }) =>
      VideoThumbnail._(key: key, path: path, height: height);

  /// Constructs a [VideoThumbnail] from the provided [bytes].
  factory VideoThumbnail.bytes({
    required Uint8List bytes,
    double? height,
    Key? key,
  }) =>
      VideoThumbnail._(key: key, bytes: bytes, height: height);

  /// URL of the video to display.
  final String? path;

  /// Bytes array of the video to display.
  final Uint8List? bytes;

  /// Optional height this [VideoThumbnail] occupies.
  final double? height;

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

/// State of a [VideoThumbnail], used to initialize and dispose a
/// [VideoPlayerController].
class _VideoThumbnailState extends State<VideoThumbnail> {
  /// [VideoPlayerController] to display the first frame of the video.
  late VideoPlayerController _controller;

  /// Indicator whether the [_initVideo] has failed.
  bool _hasError = false;

  @override
  void initState() {
    _initVideo();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = 0;
    double height = 0;

    if (_controller.value.isInitialized) {
      width = _controller.value.size.width;
      height = _controller.value.size.height;

      if (widget.height != null) {
        width = width * widget.height! / height;
        height = widget.height!;
      }
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: _controller.value.isInitialized
          ? SizedBox(
              width: width,
              height: height,
              child: IgnorePointer(
                child: ContextMenuInterceptor(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            )
          : SizedBox(
              width: 250,
              height: widget.height ?? 250,
              child: _hasError
                  ? null
                  : const Center(child: CircularProgressIndicator()),
            ),
    );
  }

  /// Initializes the [_controller].
  Future<void> _initVideo() async {
    try {
      if (widget.bytes != null) {
        _controller = VideoPlayerControllerExt.bytes(widget.bytes!);
      } else {
        _controller = VideoPlayerController.network(widget.path!);
      }

      await _controller.initialize();
    } on PlatformException catch (_) {
      // Plugin is not supported on the current platform.
      _hasError = true;
    }

    if (mounted) {
      setState(() {});
    }
  }
}
