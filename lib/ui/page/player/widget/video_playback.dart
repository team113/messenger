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

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '/themes.dart';
import '/ui/widget/progress_indicator.dart';

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
  });

  /// URL of the video to display.
  final String url;

  /// SHA-256 checksum of the video to display.
  final String? checksum;

  /// Callback, called when a [VideoPlayerController] is assigned or disposed.
  final void Function(VideoPlayerController?)? onController;

  /// Callback, called on the [VideoPlayerController] initialization errors.
  final FutureOr<void> Function()? onError;

  final double? volume;
  final void Function(double)? onVolumeChanged;
  final bool loop;

  @override
  State<VideoPlayback> createState() => _VideoPlaybackState();
}

/// State of a [VideoPlayback] used to initialize and dispose video controller.
class _VideoPlaybackState extends State<VideoPlayback> {
  /// [Timer] for displaying the loading animation when non-`null`.
  Timer? _loading;

  /// [CancelToken] for cancelling the [VideoView.url] header fetching.
  CancelToken? _cancelToken;

  /// [VideoPlayerController] to display the video.
  VideoPlayerController? _controller;

  StreamSubscription? _volumeSubscription;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initVideo();
    });

    _loading = Timer(1.seconds, () => setState(() => _loading = null));

    super.initState();
  }

  @override
  void dispose() {
    widget.onController?.call(null);
    _loading?.cancel();
    _controller?.dispose();
    _cancelToken?.cancel();
    _volumeSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoPlayback oldWidget) {
    if (oldWidget.url != widget.url) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _initVideo();
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    if (_controller != null && _controller?.value.isInitialized == true) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      );
    }

    return GestureDetector(
      key: Key(_loading != null ? 'Box' : 'Loading'),
      onTap: () {
        // Intercept `onTap` event to prevent [GalleryPopup]
        // closing.
      },
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.99,
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: style.colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: _loading != null
              ? const SizedBox()
              : const Center(child: CustomProgressIndicator()),
        ),
      ),
    );
  }

  /// Initializes the [_controller].
  Future<void> _initVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    widget.onController?.call(_controller);

    // _volumeSubscription?.cancel();
    // _volumeSubscription = _controller.player.stream.volume.listen((e) {
    //   widget.onVolumeChanged?.call(e);
    // });

    try {
      if (widget.volume != null) {
        await _controller?.setVolume(widget.volume!);
      }

      if (widget.loop) {
        await _controller?.setLooping(true);
      }
    } catch (_) {
      // No-op.
    }

    setState(() {});

    // _cancelToken?.cancel();
    // _cancelToken = CancelToken();

    // bool shouldReload = false;

    // try {
    //   await Backoff.run(() async {
    //     try {
    //       await (await PlatformUtils.dio).head(widget.url);
    //       if (shouldReload) {
    //         // Reinitialize the [_controller] if an unexpected error was thrown.
    //         await _controller.player.open(Media(widget.url));
    //       }
    //     } catch (e) {
    //       if (e is DioException && e.response?.statusCode == 403) {
    //         widget.onError?.call();
    //       } else {
    //         shouldReload = true;
    //         rethrow;
    //       }
    //     }
    //   }, cancel: _cancelToken);
    // } on OperationCanceledException {
    //   // No-op.
    // }
  }
}
