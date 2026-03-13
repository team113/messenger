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
import '/util/audio_utils.dart';
import '/util/backoff.dart';
import '/util/log.dart';
import '/util/media_utils.dart' show AudioSpeakerKind;
import '/util/platform_utils.dart';
import 'audio/playback.dart';
import 'audio/playback/just_audio.dart';
import 'audio/playback/video_player.dart';

/// Worker responsible for audio playback.
class AudioWorker extends Dependency {
  AudioWorker();

  /// Unique identifier of the currently active audio, if any.
  final Rx<AudioId?> activeAudioId = Rx(null);

  /// [AudioPlayback] to play [AudioSource]s.
  final AudioPlayback _playback =
      (PlatformUtils.isMacOS || PlatformUtils.isIOS) && !PlatformUtils.isWeb
      ? VideoPlayerPlayback()
      : JustAudioPlayback();

  /// [StreamSubscription] to the audio intent in [AudioMode.music].
  StreamSubscription? _intentSubscription;

  /// [StreamSubscription] to [AudioUtilsImpl.routeChangeStream].
  StreamSubscription? _routeSubscription;

  /// [StreamSubscription] for playback completion.
  StreamSubscription? _completedSubscription;

  /// [CancelToken] for cancelling the audio download.
  CancelToken? _cancelToken;

  /// [CancelToken] for cancelling the audio header fetching.
  CancelToken? _headerToken;

  /// Returns the [AudioPlayback].
  AudioPlayback get playback => _playback;

  @override
  void onInit() {
    super.onInit();

    Log.debug('onInit()', '$runtimeType');

    if (PlatformUtils.isIOS && !PlatformUtils.isWeb) {
      _initialize();
    }

    _completedSubscription = _playback.isCompleted.listen((completed) async {
      if (completed) {
        await pause();
        await seek(Duration.zero);
      }
    });
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    _routeSubscription?.cancel();
    _completedSubscription?.cancel();
    _playback.dispose();
    _intentSubscription?.cancel();
    _cancelToken?.cancel();
    _headerToken?.cancel();

    super.onClose();
  }

  /// Plays audio from the given [source] with the specified [id].
  ///
  /// If the audio with the same [id] is already active, then resumes playback.
  ///
  /// Otherwise, sets the new [source] and starts a playback.
  Future<void> play(
    AudioId id,
    AudioSource source, {
    FutureOr<AudioSource?> Function()? onForbidden,
  }) async {
    Log.debug('play(id: $id, source: $source)', '$runtimeType');

    try {
      _intentSubscription ??= AudioUtils.acquire(
        AudioMode.music,
        speaker: AudioSpeakerKind.speaker,
      ).listen((_) {});

      if (activeAudioId.value == id) {
        return await _playback.play();
      }

      await stop();
      activeAudioId.value = id;
      _playback.isLoading.value = true;

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

      await _playback.prepare(targetSource);
      await _playback.play();
    } on OperationCanceledException {
      // No-op.
    } catch (e) {
      Log.error('play($id) failed with: $e', '$runtimeType');
      await stop();
    } finally {
      _playback.isLoading.value = false;
    }
  }

  /// Pauses the current playback.
  Future<void> pause() async => await _playback.pause();

  /// Stops the current playback, clears [activeAudioId], cancels
  /// [_intentSubscription] and tokens.
  Future<void> stop() async {
    Log.debug('stop()', '$runtimeType');

    _cancelToken?.cancel();
    _headerToken?.cancel();
    _cancelToken = null;
    _headerToken = null;
    await _playback.stop();
    activeAudioId.value = null;
    await _intentSubscription?.cancel();
    _intentSubscription = null;
  }

  /// Seeks to the specified [position] in the active audio.
  Future<void> seek(Duration position) async {
    await _playback.seek(position);
  }

  /// Returns the [Duration] of the provided [source].
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

      return await _playback.extractDuration(targetSource);
    } on OperationCanceledException {
      return Duration.zero;
    } catch (e) {
      Log.error('extractDuration() failed with: $e', '$runtimeType');
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
