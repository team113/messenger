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

import '/domain/service/disposable_service.dart';
import '/util/audio_player.dart';
import '/util/audio_utils.dart';
import '/util/backoff.dart';
import '/util/log.dart';
import '/util/media_utils.dart' show AudioSpeakerKind;
import '/util/platform_utils.dart';

/// Worker responsible for audio playback.
class AudioWorker extends Dependency {
  AudioWorker();

  /// Unique identifier of the currently active audio, if any.
  final Rxn<AudioId> activeAudioId = Rxn<AudioId>();

  /// Whether the audio is currently playing.
  RxBool get isPlaying => _engine.isPlaying;

  /// Whether the audio is currently loading or buffering.
  RxBool get isLoading => _engine.isLoading;

  /// Current playback position of the active audio.
  Rx<Duration> get position => _engine.position;

  /// Total duration of the active audio.
  Rx<Duration> get duration => _engine.duration;

  /// Playback engine implementation.
  final AudioPlaybackEngine _engine =
      (PlatformUtils.isMacOS || PlatformUtils.isIOS) && !PlatformUtils.isWeb
      ? VideoPlayerPlaybackEngine()
      : JustAudioPlaybackEngine();

  /// Subscription to the audio intent (music mode).
  StreamSubscription? _audioIntentSubscription;

  /// [StreamSubscription] to [AudioUtilsImpl.routeChangeStream].
  StreamSubscription? _routeSubscription;

  /// Subscription to playback completion.
  StreamSubscription? _completedSubscription;

  /// [CancelToken] for cancelling the audio download.
  CancelToken? _cancelToken;

  /// [CancelToken] for cancelling the audio header fetching.
  CancelToken? _headerToken;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

    super.onInit();

    if (PlatformUtils.isIOS && !PlatformUtils.isWeb) {
      _initialize();
    }

    _completedSubscription = _engine.isCompleted.listen((completed) {
      if (completed) _onPlaybackCompleted();
    });
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');
    _routeSubscription?.cancel();
    _completedSubscription?.cancel();
    _engine.dispose();
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
        await _engine.play();
        return;
      }

      await stop();
      activeAudioId.value = id;
      isLoading.value = true;

      AudioSource targetSource = source;

      if (source is UrlAudioSource) {
        _headerToken?.cancel();
        _headerToken = CancelToken();
        final reachable = await _ensureReachable(
          source,
          onForbidden: onForbidden,
          cancelToken: _headerToken,
        );
        targetSource = reachable;
      }

      await _engine.setSource(targetSource);
      await _engine.play();
    } on OperationCanceledException {
      return;
    } catch (e) {
      Log.error('Failed to play audio: $e', '$runtimeType');
      await stop();
    } finally {
      isLoading.value = false;
    }
  }

  /// Pauses the current playback.
  Future<void> pause() async {
    await _engine.pause();
  }

  /// Stops the current playback, clears [activeAudioId], cancels
  /// [_audioIntentSubscription] and tokens.
  Future<void> stop() async {
    _cancelToken?.cancel();
    _headerToken?.cancel();
    _cancelToken = null;
    _headerToken = null;
    await _engine.stop();
    activeAudioId.value = null;
    await _audioIntentSubscription?.cancel();
    _audioIntentSubscription = null;
  }

  /// Seeks to the specified [position] in the active audio.
  Future<void> seek(Duration position) async {
    await _engine.seek(position);
  }

  /// Returns the duration of the provided [source].
  Future<Duration> extractDuration(
    AudioSource source, {
    FutureOr<AudioSource?> Function()? onForbidden,
  }) async {
    try {
      AudioSource targetSource = source;
      if (source is UrlAudioSource) {
        final reachable = await _ensureReachable(
          source,
          onForbidden: onForbidden,
        );
        targetSource = reachable;
      }
      return await _engine.extractDuration(targetSource);
    } on OperationCanceledException {
      return Duration.zero;
    } catch (e) {
      Log.error('Failed to get audio duration: $e', '$runtimeType');
      return Duration.zero;
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
    await pause();
    await seek(Duration.zero);
  }

  /// Fetches the header of [source] to ensure that the URL is reachable.
  ///
  /// Tries refreshing the [source] once via [onForbidden] on `403` response.
  Future<UrlAudioSource> _ensureReachable(
    UrlAudioSource source, {
    FutureOr<AudioSource?> Function()? onForbidden,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();

    Future<void> check(String url) async {
      await Backoff.run(
        () async => (await PlatformUtils.dio).head(url, cancelToken: token),
        cancel: token,
        retryIf: (e) =>
            e is! DioException ||
            (e.response?.statusCode != 403 && e.isNetworkRelated),
      );
    }

    try {
      await check(source.url);
      return source;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final refreshed = await onForbidden?.call();
        if (refreshed is UrlAudioSource) {
          await check(refreshed.url);
          return refreshed;
        }
      }
      rethrow;
    }
  }
}
