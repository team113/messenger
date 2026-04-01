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

import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/domain/service/disposable_service.dart';
import '/util/audio_utils.dart';
import '/util/backoff.dart';
import '/util/log.dart';
import '/util/media_utils.dart' show AudioSpeakerKind;
import '/util/new_type.dart';
import '/util/platform_utils.dart';
import 'audio/active_playback.dart';
import 'audio/delegate.dart';
import 'audio/delegate/just_audio.dart';
import 'audio/delegate/video_player.dart';

/// Worker responsible for audio playback.
class AudioWorker extends Dependency {
  AudioWorker({AudioDelegate? delegate})
    : _delegate = delegate ?? _createDefaultDelegate();

  /// Currently active [AudioPlayback] being set.
  final Rx<AudioPlayback?> playback = Rx(null);

  /// [AudioDelegate] to play [AudioSource]s.
  final AudioDelegate _delegate;

  /// [StreamSubscription] to the audio intent in [AudioMode.music].
  StreamSubscription? _intentSubscription;

  /// [StreamSubscription] to [AudioUtilsImpl.routeChangeStream].
  StreamSubscription? _routeSubscription;

  /// [StreamSubscription] for handling playback completion.
  StreamSubscription? _completedSubscription;

  /// [CancelToken] for cancelling the audio download.
  CancelToken? _cancelToken;

  /// [CancelToken] for cancelling the audio header fetching.
  CancelToken? _headerToken;

  /// Current play request identifier.
  ///
  /// Used to implement a cancellation mechanism for concurrent [play] calls.
  int _playRequestId = 0;

  /// Cache of pre-extracted audio durations by [AudioId].
  final Map<AudioId, Duration> _durationCache = {};

  @override
  void onInit() {
    super.onInit();

    Log.debug('onInit()', '$runtimeType');

    if (PlatformUtils.isIOS && !PlatformUtils.isWeb) {
      _initialize();
    }
  }

  @override
  void onClose() async {
    Log.debug('onClose()', '$runtimeType');

    _routeSubscription?.cancel();
    await stop();

    super.onClose();
  }

  /// Resumes the current playback, if any.
  Future<void> resume() async {
    if (playback.value != null) {
      await _delegate.play();
    }
  }

  /// Plays the provided [item], creating a new [AudioPlayback].
  ///
  /// If [item] is already active, resumes playback instead.
  Future<void> play(
    AudioItem item, {
    Future<AudioSource?> Function()? onForbidden,
  }) async {
    Log.debug('play(id: ${item.id}, source: ${item.source})', '$runtimeType');

    final int playId = ++_playRequestId;
    try {
      _intentSubscription ??= AudioUtils.acquire(
        AudioMode.music,
        speaker: AudioSpeakerKind.speaker,
      ).listen((_) {});

      if (playback.value?.item.id == item.id) {
        return resume();
      }

      _clean();
      await _delegate.stop();

      if (_isStale(playId)) {
        return;
      }

      _delegate.isLoading.value = true;

      AudioSource target = item.source;

      final cachedDuration = _durationCache[item.id];
      if (cachedDuration != null && cachedDuration != Duration.zero) {
        _delegate.duration.value = cachedDuration;
      }

      playback.value = AudioPlayback(_delegate, item);

      if (item.source is UrlAudioSource) {
        _headerToken?.cancel();
        _headerToken = CancelToken();

        target = await _ensureReachable(
          item.source as UrlAudioSource,
          onForbidden: onForbidden,
          cancelToken: _headerToken,
        );
      }

      await _delegate.prepare(
        target,
        knownDuration: cachedDuration ?? Duration.zero,
      );

      if (_isStale(playId)) {
        return;
      }
      _setupCompletionHandler();

      await _delegate.play();
    } on OperationCanceledException {
      // No-op.
    } catch (e) {
      Log.error('play(${item.id}) failed with: $e', '$runtimeType');
      if (_playRequestId == playId) await stop();
    } finally {
      if (_playRequestId == playId) _delegate.isLoading.value = false;
    }
  }

  /// Pauses the current playback.
  Future<void> pause() async => await _delegate.pause();

  /// Stops the current playback, clears resources, cancels
  /// [_intentSubscription], [_completedSubscription].
  Future<void> stop() async {
    Log.debug('stop()', '$runtimeType');
    _playRequestId++;
    _clean();
    await _delegate.stop();

    await _completedSubscription?.cancel();
    _completedSubscription = null;
    await _intentSubscription?.cancel();
    _intentSubscription = null;
  }

  /// Returns a [Duration] of the provided [item].
  Future<Duration> extract(
    AudioItem item, {
    Future<AudioSource?> Function()? onForbidden,
  }) async {
    final AudioId audioId = item.id;
    final AudioSource source = item.source;

    if (_durationCache.containsKey(audioId)) {
      return _durationCache[audioId]!;
    }

    try {
      AudioSource target = source;

      if (source is UrlAudioSource) {
        target = await _ensureReachable(source, onForbidden: onForbidden);
      }

      Duration duration = await _delegate.extract(target);
      _durationCache[audioId] = duration;

      return duration;
    } on OperationCanceledException {
      return Duration.zero;
    } catch (e) {
      Log.error('extract() failed with: $e', '$runtimeType');
      return Duration.zero;
    }
  }

  /// Returns a platform-specific [AudioDelegate] implementation.
  static AudioDelegate _createDefaultDelegate() {
    return (PlatformUtils.isMacOS || PlatformUtils.isIOS) &&
            !PlatformUtils.isWeb
        ? VideoPlayerDelegate()
        : JustAudioDelegate();
  }

  /// Cancels pending tokens, clears [playback].
  void _clean() {
    _cancelToken?.cancel();
    _headerToken?.cancel();
    _cancelToken = null;
    _headerToken = null;
    playback.value = null;
  }

  /// Returns `true` if the given [requestId] no longer matches the current
  /// [_playRequestId].
  bool _isStale(int requestId) => requestId != _playRequestId;

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

  /// Wires up playback completion handling.
  void _setupCompletionHandler() {
    _completedSubscription = _delegate.isCompleted.listen((completed) async {
      if (completed) {
        await _delegate.pause();
        await _delegate.seek(Duration.zero);
      }
    });
  }

  /// Fetches the header of [source] to ensure that the URL is reachable.
  ///
  /// On a `403` response code calls [onForbidden] to obtain a refreshed
  /// [UrlAudioSource] and returns it.
  Future<UrlAudioSource> _ensureReachable(
    UrlAudioSource source, {
    Future<AudioSource?> Function()? onForbidden,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    UrlAudioSource result = source;
    try {
      await Backoff.run(
        () async {
          try {
            await (await PlatformUtils.dio).head(
              source.url,
              cancelToken: token,
            );
          } catch (e) {
            Log.debug(
              '_ensureReachable() -> fetching HEAD... ⛔️ failed with $e',
              '$runtimeType',
            );
            if (e is DioException && e.response?.statusCode == 403) {
              final refreshed = await onForbidden?.call();
              result = refreshed as UrlAudioSource;
            } else {
              rethrow;
            }
          }
        },
        cancel: token,
        retryIf: (e) => e is DioException && e.isNetworkRelated,
      );
    } on OperationCanceledException {
      Log.debug(
        '_ensureReachable(${source.url}) -> OperationCanceledException',
        '$runtimeType',
      );
    }

    return result;
  }
}

/// Unique identifier of an audio.
class AudioId extends NewType<String> {
  AudioId(super.value);

  /// Constructs an [AudioId] from the provided [ChatItemId] and [AttachmentId].
  AudioId.fromMessage(ChatItemId itemId, AttachmentId attachmentId)
    : super('${itemId}_$attachmentId');
}

/// Metadata describing an audio.
class AudioItem {
  const AudioItem({required this.id, required this.source, this.title});

  /// Unique [AudioId] of the audio.
  final AudioId id;

  /// [AudioSource] of the audio.
  final AudioSource source;

  /// Human-readable name of the audio, if any.
  final String? title;
}
