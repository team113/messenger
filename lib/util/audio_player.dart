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

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:video_player/video_player.dart';

import '/util/audio_utils.dart';
import '/ui/page/player/controller.dart' show ReactivePlayerController;

/// Abstraction over concrete audio backends.
abstract class AudioPlaybackEngine {
  /// Whether playback is currently active.
  RxBool get isPlaying;

  /// Whether playback is currently loading or buffering.
  RxBool get isLoading;

  /// Current playback position.
  Rx<Duration> get position;

  /// Total duration of the active source.
  Rx<Duration> get duration;

  /// Whether playback reached the end of the source.
  RxBool get isCompleted;

  /// Sets the source to play and prepares the engine.
  Future<void> setSource(AudioSource source);

  /// Starts or resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Stops playback and releases source-specific resources.
  Future<void> stop();

  /// Seeks to the specified position.
  Future<void> seek(Duration position);

  /// Disposes the engine and its resources.
  Future<void> dispose();

  /// Extracts duration without starting playback.
  Future<Duration> extractDuration(AudioSource source);
}

/// Audio backend based on `just_audio`.
class JustAudioPlaybackEngine implements AudioPlaybackEngine {
  JustAudioPlaybackEngine() {
    _subscriptions.addAll([
      _player.playerStateStream.listen((state) {
        isPlaying.value = state.playing;
        isLoading.value =
            state.processingState == ja.ProcessingState.buffering ||
            state.processingState == ja.ProcessingState.loading;
        isCompleted.value =
            state.processingState == ja.ProcessingState.completed;
      }),
      _player.positionStream.distinct().listen(
        (value) => position.value = value,
      ),
      _player.durationStream.listen(
        (value) => duration.value = value ?? Duration.zero,
      ),
    ]);
  }

  @override
  final RxBool isPlaying = RxBool(false);

  @override
  final RxBool isLoading = RxBool(false);

  @override
  final Rx<Duration> position = Rx<Duration>(Duration.zero);

  @override
  final Rx<Duration> duration = Rx<Duration>(Duration.zero);

  @override
  final RxBool isCompleted = RxBool(false);

  /// Underlying [just_audio] player.
  final ja.AudioPlayer _player = ja.AudioPlayer();

  /// List of [_player] subscriptions.
  final List<StreamSubscription> _subscriptions = [];

  @override
  Future<void> setSource(AudioSource source) async {
    _resetState();
    await _player.setAudioSource(source.source);
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    await _player.dispose();
  }

  /// Uses a temporary player to read duration.
  @override
  Future<Duration> extractDuration(AudioSource source) async {
    final player = ja.AudioPlayer();
    try {
      final duration = await player.setAudioSource(source.source);
      return duration ?? Duration.zero;
    } finally {
      await player.dispose();
    }
  }

  /// Resets state.
  void _resetState() {
    isPlaying.value = false;
    isLoading.value = false;
    isCompleted.value = false;
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }
}

/// Audio backend based on `video_player`.
class VideoPlayerPlaybackEngine implements AudioPlaybackEngine {
  @override
  final RxBool isPlaying = RxBool(false);

  @override
  final RxBool isLoading = RxBool(false);

  @override
  final Rx<Duration> position = Rx<Duration>(Duration.zero);

  @override
  final Rx<Duration> duration = Rx<Duration>(Duration.zero);

  @override
  final RxBool isCompleted = RxBool(false);

  /// [VideoPlayerController] driving playback for the current source.
  VideoPlayerController? _controller;

  /// Reactive [VideoPlayerController].
  ReactivePlayerController? _reactiveController;

  /// List of [_reactiveController] subscriptions.
  final List<StreamSubscription> _subscriptions = [];

  @override
  Future<void> setSource(AudioSource source) async {
    _resetState();
    await _disposeReactiveController();
    await _disposeController();

    _controller = _buildController(
      source,
      options: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: true,
      ),
    );

    _reactiveController = ReactivePlayerController(_controller!);
    _bindStreams();
    await _controller!.initialize();
    await _controller!.setLooping(false);
  }

  @override
  Future<void> play() async {
    await _controller?.play();
  }

  @override
  Future<void> pause() async {
    await _controller?.pause();
  }

  @override
  Future<void> stop() async {
    await _controller?.pause();
    _resetState();
    await _disposeReactiveController();
    await _disposeController();
  }

  @override
  Future<void> seek(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  Future<void> dispose() async {
    _resetState();
    await _disposeReactiveController();
    await _disposeController();
  }

  @override
  Future<Duration> extractDuration(AudioSource source) async {
    final controller = _buildController(source);
    try {
      await controller.initialize();
      return controller.value.duration;
    } finally {
      await controller.dispose();
    }
  }

  /// Subscribes to [_reactiveController] streams.
  void _bindStreams() {
    final reactive = _reactiveController;
    if (reactive == null) {
      return;
    }

    _subscriptions.addAll([
      _reactiveController!.isPlaying.listen((v) => isPlaying.value = v),
      _reactiveController!.isBuffering.listen((v) => isLoading.value = v),
      _reactiveController!.position.listen((v) => position.value = v),
      _reactiveController!.duration.listen((v) => duration.value = v),
      _reactiveController!.isCompleted.listen((v) => isCompleted.value = v),
    ]);
  }

  /// Disposes subscriptions and reactive wrapper.
  Future<void> _disposeReactiveController() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    _reactiveController?.dispose();
    _reactiveController = null;
  }

  /// Disposes the underlying [VideoPlayerController].
  Future<void> _disposeController() async {
    if (_controller == null) {
      return;
    }

    await _controller!.dispose();
    _controller = null;
  }

  /// Resets state to a neutral idle value.
  void _resetState() {
    isPlaying.value = false;
    isLoading.value = false;
    isCompleted.value = false;
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }

  /// Builds a [VideoPlayerController] for the provided [AudioSource].
  VideoPlayerController _buildController(
    AudioSource source, {
    VideoPlayerOptions? options,
  }) {
    return switch (source) {
      UrlAudioSource() => VideoPlayerController.networkUrl(
        Uri.parse(source.url),
        videoPlayerOptions: options,
      ),
      AssetAudioSource() => VideoPlayerController.asset(
        'assets/${source.asset}',
        videoPlayerOptions: options,
      ),
      FileAudioSource() => VideoPlayerController.networkUrl(
        Uri.file(source.file),
        videoPlayerOptions: options,
      ),
    };
  }
}
