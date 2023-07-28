// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'dart:convert';

import 'package:callkeep/callkeep.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock/wakelock.dart';

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
import '/util/android_utils.dart';
import '/util/audio_utils.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'background/background.dart';

/// Worker responsible for showing an incoming call notification and playing an
/// incoming or outgoing call audio.
class CallWorker extends DisposableService {
  CallWorker(
    this._background,
    this._callService,
    this._chatService,
    this._myUserService,
    this._notificationService,
  );

  /// [BackgroundWorker] used to get data from its service.
  final BackgroundWorker _background;

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

  /// [FlutterCallkeep] used to require the call account permissions.
  final FlutterCallkeep _callKeep = FlutterCallkeep();

  /// [ChatId]s of the calls that should be answered right away.
  final List<ChatId> _answeredCalls = [];

  /// [Timer] used to [Vibration.vibrate] every 500 milliseconds.
  Timer? _vibrationTimer;

  /// [StreamSubscription] to the data coming from the [_background] service.
  StreamSubscription? _onDataReceived;

  /// [StreamSubscription] for canceling the [_outgoing] sound playing.
  StreamSubscription? _outgoingAudio;

  /// [StreamSubscription] for canceling the [_incoming] sound playing.
  StreamSubscription? _incomingAudio;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get _myUser => _myUserService.myUser;

  /// Returns the name of an incoming call sound asset.
  String get _incoming =>
      PlatformUtils.isWeb ? 'chinese-web.mp3' : 'chinese.mp3';

  /// Returns the name of an outgoing call sound asset.
  String get _outgoing => 'ringing.mp3';

  @override
  void onInit() {
    AudioUtils.ensureInitialized();
    _initBackgroundService();
    _initWebUtils();

    bool wakelock = _callService.calls.isNotEmpty;
    if (wakelock && !PlatformUtils.isLinux) {
      Wakelock.enable().onError((_, __) => false);
    }

    _subscription = _callService.calls.changes.listen((event) async {
      // TODO: Wait for Linux `wakelock` implementation to be done and merged:
      //       https://github.com/creativecreatorormaybenot/wakelock/pull/186
      if (!PlatformUtils.isLinux) {
        if (!wakelock && _callService.calls.isNotEmpty) {
          wakelock = true;
          Wakelock.enable().onError((_, __) => false);
        } else if (wakelock && _callService.calls.isEmpty) {
          wakelock = false;
          Wakelock.disable().onError((_, __) => false);
        }
      }

      switch (event.op) {
        case OperationKind.added:
          OngoingCall c = event.value!.value;

          // Play a sound of an incoming or outgoing call.
          bool calling = (_callService.me == c.caller?.id ||
                  c.state.value == OngoingCallState.local) &&
              c.conversationStartedAt == null;
          if (c.state.value == OngoingCallState.pending ||
              c.state.value == OngoingCallState.local) {
            bool isInForeground = router.lifecycle.value.inForeground;

            if (_answeredCalls.contains(c.chatId.value)) {
              _callService.join(c.chatId.value, withVideo: false);
              _answeredCalls.remove(c.chatId.value);
            } else if (calling) {
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

            // Show a notification of an incoming call.
            if (!calling) {
              // On mobile, notification should be displayed only if application
              // is not in the foreground and the call permissions are not
              // granted.
              bool showNotification = !PlatformUtils.isMobile;
              if (PlatformUtils.isMobile) {
                showNotification =
                    !isInForeground && !(await _callKeep.hasPhoneAccount());
              }

              if (showNotification && _myUser.value?.muted == null) {
                _chatService.get(c.chatId.value).then((RxChat? chat) {
                  if (chat?.chat.value.muted == null) {
                    String? title = chat?.title.value ??
                        c.caller?.name?.val ??
                        c.caller?.num.val;

                    _notificationService.show(
                      title ?? 'label_incoming_call'.l10n,
                      body: title == null ? null : 'label_incoming_call'.l10n,
                      payload: '${Routes.chats}/${c.chatId}',
                      icon: chat?.avatar.value?.original.url,
                      playSound: false,
                    );
                  }
                });
              }
            }
          }

          break;

        case OperationKind.removed:
          _answeredCalls.remove(event.key);
          _workers.remove(event.key)?.dispose();
          if (_workers.isEmpty) {
            stop();
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
    if (PlatformUtils.isMobile) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _callKeep.setup(
          router.context!,
          {
            'ios': {'appName': 'Gapopa'},
            'android': {
              'alertTitle': 'label_call_permissions_title'.l10n,
              'alertDescription': 'label_call_permissions_description'.l10n,
              'cancelButton': 'btn_dismiss'.l10n,
              'okButton': 'btn_allow'.l10n,
              'foregroundService': {
                'channelId': 'com.team113.messenger',
                'channelName': 'Foreground calls service',
                'notificationTitle': 'My app is running on background',
                'notificationIcon': 'mipmap/ic_notification_launcher',
              },
              'additionalPermissions': <String>[],
            },
          },
        );

        if (PlatformUtils.isAndroid) {
          AndroidUtils.canDrawOverlays().then((v) {
            if (!v) {
              showDialog(
                barrierDismissible: false,
                context: router.context!,
                builder: (context) => AlertDialog(
                  title: Text('alert_popup_permissions_title'.l10n),
                  content: Text('alert_popup_permissions_description'.l10n),
                  actions: [
                    TextButton(
                      onPressed: () {
                        AndroidUtils.openOverlaySettings().then((_) {
                          Navigator.of(context).pop();
                        });
                      },
                      child: Text('alert_popup_permissions_button'.l10n),
                    ),
                  ],
                ),
              );
            }
          });
        }
      });
    }

    super.onReady();
  }

  @override
  void onClose() {
    _outgoingAudio?.cancel();
    _incomingAudio?.cancel();

    _subscription.cancel();
    _storageSubscription?.cancel();
    _workers.forEach((_, value) => value.dispose());

    if (_vibrationTimer != null) {
      _vibrationTimer?.cancel();
      Vibration.cancel();
    }

    _onDataReceived?.cancel();

    super.onClose();
  }

  /// Plays the given [asset].
  Future<void> play(String asset, {bool fade = false}) async {
    if (_myUser.value?.muted == null) {
      if (asset == _incoming) {
        final previous = _incomingAudio;
        _incomingAudio = AudioUtils.play(
          AudioSource.asset('audio/$asset'),
          fade: fade ? 1.seconds : Duration.zero,
        );
        previous?.cancel();
      } else {
        final previous = _outgoingAudio;
        _outgoingAudio = AudioUtils.play(
          AudioSource.asset('audio/$asset'),
          fade: fade ? 1.seconds : Duration.zero,
        );
        previous?.cancel();
      }
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

  /// Initializes a connection to the [_background] worker.
  void _initBackgroundService() {
    _onDataReceived = _background.on('answer').listen((event) {
      var callId = ChatId(event!['callId']!);

      var call = _callService.calls[callId];
      if (call == null) {
        _answeredCalls.add(callId);
      } else {
        if (call.value.state.value != OngoingCallState.joining &&
            call.value.state.value != OngoingCallState.active) {
          if (!router.lifecycle.value.inForeground) {
            Future(() async {
              await AndroidUtils.foregroundFromLockscreen();

              Worker? worker;
              worker = ever(router.lifecycle, (AppLifecycleState state) {
                if (state.inForeground) {
                  _callService.join(callId, withVideo: false);
                  worker?.dispose();
                }
              });
            });
          } else {
            _callService.join(callId, withVideo: false);
          }
        }
      }
    });
  }

  /// Initializes [WebUtils] related functionality.
  void _initWebUtils() {
    _storageSubscription = WebUtils.onStorageChange.listen((s) {
      if (s.key == null) {
        stop();
      } else if (s.key?.startsWith('call_') == true) {
        ChatId chatId = ChatId(s.key!.replaceAll('call_', ''));
        if (s.newValue == null) {
          _callService.remove(chatId);
          _workers.remove(chatId)?.dispose();
          if (_workers.isEmpty) {
            stop();
          }
        } else {
          var call = WebStoredCall.fromJson(json.decode(s.newValue!));
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
}
