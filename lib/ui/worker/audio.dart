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

import '/domain/model/chat_item.dart';
import '/domain/service/disposable_service.dart';
import '/util/audio_utils.dart';
import '/util/backoff.dart';
import '/util/log.dart';
import '/util/media_utils.dart';
import '/util/platform_utils.dart';

/// Worker responsible for audio playback.
class AudioWorker extends Dependency {
  AudioWorker();

  /// Underlying audio player instance.
  final ja.AudioPlayer _player = ja.AudioPlayer();

  /// Subscription to the audio intent (music mode).
  StreamSubscription? _audioIntentSubscription;

  /// Unique identifier of the currently active audio, if any.
  final Rxn<ChatItemId> activeAudioId = Rxn<ChatItemId>();

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

  /// [CancelToken] for cancelling the audio header fetching.
  CancelToken? _headerToken;

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
    _headerToken?.cancel();
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

  /// Downloads [source] and sets it as a local file path in [_player].
  Future<void> _setDownloadedAudioSource(
    String id,
    UrlAudioSource source,
  ) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    await Backoff.run(
      () async {
        final response = await (await PlatformUtils.dio).get(
          source.url,
          options: Options(responseType: ResponseType.bytes),
          cancelToken: _cancelToken,
        );

        final dir = await PlatformUtils.temporaryDirectory;
        final filePath = '${dir.path}/audio_$id.mp3';
        // TODO: add caching
        //final exists = await File(filePath).exists();

        final file = File(filePath);
        await file.writeAsBytes(response.data);
        await _player.setFilePath(filePath);
      },
      cancel: _cancelToken,
      retryIf: (e) =>
          e is! DioException ||
          e.response?.statusCode != 403 && e.isNetworkRelated,
    );
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

  /// Plays audio from the given [source] with the specified [id].
  ///
  /// If the audio with the same [id] is already active, it resumes playback.
  /// Otherwise, it sets the new [source] and starts playback.
  Future<void> play(
    ChatItemId id,
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

        if (source is UrlAudioSource) {
          isLoading.value = true;

          try {
            final reachable = await _ensureReachable(
              source,
              onForbidden: onForbidden,
            );
            final needsLocalDownload =
                (PlatformUtils.isMacOS || PlatformUtils.isIOS) &&
                !PlatformUtils.isWeb;
            if (needsLocalDownload) {
              await _setDownloadedAudioSource(id.val, reachable);
            } else {
              await _player.setAudioSource(reachable.source);
            }
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

  /// Stops the current playback, clears [activeAudioId], cancels
  /// [_audioIntentSubscription] and tokens.
  Future<void> stop() async {
    _cancelToken?.cancel();
    _headerToken?.cancel();
    _cancelToken = null;
    _headerToken = null;
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
