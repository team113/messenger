// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '/domain/model/chat.dart';
import '/domain/model/my_user.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/repository/chat.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/disposable_service.dart';
import '/domain/service/my_user.dart';
import '/domain/service/notification.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/util/audio_utils.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// Worker responsible for showing an incoming call notification and playing an
/// incoming or outgoing call audio.
class CallWorker extends DisposableService {
  CallWorker(
    this._callService,
    this._chatService,
    this._myUserService,
    this._notificationService,
  );

  /// [CallService] used to get reactive changes of [OngoingCall]s.
  final CallService _callService;

  /// [ChatService] used to get the [Chat] an [OngoingCall] is happening in.
  final ChatService _chatService;

  /// [MyUserService] used to get [MyUser.muted] status.
  final MyUserService _myUserService;

  /// [NotificationService] used to show an incoming call notification.
  final NotificationService _notificationService;

  /// Subscription to [CallService.calls] map.
  late final StreamSubscription _subscription;

  /// Workers of [OngoingCall.state] responsible for stopping the [_audioPlayer]
  /// when corresponding [OngoingCall] becomes active.
  final Map<ChatId, Worker> _workers = {};

  /// Subscription to [WebUtils.onStorageChange] [stop]ping the [_audioPlayer].
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

  @override
  void onInit() {
    AudioUtils.ensureInitialized();
    _initWebUtils();

    bool wakelock = _callService.calls.isNotEmpty;
    if (wakelock && !PlatformUtils.isLinux) {
      WakelockPlus.enable().onError((_, __) => false);
    }

    if (PlatformUtils.isAndroid && !PlatformUtils.isWeb) {
      _lifecycleWorker = ever(router.lifecycle, (e) async {
        if (e.inForeground) {
          await FlutterCallkitIncoming.endAllCalls();

          _callService.calls.forEach((id, call) {
            if (_answeredCalls.contains(id) && !call.value.isActive) {
              _callService.join(id, withVideo: false);
              _answeredCalls.remove(id);
            }
          });
        }
      });
    }

    _subscription = _callService.calls.changes.listen((event) async {
      if (!wakelock && _callService.calls.isNotEmpty) {
        wakelock = true;
        WakelockPlus.enable().onError((_, __) => false);
      } else if (wakelock && _callService.calls.isEmpty) {
        wakelock = false;
        WakelockPlus.disable().onError((_, __) => false);
      }

      switch (event.op) {
        case OperationKind.added:
          final OngoingCall c = event.value!.value;

          if (c.state.value == OngoingCallState.pending ||
              c.state.value == OngoingCallState.local) {
            // Indicator whether it is us who are calling.
            final bool outgoing = (_callService.me == c.caller?.id ||
                    c.state.value == OngoingCallState.local) &&
                c.conversationStartedAt == null;

            final SharedPreferences prefs =
                await SharedPreferences.getInstance();

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
            } else if (!PlatformUtils.isMobile || isInForeground) {
              play(_incoming, fade: true);
              Vibration.hasVibrator().then((bool? v) {
                _vibrationTimer?.cancel();

                if (v == true) {
                  Vibration.vibrate(pattern: [500, 1000])
                      .onError((_, __) => false);
                  _vibrationTimer = Timer.periodic(
                    const Duration(milliseconds: 1500),
                    (timer) {
                      Vibration.vibrate(pattern: [500, 1000], repeat: 0)
                          .onError((_, __) => false);
                    },
                  );
                }
              }).catchError((_, __) {
                // No-op.
              });

              // Show a notification of an incoming call.
              if (!outgoing && !PlatformUtils.isMobile && !_focused) {
                final FutureOr<RxChat?> chat = _chatService.get(c.chatId.value);

                void showIncomingCallNotification(RxChat? chat) {
                  // Displays a local notification via [NotificationService].
                  void notify() {
                    if (_myUser.value?.muted == null &&
                        chat?.chat.value.muted == null) {
                      final String? title = chat?.title ?? c.caller?.title;

                      _notificationService.show(
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
                  if (!_notificationService.pushNotifications) {
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

            _workers[event.key!] = ever(c.state, (OngoingCallState state) {
              if (state != OngoingCallState.pending &&
                  state != OngoingCallState.local) {
                _workers.remove(event.key!)?.dispose();
                if (_workers.isEmpty) {
                  stop();
                }
              }
            });
          }
          break;

        case OperationKind.removed:
          _answeredCalls.remove(event.key);
          _workers.remove(event.key)?.dispose();
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
          }

          // Set the default speaker, when all the [OngoingCall]s are ended.
          if (_callService.calls.isEmpty) {
            await AudioUtils.setDefaultSpeaker();
          }
          break;

        default:
          break;
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
    _outgoingAudio?.cancel();
    _incomingAudio?.cancel();

    _subscription.cancel();
    _storageSubscription?.cancel();
    _onFocusChanged?.cancel();
    _workers.forEach((_, value) => value.dispose());
    _lifecycleWorker?.dispose();

    if (_vibrationTimer != null) {
      _vibrationTimer?.cancel();
      Vibration.cancel();
    }

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
          _workers.remove(chatId)?.dispose();
          if (_workers.isEmpty) {
            stop();
          }

          // Play a sound when a call with [myUser] ends in a popup.
          // if (e.oldValue != null) {
          //   final call = WebStoredCall.fromJson(json.decode(e.oldValue!));

          //   final bool isActiveOrEnded =
          //       call.state == OngoingCallState.active ||
          //           call.state == OngoingCallState.ended;
          //   final bool withMe =
          //       call.call?.members.any((m) => m.user.id == _myUser.value?.id) ??
          //           false;

          //   if (isActiveOrEnded && withMe) {
          //     play(_endCall);
          //   }
          // }
        } else {
          // final call = WebStoredCall.fromJson(json.decode(e.newValue!));
          // if (call.state != OngoingCallState.local &&
          //     call.state != OngoingCallState.pending) {
          //   _workers.remove(chatId)?.dispose();
          //   if (_workers.isEmpty) {
          //     stop();
          //   }
          // }
        }
      }
    });
  }
}
