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

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '/themes.dart';
import '/ui/widget/progress_indicator.dart';
import '/util/audio_utils.dart';
import '/util/backoff.dart';
import '/util/log.dart';
import '/util/media_utils.dart';
import '/util/platform_utils.dart';

/// Video player with controls.
class VideoPlayback extends StatefulWidget {
  const VideoPlayback(
    this.url, {
    super.key,
    this.checksum,
    this.onController,
    this.onError,
    this.volume,
    this.onVolumeChanged,
    this.loop = false,
    this.autoplay = true,
  });

  /// URL of the video to display.
  final String url;

  /// SHA-256 checksum of the video to display.
  final String? checksum;

  /// Callback, called when a [VideoPlayerController] is assigned or disposed.
  final void Function(VideoPlayerController?)? onController;

  /// Callback, called on the [VideoPlayerController] initialization errors.
  final FutureOr<void> Function()? onError;

  /// Volume to start playing the video with.
  final double? volume;

  /// Callback, called when the volume of video changes.
  final void Function(double)? onVolumeChanged;

  /// Indicator whether video should loop.
  final bool loop;

  /// Indicator whether video should autoplay.
  final bool autoplay;

  @override
  State<VideoPlayback> createState() => _VideoPlaybackState();
}

/// State of a [VideoPlayback] used to initialize and dispose video controller.
class _VideoPlaybackState extends State<VideoPlayback> {
  /// [Timer] for displaying the loading animation when non-`null`.
  Timer? _loading;

  /// [CancelToken] for cancelling the [VideoView.url] fetching.
  CancelToken? _cancelToken;

  /// [CancelToken] for cancelling the [VideoView.url] header fetching.
  CancelToken? _headerToken;

  /// [VideoPlayerController] to display the video.
  VideoPlayerController? _controller;

  /// Text of an error happened during [_initVideo], if any.
  String? _error;

  /// Current volume of a video.
  double? _volume;

  /// [StreamSubscription] to [AudioUtilsImpl.acquire] with [AudioMode.video].
  StreamSubscription? _intent;

  @override
  void initState() {
    _initVideo();
    _ensureReachable();
    _loading = Timer(1.seconds, () => setState(() => _loading = null));

    _intent = AudioUtils.acquire(
      AudioMode.video,
      speaker: AudioSpeakerKind.speaker,
    ).listen((_) {});

    super.initState();
  }

  @override
  void dispose() {
    widget.onController?.call(null);
    _controller?.removeListener(_listener);
    _loading?.cancel();
    _controller?.dispose();
    _cancelToken?.cancel();
    _headerToken?.cancel();
    _intent?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoPlayback oldWidget) {
    if (oldWidget.url != widget.url) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _ensureReachable();
        await _initVideo();
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
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
      );
    }

    if (_controller != null && _controller?.value.isInitialized == true) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      );
    }

    return GestureDetector(
      key: Key(_loading != null ? 'Box' : 'Loading'),
      onTap: () {
        // Intercept `onTap` event to prevent [PlayerView] closing.
      },
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.99,
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: style.colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(child: CustomProgressIndicator()),
        ),
      ),
    );
  }

  /// Initializes the [_controller].
  Future<void> _initVideo() async {
    Log.debug('_initVideo() for `${widget.url}`', '$runtimeType');

    _controller?.removeListener(_listener);
    _controller?.dispose();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: true,
        webOptions: VideoPlayerWebOptions(
          allowContextMenu: false,
          allowRemotePlayback: false,
        ),
      ),
    );
    _controller?.addListener(_listener);

    widget.onController?.call(_controller);

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    try {
      await Backoff.run(() async {
        try {
          if (widget.volume != null) {
            await _controller?.setVolume(widget.volume!);
          }

          if (widget.loop) {
            await _controller?.setLooping(true);
          }

          Log.debug(
            '_initVideo() -> await _controller?.initialize()...',
            '$runtimeType',
          );

          await _controller?.initialize();

          Log.debug(
            '_initVideo() -> await _controller?.initialize()... done!',
            '$runtimeType',
          );

          if (widget.autoplay) {
            await _controller?.play();
          }
        } catch (e) {
          Log.error(
            'Unable to load video for `${widget.url}`: $e',
            '$runtimeType',
          );

          _error = e.toString();

          rethrow;
        }

        if (mounted) {
          setState(() {});
        }
      }, cancel: _cancelToken);
    } on OperationCanceledException {
      // No-op.
    }
  }

  /// Fetches the header of [VideoPlayback.url] to ensure that the URL is
  /// reachable.
  Future<void> _ensureReachable() async {
    Log.debug('_ensureReachable()', '$runtimeType');

    _headerToken?.cancel();
    _headerToken = CancelToken();

    try {
      await Backoff.run(() async {
        try {
          Log.debug('_ensureReachable() -> fetching HEAD...', '$runtimeType');

          await (await PlatformUtils.dio).head(widget.url);

          Log.debug(
            '_ensureReachable() -> fetching HEAD... done!',
            '$runtimeType',
          );
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
      }, cancel: _cancelToken);
    } on OperationCanceledException {
      // No-op.
    }
  }

  /// Changes the current [_volume] and invokes [VideoPlayback.onVolumeChanged].
  void _listener() {
    if (_controller != null && _controller?.value.volume != _volume) {
      if (_volume != null) {
        widget.onVolumeChanged?.call(_controller!.value.volume);
      }

      _volume = _controller?.value.volume;
    }
  }
}
