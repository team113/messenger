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

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/util/backoff.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';
import '/util/video_extension.dart';

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
    this.fit = BoxFit.contain,
    this.autoplay = false,
    this.interface = true,
  }) : bytes = null,
       path = null;

  /// Constructs a [VideoThumbnail] from the provided [bytes].
  const VideoThumbnail.bytes(
    this.bytes, {
    super.key,
    this.height,
    this.width,
    this.onError,
    this.fit = BoxFit.contain,
    this.autoplay = false,
    this.interface = true,
  }) : url = null,
       checksum = null,
       path = null;

  /// Constructs a [VideoThumbnail] from the provided file [path].
  const VideoThumbnail.file(
    this.path, {
    super.key,
    this.height,
    this.width,
    this.onError,
    this.fit = BoxFit.contain,
    this.autoplay = false,
    this.interface = true,
  }) : url = null,
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

  /// [BoxFit] to prefer displaying this [VideoThumbnail] as.
  final BoxFit fit;

  /// Callback, called on the video loading errors.
  final Future<void> Function()? onError;

  /// Indicator whether video should autoplay.
  final bool autoplay;

  /// Indicator whether duration and additional elements should be displayed.
  final bool interface;

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

/// State of a [VideoThumbnail], used to initialize and dispose a
/// [VideoPlayerController].
class _VideoThumbnailState extends State<VideoThumbnail> {
  /// [VideoPlayerController] opening and maintaining the video itself.
  VideoPlayerController? _controller;

  /// [CancelToken] for cancelling the [VideoPlayerController] initialization.
  CancelToken? _cancelToken;

  /// [CancelToken] for cancelling the [VideoThumbnail.url] header fetching.
  CancelToken? _headerToken;

  /// Error message, if any.
  String? _error;

  /// Indicator whether [VideoThumbnail.onError] was invoked during
  /// [_initVideo].
  ///
  /// This is needed to prevent the spamming of the callback, since
  /// [VideoPlayerController.initialize] doesn't specify the exact error
  /// happened during initialization.
  bool _triedOnError = false;

  /// Indicator whether the video playback was manually stopped.
  ///
  /// If `true`, the video will not autoplay on mouse hover. Otherwise, it will
  /// autoplay on mouse hover.
  bool _hasManuallyStopped = false;

  @override
  void initState() {
    _initVideo();
    _ensureReachable();
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _cancelToken?.cancel();
    _headerToken?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoThumbnail oldWidget) {
    if (oldWidget.bytes != widget.bytes || oldWidget.url != widget.url) {
      _initVideo();
      _ensureReachable();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    double width = widget.width ?? 300;
    double height = widget.height ?? 300;

    if (_error != null) {
      return SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: style.systemMessageBorder,
                color: style.systemMessageColor,
              ),
              child: Text('$_error', style: style.systemMessageStyle),
            ),
          ),
        ),
      );
    }

    if (_controller == null || _controller?.value.isInitialized == false) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final Widget child = SizedBox(
      width: switch (widget.fit) {
        BoxFit.contain => width * _controller!.value.aspectRatio,
        (_) => width,
      },
      height: height,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox.fromSize(
            size: _controller!.value.size,
            child: IgnorePointer(child: VideoPlayer(_controller!)),
          ),
        ),
      ),
    );

    if (!widget.autoplay && !widget.interface) {
      return child;
    }

    final Widget interface = Stack(
      children: [
        child,

        if (widget.interface)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: EdgeInsets.fromLTRB(7, 3, 7, 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: style.colors.onBackgroundOpacity40,
              ),
              child: ValueListenableBuilder(
                builder: (_, value, _) {
                  return Row(
                    children: [
                      if (widget.autoplay)
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (value.isPlaying) {
                              _controller?.pause();
                              _hasManuallyStopped = true;
                            } else {
                              _controller?.play();
                              _hasManuallyStopped = false;
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                            child: SvgIcon(
                              value.isPlaying
                                  ? SvgIcons.previewPause
                                  : SvgIcons.previewPlay,
                            ),
                          ),
                        ),
                      IgnorePointer(
                        child: Text(
                          (value.duration - value.position).hhMmSs(),
                          style: style.fonts.smaller.regular.onPrimary,
                        ),
                      ),
                    ],
                  );
                },
                valueListenable: _controller!,
              ),
            ),
          ),
      ],
    );

    if (!widget.autoplay) {
      return interface;
    }

    return MouseRegion(
      onEnter: (_) async {
        if (_controller!.value.isInitialized && !_hasManuallyStopped) {
          await _controller?.play();
        }
      },
      onExit: (_) async {
        if (_controller!.value.isInitialized && !_hasManuallyStopped) {
          await _controller?.pause();
          await _controller?.seekTo(Duration.zero);
        }
      },
      child: interface,
    );
  }

  /// Initializes the [_controller].
  Future<void> _initVideo() async {
    Log.debug('_initVideo(${widget.url})', '$runtimeType');

    _triedOnError = false;

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    Uint8List? bytes = widget.bytes;
    File? file;

    if (widget.path != null) {
      file = File(widget.path!);
    }

    try {
      _controller?.dispose();
      _controller = null;
    } catch (_) {
      // No-op.
    }

    try {
      final VideoPlayerOptions options = VideoPlayerOptions(
        webOptions: VideoPlayerWebOptions(
          allowContextMenu: false,
          allowRemotePlayback: false,
        ),
      );

      if (file != null) {
        _controller = VideoPlayerController.file(
          file,
          videoPlayerOptions: options,
        );
      } else if (bytes != null) {
        _controller = await VideoPlayerControllerExt.bytes(
          bytes,
          checksum: widget.checksum,
          videoPlayerOptions: options,
        );
      } else if (widget.url != null) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.url!),
          videoPlayerOptions: options,
        );
      }

      await Backoff.run(() async {
        if (_controller == null) {
          return;
        }

        try {
          Log.debug(
            '_initVideo(${widget.url}) -> await _controller?.initialize()...',
            '$runtimeType',
          );

          await _controller?.initialize();

          Log.debug(
            '_initVideo(${widget.url}) -> await _controller?.initialize()... done!',
            '$runtimeType',
          );

          if (mounted) {
            setState(() {});
          }

          await _controller?.setVolume(0);
        } catch (e) {
          if (!_triedOnError) {
            _triedOnError = true;
            await widget.onError?.call();
            _cancelToken?.cancel();
          } else {
            Log.error(
              'Unable to load thumbnail of `${widget.url}`: $e',
              '$runtimeType',
            );

            _error = e.toString();
            if (mounted) {
              setState(() {});
            }

            rethrow;
          }
        }
      }, cancel: _cancelToken);
    } on OperationCanceledException {
      Log.debug(
        '_initVideo(${widget.url}) -> OperationCanceledException',
        '$runtimeType',
      );
    } catch (e) {
      Log.error(
        'Unable to load thumbnail of `${widget.url}`: $e',
        '$runtimeType',
      );

      _error = e.toString();
    }

    if (mounted) {
      setState(() {});
    }
  }

  /// Fetches the header of [VideoThumbnail.url] to ensure that the URL is
  /// reachable.
  Future<void> _ensureReachable() async {
    Log.debug('_ensureReachable(${widget.url})', '$runtimeType');

    _headerToken?.cancel();
    _headerToken = CancelToken();

    try {
      await Backoff.run(() async {
        if (widget.url == null) {
          return;
        }

        try {
          Log.debug('_ensureReachable() -> fetching HEAD...', '$runtimeType');

          await (await PlatformUtils.dio).head(widget.url!);

          Log.debug(
            '_ensureReachable() -> fetching HEAD... done!',
            '$runtimeType',
          );

          if (mounted) {
            setState(() {});
          }
        } catch (e) {
          Log.debug(
            '_ensureReachable() -> fetching HEAD... ⛔️ failed with $e',
            '$runtimeType',
          );

          if (e is DioException && e.response?.statusCode == 403) {
            _headerToken?.cancel();

            if (widget.onError == null) {
              Log.warning(
                '_ensureReachable() -> HEAD has failed with 403, yet no `onError` handler was provided, thus the resource cannot be recovered!',
                '$runtimeType',
              );
            } else {
              await widget.onError?.call();
              if (mounted) {
                setState(() {});
              }
            }
          } else {
            rethrow;
          }
        }
      }, cancel: _headerToken);
    } on OperationCanceledException {
      Log.debug(
        '_ensureReachable(${widget.url}) -> OperationCanceledException',
        '$runtimeType',
      );
    }
  }
}
