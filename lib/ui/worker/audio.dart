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
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '/domain/service/disposable_service.dart';
import '/util/audio_utils.dart';
import '/util/backoff.dart';
import '/util/log.dart';
import '/util/media_utils.dart';
import '/util/platform_utils.dart';

/// Worker responsible for [AudioUtils] related scoped functionality.
class AudioWorker extends Dependency {
  AudioWorker();

  /// Underlying audio player instance.
  final ja.AudioPlayer _player = ja.AudioPlayer();

  /// Subscription to the audio intent (music mode).
  StreamSubscription? _audioIntentSubscription;

  /// Unique identifier of the currently active audio, if any.
  final RxnString activeAudioId = RxnString();

  /// Whether the audio is currently playing.
  final RxBool isPlaying = RxBool(false);

  /// Whether the audio is currently loading or buffering.
  final RxBool isLoading = RxBool(false);

  /// Current playback position of the active audio.
  final Rx<Duration> position = Rx<Duration>(Duration.zero);

  /// Total duration of the active audio.
  final Rx<Duration> duration = Rx<Duration>(Duration.zero);

  /// [StreamSubscription] to [AudioUtilsImpl.routeChangeStream].
  StreamSubscription? _routeSubscription;

  /// List of [_player] subscriptions.
  final List<StreamSubscription> _subscriptions = [];

  /// [CancelToken] for cancelling the audio download.
  CancelToken? _cancelToken;

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
    _audioIntentSubscription?.cancel();
    _cancelToken?.cancel();
    super.onClose();
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
        case AVAudioSessionRouteChangeReason.routeConfigurationChange:
        case AVAudioSessionRouteChangeReason.unknown:
          // This may happen due to `media_kit` overriding the category, which
          // we shouldn't allow to happen.
          await AudioUtils.reconfigure(force: true);
          break;
      }
    });
  }

  /// Called when the audio playback is completed.
  Future<void> _onPlaybackCompleted() async {
    await _player.seek(Duration.zero);
    await _player.pause();
  }

  /// Ensures [source] is reachable and sets it as a local file path in
  /// [_player].
  ///
  /// Tries refreshing the [source] once via [onForbidden] on `403` response.
  Future<void> _setRemoteAudioSource(
    String id,
    UrlAudioSource source, {
    FutureOr<AudioSource?> Function()? onForbidden,
  }) async {
    UrlAudioSource current = source;
    bool retriedAfterForbidden = false;
    if (PlatformUtils.isWeb) return;
    while (true) {
      _cancelToken?.cancel();
      _cancelToken = CancelToken();

      try {
        await Backoff.run(
          () async {
            await _ensureReachable(current);

            final response = await (await PlatformUtils.dio).get(
              current.url,
              options: Options(responseType: ResponseType.bytes),
              cancelToken: _cancelToken,
            );

            final dir = await PlatformUtils.temporaryDirectory;
            final filePath = '${dir.path}/audio_$id.mp3';

            final file = File(filePath);
            await file.writeAsBytes(response.data);
            await _player.setFilePath(filePath);
          },
          cancel: _cancelToken,
          retryIf: (e) =>
              e is! DioException ||
              e.response?.statusCode != 403 && e.isNetworkRelated,
        );

        return;
      } on DioException catch (e) {
        if (e.response?.statusCode == 403 && !retriedAfterForbidden) {
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

  /// Fetches the header of [source] to ensure that it is reachable.
  Future<void> _ensureReachable(UrlAudioSource source) async {
    await (await PlatformUtils.dio).head(source.url, cancelToken: _cancelToken);
  }

  /// Plays audio from the given [source] with the specified [id].
  ///
  /// If the audio with the same [id] is already active, it resumes playback.
  /// Otherwise, it sets the new [source] and starts playback.
  Future<void> play(
    String id,
    AudioSource source, {
    FutureOr<AudioSource?> Function()? onForbidden,
  }) async {
    try {
      _audioIntentSubscription ??= AudioUtils.acquire(
        AudioMode.music,
        speaker: AudioSpeakerKind.speaker,
      ).listen((_) {});

      if (activeAudioId.value == id) {
        await _player.play();
      } else {
        await stop();
        activeAudioId.value = id;

        if (source is UrlAudioSource &&
            (PlatformUtils.isIOS || PlatformUtils.isMacOS) &&
            !PlatformUtils.isWeb) {
          isLoading.value = true;

          try {
            await _setRemoteAudioSource(id, source, onForbidden: onForbidden);
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
  Future<void> pause() => _player.pause();

  /// Stops the current playback and clears [activeAudioId].
  Future<void> stop() async {
    _cancelToken?.cancel();
    _cancelToken = null;
    await _player.stop();
    activeAudioId.value = null;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    await _audioIntentSubscription?.cancel();
    _audioIntentSubscription = null;
  }

  /// Seeks to the specified [position] in the active audio.
  Future<void> seek(Duration position) async => _player.seek(position);
}
