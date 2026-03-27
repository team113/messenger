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

import 'package:video_player/video_player.dart';

import '../playback.dart';
import '/ui/page/player/controller.dart';
import '/util/audio_utils.dart';

/// [AudioDelegate] implemented by using a [VideoPlayerController].
class VideoPlayerDelegate extends AudioDelegate {
  /// [VideoPlayerController] driving playback for the current source.
  VideoPlayerController? _controller;

  /// Reactive [VideoPlayerController].
  ReactivePlayerController? _reactiveController;

  /// List of [_reactiveController] subscriptions.
  final List<StreamSubscription> _subscriptions = [];

  @override
  Future<void> prepare(AudioSource source) async {
    await dispose();

    _controller = _buildController(
      source,
      options: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: true,
      ),
    );

    // Guard against [dispose] `null`-ing [_controller] during initialization.
    final VideoPlayerController controller = _controller!;

    _reactiveController = ReactivePlayerController(controller);
    final ReactivePlayerController? reactive = _reactiveController;
    if (reactive != null) {
      _subscriptions.addAll([
        reactive.isPlaying.listen((v) => isPlaying.value = v),
        reactive.isBuffering.listen((v) => isLoading.value = v),
        reactive.position.listen((v) => position.value = v),
        reactive.duration.listen((v) => duration.value = v),
        reactive.isCompleted.listen((v) => isCompleted.value = v),
      ]);
    }

    await controller.initialize();

    // If dispose() was called while initializing, quit.
    if (_controller == null) return;

    await controller.setLooping(false);
  }

  @override
  Future<void> dispose() async {
    _resetState();

    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    _reactiveController?.dispose();
    _reactiveController = null;

    final VideoPlayerController? controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  @override
  Future<void> play() async => await _controller?.play();

  @override
  Future<void> pause() async => await _controller?.pause();

  @override
  Future<void> stop() async {
    await _controller?.pause();
    dispose();
  }

  @override
  Future<void> seek(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  Future<Duration> extract(AudioSource source) async {
    final VideoPlayerController controller = _buildController(source);

    try {
      await controller.initialize();
      return controller.value.duration;
    } finally {
      await controller.dispose();
    }
  }

  /// Resets state.
  void _resetState() {
    isPlaying.value = false;
    isLoading.value = true;
    isCompleted.value = false;
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }

  /// Builds a [VideoPlayerController] for the provided [AudioSource].
  VideoPlayerController _buildController(
    AudioSource source, {
    VideoPlayerOptions? options,
  }) {
    return switch (source.kind) {
      AudioSourceKind.url => VideoPlayerController.networkUrl(
        Uri.parse((source as UrlAudioSource).url),
        videoPlayerOptions: options,
      ),
      AudioSourceKind.asset => VideoPlayerController.asset(
        'assets/${(source as AssetAudioSource).asset}',
        videoPlayerOptions: options,
      ),
      AudioSourceKind.file => VideoPlayerController.networkUrl(
        Uri.file((source as FileAudioSource).file),
        videoPlayerOptions: options,
      ),
    };
  }
}
