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

import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:video_player/video_player.dart';

import '../page/player/controller.dart';
import '/domain/service/disposable_service.dart';
import '/util/audio_utils.dart';
import '/util/backoff.dart';
import '/util/log.dart';
import '/util/media_utils.dart';
import '/util/platform_utils.dart';

/// Worker responsible for audio playback.
class AudioWorker extends Dependency {
  AudioWorker();

  /// Unique identifier of the currently active audio, if any.
  final Rxn<AudioId> activeAudioId = Rxn<AudioId>();

  /// Whether the audio is currently playing.
  final RxBool isPlaying = RxBool(false);

  /// Whether the audio is currently loading or buffering.
  final RxBool isLoading = RxBool(false);

  /// Current playback position of the active audio.
  final Rx<Duration> position = Rx<Duration>(Duration.zero);

  /// Total duration of the active audio.
  final Rx<Duration> duration = Rx<Duration>(Duration.zero);

  /// Underlying audio player instance.
  final ja.AudioPlayer _player = ja.AudioPlayer();

  /// [VideoPlayerController] used for Apple URL audio playback.
  VideoPlayerController? _videoPlayer;

  /// Reactive [VideoPlayerController].
  ReactivePlayerController? _reactiveVideoController;

  /// Subscription to the audio intent (music mode).
  StreamSubscription? _audioIntentSubscription;

  /// [StreamSubscription] to [AudioUtilsImpl.routeChangeStream].
  StreamSubscription? _routeSubscription;

  /// List of [_player] subscriptions.
  final List<StreamSubscription> _subscriptions = [];

  /// [CancelToken] for cancelling the audio download.
  CancelToken? _cancelToken;

  /// [CancelToken] for cancelling the audio header fetching.
  CancelToken? _headerToken;

  /// Whether the [VideoPlayerController] should be used for audio playback.
  final bool _needsVideoPlayer =
      (PlatformUtils.isMacOS || PlatformUtils.isIOS) && !PlatformUtils.isWeb;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

    super.onInit();

    if (PlatformUtils.isIOS && !PlatformUtils.isWeb) {
      _initialize();
    }

    _subscriptions.addAll([
      _player.playerStateStream.listen((state) async {
        isPlaying.value = state.playing;
        isLoading.value =
            state.processingState == ja.ProcessingState.buffering ||
            state.processingState == ja.ProcessingState.loading;

        if (state.processingState == ja.ProcessingState.completed) {
          _onPlaybackCompleted();
        }
      }),
      _player.positionStream.distinct().listen((p) => position.value = p),
      _player.durationStream.listen((d) => duration.value = d ?? Duration.zero),
    ]);
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');
    _routeSubscription?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _player.dispose();

    _disposeVideoPlayer();
    _audioIntentSubscription?.cancel();
    _cancelToken?.cancel();
    _headerToken?.cancel();
    super.onClose();
  }

  /// Plays audio from the given [source] with the specified [id].
  ///
  /// If the audio with the same [id] is already active, it resumes playback.
  /// Otherwise, it sets the new [source] and starts playback.
  Future<void> play(
    AudioId id,
    AudioSource source, {
    FutureOr<AudioSource?> Function()? onForbidden,
  }) async {
    try {
      _audioIntentSubscription ??= AudioUtils.acquire(
        AudioMode.music,
        speaker: AudioSpeakerKind.speaker,
      ).listen((_) {});

      if (activeAudioId.value == id) {
        if (_needsVideoPlayer) {
          await _videoPlayer?.play();
        } else {
          await _player.play();
        }
      } else {
        await stop();
        activeAudioId.value = id;

        if (source is UrlAudioSource) {
          isLoading.value = true;

          try {
            final reachable = await _ensureReachable(
              source,
              onForbidden: onForbidden,
            );

            if (_needsVideoPlayer) {
              await _setVideoPlayerAudioSource(reachable);
              await _videoPlayer?.play();
              return;
            }

            await _player.setAudioSource(reachable.source);
          } on OperationCanceledException {
            return;
          } finally {
            isLoading.value = false;
          }
        } else {
          await _player.setAudioSource(source.source);
        }

        await _player.play();
      }
    } catch (e) {
      if (e is! OperationCanceledException) {
        Log.error('Failed to play audio: $e', '$runtimeType');
        await stop();
      }
    }
  }

  /// Pauses the current playback.
  Future<void> pause() async {
    if (_needsVideoPlayer) {
      await _videoPlayer?.pause();
    } else {
      await _player.pause();
    }
  }

  /// Stops the current playback, clears [activeAudioId], cancels
  /// [_audioIntentSubscription] and tokens.
  Future<void> stop() async {
    _cancelToken?.cancel();
    _headerToken?.cancel();
    _cancelToken = null;
    _headerToken = null;
    await _videoPlayer?.pause();
    await _disposeVideoPlayer();
    await _player.stop();
    activeAudioId.value = null;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    await _audioIntentSubscription?.cancel();
    _audioIntentSubscription = null;
  }

  /// Seeks to the specified [position] in the active audio.
  Future<void> seek(Duration position) async {
    if (_needsVideoPlayer) {
      await _videoPlayer?.pause();
      await _videoPlayer?.seekTo(position);
    } else {
      await _player.seek(position);
    }
  }

  /// Initializes the [_routeSubscription].
  Future<void> _initialize() async {
    _routeSubscription = AudioUtils.routeChangeStream.listen((e) async {
      Log.debug(
        'AudioUtils.routeChangeStream -> ${e.reason.name}',
        '$runtimeType',
      );

      switch (e.reason) {
        case AVAudioSessionRouteChangeReason.newDeviceAvailable:
        case AVAudioSessionRouteChangeReason.override:
        case AVAudioSessionRouteChangeReason.oldDeviceUnavailable:
        case AVAudioSessionRouteChangeReason.wakeFromSleep:
        case AVAudioSessionRouteChangeReason.noSuitableRouteForCategory:
          // No-op.
          break;

        case AVAudioSessionRouteChangeReason.categoryChange:
          // This may happen due to `media_kit` overriding the category, which
          // we shouldn't allow to happen.
          await AudioUtils.reconfigure(force: true);
          break;

        case AVAudioSessionRouteChangeReason.routeConfigurationChange:
        case AVAudioSessionRouteChangeReason.unknown:
          // No-op.
          break;
      }
    });
  }

  /// Called when the audio playback is completed.
  Future<void> _onPlaybackCompleted() async {
    await _player.seek(Duration.zero);
    await _player.pause();
  }

  /// Initializes [_videoPlayer] for the provided URL [source].
  Future<void> _setVideoPlayerAudioSource(UrlAudioSource source) async {
    await _videoPlayer?.pause();
    await _disposeVideoPlayer();

    _videoPlayer = VideoPlayerController.networkUrl(
      Uri.parse(source.url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: true,
      ),
    );

    _reactiveVideoController = ReactivePlayerController(_videoPlayer!);

    _subscriptions.addAll([
      _reactiveVideoController!.isPlaying.listen((v) => isPlaying.value = v),
      _reactiveVideoController!.isBuffering.listen((v) => isLoading.value = v),
      _reactiveVideoController!.position.listen((v) => position.value = v),
      _reactiveVideoController!.duration.listen((v) => duration.value = v),
      _reactiveVideoController!.isCompleted.listen((completed) {
        if (completed) _onPlaybackCompleted();
      }),
    ]);
    await _videoPlayer?.initialize();
    await _videoPlayer?.setLooping(false);
    await _videoPlayer?.setVolume(1);
  }

  /// Fetches the header of [source] to ensure that the URL is reachable.
  ///
  /// Tries refreshing the [source] once via [onForbidden] on `403` response.
  Future<UrlAudioSource> _ensureReachable(
    UrlAudioSource source, {
    FutureOr<AudioSource?> Function()? onForbidden,
  }) async {
    UrlAudioSource current = source;
    bool retriedAfterForbidden = false;

    while (true) {
      _headerToken?.cancel();
      _headerToken = CancelToken();

      try {
        await Backoff.run(
          () async {
            await (await PlatformUtils.dio).head(
              current.url,
              cancelToken: _headerToken,
            );
          },
          cancel: _headerToken,
          retryIf: (e) =>
              e is! DioException ||
              e.response?.statusCode != 403 && e.isNetworkRelated,
        );

        return current;
      } on DioException catch (e) {
        if (e.response?.statusCode == 403 && !retriedAfterForbidden) {
          _headerToken?.cancel();

          final AudioSource? refreshed = await onForbidden?.call();
          if (refreshed is UrlAudioSource) {
            current = refreshed;
            retriedAfterForbidden = true;
            continue;
          }
        }
        rethrow;
      }
    }
  }

  /// Disposes the currently assigned [_videoPlayer], if any.
  Future<void> _disposeVideoPlayer() async {
    _reactiveVideoController?.dispose();
    _reactiveVideoController = null;
    _videoPlayer?.dispose();
    _videoPlayer = null;
  }
}
