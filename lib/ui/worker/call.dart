// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:mutex/mutex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';
import 'package:vibration/vibration_presets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '/api/backend/schema.dart';
import '/domain/model/application_settings.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/my_user.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/session.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/session.dart';
import '/domain/repository/settings.dart';
import '/domain/service/auth.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/disposable_service.dart';
import '/domain/service/my_user.dart';
import '/domain/service/notification.dart';
import '/l10n/l10n.dart';
import '/provider/drift/callkit_calls.dart';
import '/provider/gql/graphql.dart';
import '/routes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/user/controller.dart';
import '/util/audio_utils.dart';
import '/util/log.dart';
import '/util/media_utils.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// Worker responsible for showing an incoming call notification and playing an
/// incoming or outgoing call audio.
class CallWorker extends Dependency {
  CallWorker(
    this._callService,
    this._chatService,
    this._myUserService,
    this._notificationService,
    this._authService,
    this._settingsRepository,
    this._graphQlProvider,
    this._callKitCalls,
    this._sessionRepository,
  );

  /// [CallService] used to get reactive changes of [OngoingCall]s.
  final CallService _callService;

  /// [ChatService] used to get the [Chat] an [OngoingCall] is happening in.
  final ChatService _chatService;

  /// [MyUserService] used to get [MyUser.muted] status.
  final MyUserService _myUserService;

  /// [NotificationService] used to show an incoming call notification.
  final NotificationService? _notificationService;

  /// [AuthService] for retrieving the current [Credentials] in
  /// [FlutterCallkitIncoming] events handling.
  final AuthService _authService;

  /// [AbstractSettingsRepository] used to retrieve
  /// [ApplicationSettings.muteKeys].
  final AbstractSettingsRepository _settingsRepository;

  /// [GraphQlProvider] required to access [ChatEvent]s directly.
  final GraphQlProvider _graphQlProvider;

  /// [CallKitCallsDriftProvider] to mark [FlutterCallkitIncoming] calls as
  /// accounted.
  final CallKitCallsDriftProvider _callKitCalls;

  /// [AbstractSessionRepository] to receive connection changes.
  final AbstractSessionRepository _sessionRepository;

  /// Subscription to [CallService.calls] map.
  late final StreamSubscription _subscription;

  /// Workers of [OngoingCall.state] responsible for stopping the
  /// [_incomingAudio] when corresponding [OngoingCall] becomes active.
  final Map<ChatId, Worker> _workers = {};

  /// Workers of [OngoingCall.audioState] toggling the
  /// [FlutterCallkitIncoming.muteCall] on iOS devices.
  final Map<ChatId, Worker> _audioWorkers = {};

  /// Subscription to [WebUtils.onStorageChange] [stop]ping the
  /// [_incomingAudio].
  StreamSubscription? _storageSubscription;

  /// [ChatId]s of the calls that should be answered right away.
  final List<ChatId> _answeredCalls = [];

  /// [Timer] used to [Vibration.vibrate] every 500 milliseconds.
  Timer? _vibrationTimer;

  /// [Worker] reacting on the [RouterState.lifecycle] changes.
  Worker? _lifecycleWorker;

  /// [StreamSubscription] for canceling the [_outgoing] sound playing.
  StreamSubscription? _outgoingAudio;

  /// [StreamSubscription] for canceling the [_incoming] sound playing.
  StreamSubscription? _incomingAudio;

  /// Subscription to the [PlatformUtilsImpl.onFocusChanged] updating the
  /// [_focused].
  StreamSubscription? _onFocusChanged;

  /// Indicator whether the application's window is in focus.
  bool _focused = true;

  /// [FlutterCallkitIncoming.onEvent] subscription reacting on the native call
  /// interface events.
  StreamSubscription? _callKitSubscription;

  /// [GraphQlProvider.chatEvents] subscriptions for each ongoing
  /// [FlutterCallkitIncoming] call to be notified about their endings.
  final Map<ChatId, StreamSubscription> _eventsSubscriptions = {};

  /// [HotKey] used for mute/unmute action of the [OngoingCall]s.
  HotKey? _hotKey;

  /// Indicator whether the [_hotKey] is already bind or not.
  bool _bind = false;

  /// Indicator whether all the [OngoingCall]s should be muted or not.
  final RxBool _muted = RxBool(false);

  /// [Worker] reacting on the [ApplicationSettings] changes to rebind the
  /// [_hotKey].
  Worker? _settingsWorker;

  /// [DateTime] when last [MediaUtilsImpl.ensureReconnected] was invoked.
  DateTime? _lastConnectedAt;

  /// [Mutex] guarding async access to [Vibration] related functions.
  final Mutex _vibrateMutex = Mutex();

  /// [Duration] between [FlutterCallkitIncoming]s displayed to be considered as
  /// a new call instead of already reported one.
  static const Duration _accountedTimeout = Duration(seconds: 15);

  /// [Duration] indicating the time after which the push notification should be
  /// considered as lost.
  static const Duration _pushTimeout = Duration(seconds: 10);

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get _myUser => _myUserService.myUser;

  /// Returns the name of an incoming call sound asset.
  String get _incoming =>
      PlatformUtils.isWeb ? 'incoming_call_web.mp3' : 'incoming_call.mp3';

  /// Returns the name of an outgoing call sound asset.
  String get _outgoing => 'outgoing_call.mp3';

  /// Returns the name of an end call sound asset.
  String get _endCall => 'end_call.wav';

  /// Indicator whether this device's [Locale] contains a China country code.
  bool get _isChina => Platform.localeName.contains('CN');

  // TODO: [FlutterCallkitIncoming] currently conflicts with `medea_jason`
  //       on Android devices making calls to do unexpected things when enabled.
  /// Indicates whether [FlutterCallkitIncoming] should be considered active.
  bool get _isCallKit =>
      !PlatformUtils.isWeb &&
      ((PlatformUtils.isIOS && !_isChina) /*|| PlatformUtils.isAndroid*/ );

  @override
  void onInit() {
    Log.debug('onInit', '$runtimeType');

    AudioUtils.ensureInitialized();

    if (!WebUtils.isPopup) {
      _initWebUtils();
    }

    List<String>? lastKeys = _settingsRepository
        .applicationSettings
        .value
        ?.muteKeys
        ?.toList();

    _settingsWorker = ever(_settingsRepository.applicationSettings, (
      ApplicationSettings? settings,
    ) {
      if (!const ListEquality().equals(settings?.muteKeys, lastKeys)) {
        lastKeys = settings?.muteKeys?.toList();

        final bool shouldBind = _bind;
        if (_bind) {
          _unbindHotKey();
        }

        _hotKey = settings?.muteHotKey ?? MuteHotKeyExtension.defaultHotKey;

        if (shouldBind) {
          _bindHotKey();
        }
      }
    });

    bool wakelock = _callService.calls.isNotEmpty;
    if (wakelock && !PlatformUtils.isLinux) {
      WakelockPlus.enable().onError((_, _) => false);
    }

    if (PlatformUtils.isAndroid && !PlatformUtils.isWeb) {
      _lifecycleWorker = ever(router.lifecycle, (e) async {
        if (e.inForeground) {
          if (_isCallKit) {
            try {
              await FlutterCallkitIncoming.endAllCalls();
            } catch (_) {
              // No-op.
            }
          }

          _callService.calls.forEach((id, call) {
            if (_answeredCalls.contains(id) && !call.value.isActive) {
              _callService.join(id, withVideo: false);
              _answeredCalls.remove(id);
            }
          });
        }
      });
    }

    Future<void> handle(ChatId key, OngoingCall c) async {
      Future.delayed(Duration.zero, () {
        // Ensure the call is displayed in the application before binding.
        if (!c.background && c.state.value != OngoingCallState.ended) {
          _bindHotKey();
        }
      });

      _workers.remove(key)?.dispose();
      _workers[key] = ever(c.state, (OngoingCallState state) async {
        final ChatItemId? callId = c.call.value?.id;

        switch (state) {
          case OngoingCallState.local:
          case OngoingCallState.pending:
            // No-op.
            break;

          case OngoingCallState.joining:
          case OngoingCallState.active:
            _workers.remove(key)?.dispose();
            if (_workers.isEmpty) {
              stop();
            }

            if (_isCallKit && callId != null) {
              await FlutterCallkitIncoming.setCallConnected(
                callId.val.base62ToUuid(),
              );

              final String base62 = callId.val.base62ToUuid();
              await _callKitCalls.upsert(base62, PreciseDateTime.now());
            }
            break;

          case OngoingCallState.ended:
            _workers.remove(key)?.dispose();
            if (_workers.isEmpty) {
              stop();
            }

            if (_isCallKit && callId != null) {
              await FlutterCallkitIncoming.endCall(callId.val.base62ToUuid());
            }
            break;
        }
      });

      if (c.state.value == OngoingCallState.pending ||
          c.state.value == OngoingCallState.local) {
        // Indicator whether it is us who are calling.
        final bool outgoing =
            (_callService.me == c.caller?.id ||
                c.state.value == OngoingCallState.local) &&
            c.conversationStartedAt == null;

        final SharedPreferences prefs = await SharedPreferences.getInstance();

        if (prefs.containsKey('answeredCall')) {
          _answeredCalls.add(ChatId(prefs.getString('answeredCall')!));
          prefs.remove('answeredCall');
        }

        final bool isInForeground = router.lifecycle.value.inForeground;
        if (isInForeground && _answeredCalls.contains(c.chatId.value)) {
          _callService.join(c.chatId.value, withVideo: false);
          _answeredCalls.remove(c.chatId.value);
        } else if (outgoing) {
          play(_outgoing);
        } else if (_workers.isNotEmpty &&
            (!PlatformUtils.isMobile || isInForeground)) {
          play(_incoming, fade: true);

          // Show a notification of an incoming call.
          if (!outgoing && !PlatformUtils.isMobile && !_focused) {
            final FutureOr<RxChat?> chat = _chatService.get(c.chatId.value);

            void showIncomingCallNotification(RxChat? chat) {
              // Displays a local notification via [NotificationService].
              void notify() {
                if (_myUser.value?.muted == null &&
                    chat?.chat.value.muted == null) {
                  final String? title = chat?.title() ?? c.caller?.title();

                  _notificationService?.show(
                    title ?? 'label_incoming_call'.l10n,
                    body: title == null ? null : 'label_incoming_call'.l10n,
                    payload: '${Routes.chats}/${c.chatId}',
                    icon: chat?.avatar.value?.original,
                    tag: '${c.chatId}_${c.call.value?.id}',
                  );
                }
              }

              // If FCM wasn't initialized, show a local notification
              // immediately.
              if (_notificationService?.pushNotifications != true) {
                notify();
              } else if (PlatformUtils.isWeb && PlatformUtils.isDesktop) {
                // [NotificationService] will not show the scheduled local
                // notification, if a push with the same tag was already
                // received.
                Future.delayed(_pushTimeout, notify);
              }
            }

            if (chat is RxChat?) {
              showIncomingCallNotification(chat);
            } else {
              chat.then(showIncomingCallNotification);
            }
          }
        }
      }

      if (_muted.value) {
        c.setAudioEnabled(!_muted.value);
      }

      if (_isCallKit) {
        _audioWorkers[key] = ever(c.audioState, (LocalTrackState state) async {
          final ChatItemId? callId = c.call.value?.id;

          if (callId != null) {
            await FlutterCallkitIncoming.muteCall(
              callId.val.base62ToUuid(),
              isMuted: !state.isEnabled,
            );
          }
        });
      }

      if (_isCallKit) {
        _eventsSubscriptions.remove(c.chatId.value)?.cancel();
        _resubscribeTo(c.chatId.value);

        final RxChat? chat = await _chatService.get(c.chatId.value);
        final String id = (c.call.value?.id.val ?? c.chatId.value.val)
            .base62ToUuid();

        bool report = true;

        final PreciseDateTime? accountedAt = await _callKitCalls.read(id);
        if (accountedAt != null) {
          report =
              accountedAt.val.difference(DateTime.now()).abs() >=
              _accountedTimeout;
        }

        if (report) {
          final CallKitParams params = CallKitParams(
            nameCaller: chat?.title() ?? 'Call',
            id: id,
            handle: c.chatId.value.val,
            extra: {'chatId': c.chatId.value.val},
          );

          switch (c.state.value) {
            case OngoingCallState.pending:
              Log.debug(
                'onInit() -> ${c.state.value.name} -> FlutterCallkitIncoming.showCallkitIncoming($id)',
                '$runtimeType',
              );

              await FlutterCallkitIncoming.showCallkitIncoming(params);
              break;

            case OngoingCallState.local:
            case OngoingCallState.joining:
            case OngoingCallState.active:
              Log.debug(
                'onInit() -> ${c.state.value.name} -> FlutterCallkitIncoming.startCall($id)',
                '$runtimeType',
              );

              await FlutterCallkitIncoming.startCall(params);
              await FlutterCallkitIncoming.setCallConnected(id);
              break;

            case OngoingCallState.ended:
              // No-op.
              break;
          }
        }
      }
    }

    if (!WebUtils.isPopup) {
      _subscription = _callService.calls.changes.listen((event) async {
        if (!wakelock && _callService.calls.isNotEmpty) {
          wakelock = true;
          WakelockPlus.enable().onError((_, _) => false);
        } else if (wakelock && _callService.calls.isEmpty) {
          wakelock = false;
          WakelockPlus.disable().onError((_, _) => false);
        }

        switch (event.op) {
          case OperationKind.added:
            if (event.key != null && event.value != null) {
              await handle(event.key!, event.value!.value);
            }
            break;

          case OperationKind.removed:
            _answeredCalls.remove(event.key);
            _audioWorkers.remove(event.key)?.dispose();
            _workers.remove(event.key)?.dispose();
            _eventsSubscriptions.remove(event.key)?.cancel();
            if (_workers.isEmpty) {
              stop();
            }

            // Play an [_endCall] sound, when an [OngoingCall] with [myUser] ends.
            final OngoingCall? call = event.value?.value;
            if (call != null) {
              final bool isActiveOrEnded =
                  call.state.value == OngoingCallState.active ||
                  call.state.value == OngoingCallState.ended;
              final bool withMe = call.members.containsKey(call.me.id);

              if (withMe && isActiveOrEnded && call.participated) {
                play(_endCall);
              }

              if (_isCallKit) {
                final ChatItemId? callId = call.call.value?.id;

                if (callId != null) {
                  final String base62 = callId.val.base62ToUuid();
                  _callKitCalls.upsert(base62, PreciseDateTime.now());
                  await FlutterCallkitIncoming.endCall(base62);
                }

                await FlutterCallkitIncoming.endCall(
                  call.chatId.value.val.base62ToUuid(),
                );
              }
            }

            // Set the default speaker, when all the [OngoingCall]s are ended.
            if (_callService.calls.isEmpty) {
              _unbindHotKey();

              try {
                await AudioUtils.setDefaultSpeaker();
              } on PlatformException {
                // No-op.
              }

              if (_isCallKit) {
                await FlutterCallkitIncoming.endAllCalls();
              }
            }
            break;

          default:
            break;
        }
      });

      for (Rx<OngoingCall> call in _callService.calls.values) {
        handle(call.value.chatId.value, call.value);
      }
    }

    if (_isCallKit) {
      _callKitSubscription = FlutterCallkitIncoming.onEvent.listen((
        CallEvent? event,
      ) async {
        Log.debug('FlutterCallkitIncoming.onEvent -> $event', '$runtimeType');

        switch (event!.event) {
          case Event.actionCallAccept:
            final String? chatId = event.body['extra']?['chatId'];
            if (chatId != null) {
              await _callService.join(ChatId(chatId));
            }
            break;

          case Event.actionCallDecline:
            final String? chatId = event.body['extra']?['chatId'];
            if (chatId != null) {
              _eventsSubscriptions.remove(ChatId(chatId))?.cancel();
              await _callService.decline(ChatId(chatId));
            }
            break;

          case Event.actionCallEnded:
          case Event.actionCallTimeout:
            final String? chatId = event.body['extra']?['chatId'];
            if (chatId != null) {
              _eventsSubscriptions.remove(ChatId(chatId))?.cancel();
              _callService.remove(ChatId(chatId));
            }
            break;

          case Event.actionCallToggleMute:
            final bool? isMuted = event.body['isMuted'] as bool?;
            if (isMuted != null) {
              for (var e in _callService.calls.entries) {
                e.value.value.setAudioEnabled(!isMuted);
              }
            }
            break;

          case Event.actionCallIncoming:
            final String? extra = event.body['extra']?['chatId'];
            final Credentials? credentials = _authService.credentials.value;

            if (extra != null && credentials != null) {
              final ChatId chatId = ChatId(extra);
              await _resubscribeTo(chatId);
            } else if (credentials == null) {
              // We don't have `credentials`, thus no calls should be allowed.
              await FlutterCallkitIncoming.endAllCalls();
            }
            break;

          case Event.actionDidUpdateDevicePushTokenVoip:
          case Event.actionCallStart:
          case Event.actionCallCallback:
          case Event.actionCallToggleHold:
          case Event.actionCallToggleDmtf:
          case Event.actionCallToggleGroup:
          case Event.actionCallToggleAudioSession:
          case Event.actionCallCustom:
          case Event.actionCallConnected:
            // No-op.
            break;
        }
      });

      // List the current active calls (e.g. if this app was launched as a
      // result of VoIP notification received) and subscribe to the events.
      FlutterCallkitIncoming.activeCalls().then((e) {
        Log.debug(
          'onInit() -> FlutterCallkitIncoming.activeCalls -> $e',
          '$runtimeType',
        );

        if (e is List) {
          for (var event in e) {
            Log.debug(
              'onInit() -> FlutterCallkitIncoming.activeCalls -> event -> ${event.runtimeType} -> ${event is Map}',
              '$runtimeType',
            );

            if (event is Map) {
              final String? chatId = event['extra']?['chatId'] as String?;
              if (chatId != null) {
                _resubscribeTo(ChatId(chatId));
              }
            }
          }
        }
      });
    }

    _hotKey =
        _settingsRepository.applicationSettings.value?.muteHotKey ??
        MuteHotKeyExtension.defaultHotKey;

    if (!WebUtils.isPopup) {
      _callKitCalls.clear();
    }

    final List<ConnectivityResult> previous = _sessionRepository.connectivity
        .toList();
    ever(_sessionRepository.connectivity, (connections) async {
      if (previous.isEmpty && connections.isNotEmpty) {
        return previous.addAll(connections.toList());
      }

      if (!const ListEquality().equals(previous, connections)) {
        Log.debug(
          '_sessionRepository.connectivity -> $previous != $connections',
          '$runtimeType',
        );

        previous.clear();
        previous.addAll(connections.toList());

        if (connections.every((e) => e != ConnectivityResult.none)) {
          final int seconds =
              _lastConnectedAt?.difference(DateTime.now()).abs().inSeconds ??
              10;

          if (_lastConnectedAt == null || seconds >= 5) {
            _lastConnectedAt = DateTime.now();

            for (var e in _callService.calls.values) {
              e.value.notify(ConnectionLostNotification());
            }

            await MediaUtils.ensureReconnected();

            for (var e in _callService.calls.values) {
              e.value.notify(ConnectionRestoredNotification());
            }
          }
        }
      }
    });

    super.onInit();
  }

  @override
  void onReady() {
    _onFocusChanged = PlatformUtils.onFocusChanged.listen((f) => _focused = f);
    super.onReady();
  }

  @override
  void onClose() {
    Log.debug('onClose', '$runtimeType');

    _outgoingAudio?.cancel();
    _incomingAudio?.cancel();
    _callKitSubscription?.cancel();

    _subscription.cancel();
    _storageSubscription?.cancel();
    _onFocusChanged?.cancel();
    _workers.forEach((_, value) => value.dispose());
    _audioWorkers.forEach((_, value) => value.dispose());
    _lifecycleWorker?.dispose();
    _settingsWorker?.dispose();

    if (_vibrationTimer != null) {
      _vibrationTimer?.cancel();
      Vibration.cancel();
    }

    _unbindHotKey();

    super.onClose();
  }

  /// Plays the given [asset].
  Future<void> play(String asset, {bool fade = false}) async {
    if (asset == _incoming) {
      if (_myUser.value?.muted == null) {
        final previous = _incomingAudio;
        _incomingAudio = AudioUtils.play(
          AudioSource.asset('audio/$asset'),
          fade: fade ? 1.seconds : Duration.zero,
        );
        previous?.cancel();
        _startVibrating();
      }
    } else if (asset == _outgoing) {
      final previous = _outgoingAudio;
      _outgoingAudio = AudioUtils.play(
        AudioSource.asset('audio/$asset'),
        fade: fade ? 1.seconds : Duration.zero,
      );
      previous?.cancel();
    } else if (asset == _endCall) {
      AudioUtils.once(AudioSource.asset('audio/$_endCall'));
    }
  }

  /// Stops the audio that is currently playing.
  Future<void> stop() async {
    if (_vibrationTimer != null) {
      _stopVibrating();
      _vibrationTimer?.cancel();
      Vibration.cancel();
    }

    _incomingAudio?.cancel();
    _outgoingAudio?.cancel();
  }

  /// Initializes [WebUtils] related functionality.
  void _initWebUtils() {
    _storageSubscription = WebUtils.onStorageChange.listen((e) {
      if (e.key == null) {
        stop();
      } else if (e.key?.startsWith('call_') == true) {
        final chatId = ChatId(e.key!.replaceAll('call_', ''));
        if (e.newValue == null) {
          _callService.remove(chatId);
          _audioWorkers.remove(chatId)?.dispose();
          _workers.remove(chatId)?.dispose();
          if (_workers.isEmpty) {
            stop();
          }

          // Play a sound when a call with [myUser] ends in a popup.
          if (e.oldValue != null) {
            final call = WebStoredCall.fromJson(json.decode(e.oldValue!));

            final bool isActiveOrEnded =
                call.state == OngoingCallState.active ||
                call.state == OngoingCallState.ended;
            final bool withMe =
                call.call?.members.any((m) => m.user.id == _myUser.value?.id) ??
                false;

            if (isActiveOrEnded && withMe) {
              play(_endCall);
            }
          }
        } else {
          final call = WebStoredCall.fromJson(json.decode(e.newValue!));
          if (call.state != OngoingCallState.local &&
              call.state != OngoingCallState.pending) {
            _workers.remove(chatId)?.dispose();
            if (_workers.isEmpty) {
              stop();
            }
          }
        }
      }
    });
  }

  /// Binds to the [_hotKey] via [WebUtils.bindKey] to [_toggleMuteOnKey].
  Future<void> _bindHotKey() async {
    Log.debug(
      '_bindHotKey() -> ${_hotKey?.modifiers} + ${_hotKey?.physicalKey.usbHidUsage}',
      '$runtimeType',
    );

    if (!_bind && _hotKey != null) {
      _bind = true;

      try {
        await WebUtils.bindKey(_hotKey!, _toggleMuteOnKey);
      } catch (e) {
        Log.warning('Unable to bind hot key: $e', '$runtimeType');
      }
    }
  }

  /// Unbinds the [_toggleMuteOnKey] from [_hotKey] via [WebUtils.unbindKey].
  void _unbindHotKey() {
    Log.debug('_unbindHotKey()', '$runtimeType');

    if (_bind) {
      _bind = false;
      _muted.value = false;

      if (_hotKey != null) {
        WebUtils.unbindKey(_hotKey!, _toggleMuteOnKey);
      }
    }
  }

  /// Toggles the [_muted] and invokes appropriate [OngoingCall.setAudioEnabled]
  /// while playing an audio indicating the current [_muted] status.
  bool _toggleMuteOnKey() {
    bool muted = _muted.value;

    final List<bool> states = _callService.calls.values
        .where((e) => !e.value.background)
        .map((e) => e.value.audioState.value.isEnabled)
        .toList();

    if (states.isNotEmpty) {
      muted = states.where((e) => e).length <= states.where((e) => !e).length;
    }

    _muted.value = !muted;

    AudioUtils.once(
      AudioSource.asset(
        _muted.value ? 'audio/note_muted.ogg' : 'audio/note_unmuted.ogg',
      ),
    );

    for (var e in _callService.calls.values) {
      e.value.setAudioEnabled(!_muted.value);
    }

    return true;
  }

  /// Subscribes to the [GraphQlProvider.chatEvents] of the provided [chatId]
  /// to listen to events when [FlutterCallkitIncoming.endCall] should be
  /// invoked.
  Future<void> _resubscribeTo(ChatId chatId) async {
    Log.debug(
      '_resubscribeTo($chatId) -> _isCallKit($_isCallKit), existing(${_eventsSubscriptions[chatId]})',
      '$runtimeType',
    );

    if (!_isCallKit) {
      return;
    }

    final Credentials? credentials = _authService.credentials.value;
    if (credentials == null) {
      return;
    }

    if (_eventsSubscriptions[chatId] != null) {
      return;
    }

    _eventsSubscriptions[chatId]?.cancel();
    _eventsSubscriptions[chatId] = _graphQlProvider
        .chatEvents(chatId, null, () => null)
        .listen((e) async {
          Log.debug('_eventsSubscriptions[$chatId] -> $e', '$runtimeType');

          final events = ChatEvents$Subscription.fromJson(e.data!).chatEvents;

          if (events.$$typename == 'Chat') {
            final mixin = events as ChatEvents$Subscription$ChatEvents$Chat;
            final call = mixin.ongoingCall;

            if (call != null) {
              if (call.members.any((e) => e.user.id == credentials.userId)) {
                _eventsSubscriptions.remove(chatId)?.cancel();
                await FlutterCallkitIncoming.endCall(chatId.val.base62ToUuid());
              }
            } else {
              _eventsSubscriptions.remove(chatId)?.cancel();
              await FlutterCallkitIncoming.endCall(chatId.val.base62ToUuid());
            }
          } else if (events.$$typename == 'ChatEventsVersioned') {
            var mixin =
                events
                    as ChatEvents$Subscription$ChatEvents$ChatEventsVersioned;

            for (var e in mixin.events) {
              if (e.$$typename == 'EventChatCallFinished') {
                final node =
                    e as ChatEventsVersionedMixin$Events$EventChatCallFinished;

                _eventsSubscriptions.remove(chatId)?.cancel();
                await FlutterCallkitIncoming.endCall(
                  node.call.id.val.base62ToUuid(),
                );
              } else if (e.$$typename == 'EventChatCallMemberJoined') {
                final node =
                    e as ChatEventsVersionedMixin$Events$EventChatCallMemberJoined;
                final call = _callService.calls[chatId];

                if (node.user.id == credentials.userId &&
                    call?.value.connected != true) {
                  _eventsSubscriptions.remove(chatId)?.cancel();
                  await FlutterCallkitIncoming.endCall(
                    node.call.id.val.base62ToUuid(),
                  );
                }
              } else if (e.$$typename == 'EventChatCallMemberLeft') {
                var node =
                    e as ChatEventsVersionedMixin$Events$EventChatCallMemberLeft;
                final call = _callService.calls[chatId];

                if (node.user.id == credentials.userId &&
                    call?.value.connected != true) {
                  _eventsSubscriptions.remove(chatId)?.cancel();
                  await FlutterCallkitIncoming.endCall(
                    chatId.val.base62ToUuid(),
                  );
                }
              } else if (e.$$typename == 'EventChatCallDeclined') {
                final node =
                    e as ChatEventsVersionedMixin$Events$EventChatCallDeclined;
                if (node.user.id == credentials.userId) {
                  _eventsSubscriptions.remove(chatId)?.cancel();
                  await FlutterCallkitIncoming.endCall(
                    node.call.id.val.base62ToUuid(),
                  );
                }
              } else if (e.$$typename == 'EventChatCallAnswerTimeoutPassed') {
                final node =
                    e
                        as ChatEventsVersionedMixin$Events$EventChatCallAnswerTimeoutPassed;
                if (node.userId == credentials.userId) {
                  _eventsSubscriptions.remove(chatId)?.cancel();
                  await FlutterCallkitIncoming.endCall(
                    node.callId.val.base62ToUuid(),
                  );
                }
              }
            }
          }
        });

    // Ensure that we haven't already joined the call.
    final query = await _graphQlProvider.getChat(chatId);
    Log.debug('_resubscribeTo($chatId) -> query is $query', '$runtimeType');

    final call = query.chat?.ongoingCall;
    if (call != null) {
      if (call.members.any((e) => e.user.id == credentials.userId)) {
        Log.debug(
          '_resubscribeTo($chatId) -> endCall(${chatId.val.base62ToUuid()}) cuz `call.members` already contains our `${credentials.userId}`',
          '$runtimeType',
        );

        _eventsSubscriptions.remove(chatId)?.cancel();
        await FlutterCallkitIncoming.endCall(chatId.val.base62ToUuid());
      }
    } else {
      Log.debug(
        '_resubscribeTo($chatId) -> endCall(${chatId.val.base62ToUuid()}) cuz `Chat.ongoingCall` is `null`',
        '$runtimeType',
      );

      _eventsSubscriptions.remove(chatId)?.cancel();
      await FlutterCallkitIncoming.endCall(chatId.val.base62ToUuid());
    }
  }

  /// Starts [Vibration.vibrate].
  Future<void> _startVibrating() async {
    await _vibrateMutex.protect(() async {
      _vibrationTimer?.cancel();

      try {
        await Vibration.cancel();

        _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1400), (
          timer,
        ) {
          Vibration.vibrate(
            preset: VibrationPreset.rhythmicBuzz,
          ).onError((_, _) => false);
        });

        Vibration.vibrate(
          preset: VibrationPreset.rhythmicBuzz,
        ).onError((_, _) => false);
      } catch (_) {
        // No-op.
      }
    });
  }

  /// Stops [Vibration.vibrate].
  Future<void> _stopVibrating() async {
    await _vibrateMutex.protect(() async {
      _vibrationTimer?.cancel();

      try {
        await Vibration.cancel();
      } catch (_) {
        // No-op.
      }
    });
  }
}

/// Extension adding ability for [String] to be converted from base62-encoded
/// to [Uuid].
extension Base62ToUuid on String {
  /// Decodes this base62-encoded [String] to a UUID.
  String base62ToUuid() {
    // Define the Base62 character set.
    final chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

    // First of all, convert this [String] into a [BigInt].
    BigInt decoded = BigInt.zero;

    for (int i = 0; i < length; i++) {
      // Find the numeric value of the character in the Base62 character set.
      final int value = chars.indexOf(this[i]);

      if (value == -1) {
        throw FormatException('Invalid Base62 character: ${this[i]}');
      }

      decoded = decoded * BigInt.from(62) + BigInt.from(value);
    }

    // Create a list of 16 bytes (128 bits) to store the UUID.
    final bytes = Uint8List(16);

    for (int i = 15; i >= 0; i--) {
      bytes[i] = (decoded & BigInt.from(0xff)).toInt();
      decoded = decoded >> 8;
    }

    // Returns the hexadecimal string of the provided part from [bytes].
    String toHex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${toHex(0, 4)}-${toHex(4, 6)}-${toHex(6, 8)}-${toHex(8, 10)}-${toHex(10, 16)}';
  }
}

/// Extension adding muting [HotKey] related getters to [ApplicationSettings].
extension MuteHotKeyExtension on ApplicationSettings {
  /// Returns the [HotKey] intended to be used as a default mute/unmute one.
  static HotKey get defaultHotKey => HotKey(
    key: PhysicalKeyboardKey.keyM,
    modifiers: [HotKeyModifier.alt],
    scope: HotKeyScope.system,
  );

  /// Constructs a [HotKey] for mute/unmute from these [ApplicationSettings].
  HotKey get muteHotKey {
    final List<String> keys = muteKeys ?? [];

    final List<HotKeyModifier> modifiers = [];
    final List<PhysicalKeyboardKey> physicalKeys = [];

    for (var e in keys) {
      final modifier = HotKeyModifier.values.firstWhereOrNull(
        (m) => m.name == e,
      );

      if (modifier != null) {
        modifiers.add(modifier);
      } else {
        final int? hid = int.tryParse(e);
        if (hid != null) {
          physicalKeys.add(PhysicalKeyboardKey(hid));
        }
      }
    }

    if (keys.where((e) => e.isNotEmpty).isEmpty) {
      modifiers.addAll(defaultHotKey.modifiers ?? []);
    }

    return HotKey(
      key: physicalKeys.lastOrNull ?? defaultHotKey.physicalKey,
      modifiers: modifiers,
      scope: HotKeyScope.system,
    );
  }
}

/// Extension adding map of visual Unicode [String] representation of the
/// [PhysicalKeyboardKey].
extension KeyboardKeyToStringExtension on PhysicalKeyboardKey {
  /// [Map] matching [PhysicalKeyboardKey] with a visual [String]
  /// representation.
  static final Map<PhysicalKeyboardKey, String> labels =
      <PhysicalKeyboardKey, String>{
        PhysicalKeyboardKey.keyA: 'A',
        PhysicalKeyboardKey.keyB: 'B',
        PhysicalKeyboardKey.keyC: 'C',
        PhysicalKeyboardKey.keyD: 'D',
        PhysicalKeyboardKey.keyE: 'E',
        PhysicalKeyboardKey.keyF: 'F',
        PhysicalKeyboardKey.keyG: 'G',
        PhysicalKeyboardKey.keyH: 'H',
        PhysicalKeyboardKey.keyI: 'I',
        PhysicalKeyboardKey.keyJ: 'J',
        PhysicalKeyboardKey.keyK: 'K',
        PhysicalKeyboardKey.keyL: 'L',
        PhysicalKeyboardKey.keyM: 'M',
        PhysicalKeyboardKey.keyN: 'N',
        PhysicalKeyboardKey.keyO: 'O',
        PhysicalKeyboardKey.keyP: 'P',
        PhysicalKeyboardKey.keyQ: 'Q',
        PhysicalKeyboardKey.keyR: 'R',
        PhysicalKeyboardKey.keyS: 'S',
        PhysicalKeyboardKey.keyT: 'T',
        PhysicalKeyboardKey.keyU: 'U',
        PhysicalKeyboardKey.keyV: 'V',
        PhysicalKeyboardKey.keyW: 'W',
        PhysicalKeyboardKey.keyX: 'X',
        PhysicalKeyboardKey.keyY: 'Y',
        PhysicalKeyboardKey.keyZ: 'Z',
        PhysicalKeyboardKey.digit1: '1',
        PhysicalKeyboardKey.digit2: '2',
        PhysicalKeyboardKey.digit3: '3',
        PhysicalKeyboardKey.digit4: '4',
        PhysicalKeyboardKey.digit5: '5',
        PhysicalKeyboardKey.digit6: '6',
        PhysicalKeyboardKey.digit7: '7',
        PhysicalKeyboardKey.digit8: '8',
        PhysicalKeyboardKey.digit9: '9',
        PhysicalKeyboardKey.digit0: '0',
        PhysicalKeyboardKey.enter: '↩︎',
        PhysicalKeyboardKey.escape: '⎋',
        PhysicalKeyboardKey.backspace: '←',
        PhysicalKeyboardKey.tab: '⇥',
        PhysicalKeyboardKey.space: '␣',
        PhysicalKeyboardKey.minus: '-',
        PhysicalKeyboardKey.equal: '=',
        PhysicalKeyboardKey.bracketLeft: '[',
        PhysicalKeyboardKey.bracketRight: ']',
        PhysicalKeyboardKey.backslash: '\\',
        PhysicalKeyboardKey.semicolon: ';',
        PhysicalKeyboardKey.quote: '"',
        PhysicalKeyboardKey.backquote: '`',
        PhysicalKeyboardKey.comma: ',',
        PhysicalKeyboardKey.period: '.',
        PhysicalKeyboardKey.slash: '/',
        PhysicalKeyboardKey.capsLock: '⇪',
        PhysicalKeyboardKey.f1: 'F1',
        PhysicalKeyboardKey.f2: 'F2',
        PhysicalKeyboardKey.f3: 'F3',
        PhysicalKeyboardKey.f4: 'F4',
        PhysicalKeyboardKey.f5: 'F5',
        PhysicalKeyboardKey.f6: 'F6',
        PhysicalKeyboardKey.f7: 'F7',
        PhysicalKeyboardKey.f8: 'F8',
        PhysicalKeyboardKey.f9: 'F9',
        PhysicalKeyboardKey.f10: 'F10',
        PhysicalKeyboardKey.f11: 'F11',
        PhysicalKeyboardKey.f12: 'F12',
        PhysicalKeyboardKey.home: '↖',
        PhysicalKeyboardKey.pageUp: '⇞',
        PhysicalKeyboardKey.delete: '⌫',
        PhysicalKeyboardKey.end: '↘',
        PhysicalKeyboardKey.pageDown: '⇟',
        PhysicalKeyboardKey.arrowRight: '→',
        PhysicalKeyboardKey.arrowLeft: '←',
        PhysicalKeyboardKey.arrowDown: '↓',
        PhysicalKeyboardKey.arrowUp: '↑',
        PhysicalKeyboardKey.controlLeft: '⌃',
        PhysicalKeyboardKey.shiftLeft: '⇧',
        PhysicalKeyboardKey.altLeft: PlatformUtils.isMacOS ? '⌥' : 'Alt',
        PhysicalKeyboardKey.metaLeft: PlatformUtils.isMacOS ? '⌘' : '⊞',
        PhysicalKeyboardKey.controlRight: '⌃',
        PhysicalKeyboardKey.shiftRight: '⇧',
        PhysicalKeyboardKey.altRight: PlatformUtils.isMacOS ? '⌥' : 'Alt',
        PhysicalKeyboardKey.metaRight: PlatformUtils.isMacOS ? '⌘' : '⊞',
        PhysicalKeyboardKey.fn: 'fn',
      };
}
