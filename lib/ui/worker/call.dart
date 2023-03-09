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

import 'package:audioplayers/audioplayers.dart';
import 'package:callkeep/callkeep.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock/wakelock.dart';

import '/domain/model/chat.dart';
import '/domain/model/my_user.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/service/call.dart';
import '/domain/service/disposable_service.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/util/android_utils.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// Worker responsible for showing an incoming call notification and playing an
/// incoming or outgoing call audio.
class CallWorker extends DisposableService {
  CallWorker(
    this._callService,
    this._myUserService,
  );

  /// [AudioPlayer] currently playing an audio.
  AudioPlayer? _audioPlayer;

  /// [CallService] used to get reactive changes of [OngoingCall]s.
  final CallService _callService;

  /// [MyUserService] used to get [MyUser.muted] status.
  final MyUserService _myUserService;

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

  /// [Worker] reacting on the [RouterState.lifecycle] changes.
  Worker? _lifecycleWorker;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get _myUser => _myUserService.myUser;

  @override
  void onInit() {
    _initAudio();
    _initWebUtils();

    bool wakelock = _callService.calls.isNotEmpty;
    if (wakelock) {
      Wakelock.enable().onError((_, __) => false);
    }

    _lifecycleWorker = ever(router.lifecycle, (e) async {
      if (e.inForeground) {
        _callKeep.endAllCalls();

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        _callService.calls.forEach((key, value) {
          if ((_answeredCalls.contains(key) ||
                  prefs.getString('answeredCall') == key.val) &&
              !value.value.isActive) {
            _callService.join(key, withVideo: false);
            _answeredCalls.remove(key);
            prefs.remove('answeredCall');
          }
        });
      }
    });

    _subscription = _callService.calls.changes.listen((event) async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!wakelock && _callService.calls.isNotEmpty) {
        wakelock = true;
        Wakelock.enable().onError((_, __) => false);
      } else if (wakelock && _callService.calls.isEmpty) {
        wakelock = false;
        Wakelock.disable().onError((_, __) => false);
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
            if (isInForeground &&
                (prefs.getString('answeredCall') == c.chatId.value.val ||
                    _answeredCalls.contains(c.chatId.value))) {
              _callService.join(c.chatId.value, withVideo: false);
              _answeredCalls.remove(c.chatId.value);
              prefs.remove('acceptedCall');
            } else if (calling) {
              play('ringing.mp3');
            } else if (!PlatformUtils.isMobile || isInForeground) {
              play('chinese.mp3');
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

        _callKeep.on(CallKeepPerformAnswerCallAction(), (event) {
          if (event.callUUID != null) {
            _answeredCalls.add(ChatId(event.callUUID!));
          }
        });

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
    _audioPlayer?.dispose();

    AudioCache.instance.clear('audio/ringing.mp3');
    AudioCache.instance.clear('audio/chinese.mp3');

    _subscription.cancel();
    _storageSubscription?.cancel();
    _workers.forEach((_, value) => value.dispose());
    _lifecycleWorker?.dispose();

    if (_vibrationTimer != null) {
      _vibrationTimer?.cancel();
      Vibration.cancel();
    }

    _onDataReceived?.cancel();

    super.onClose();
  }

  /// Plays the given [asset].
  Future<void> play(String asset) async {
    if (_myUser.value?.muted == null) {
      runZonedGuarded(() async {
        await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer?.play(
          AssetSource('audio/$asset'),
          position: Duration.zero,
          mode: PlayerMode.mediaPlayer,
        );
      }, (e, _) {
        if (!e.toString().contains('NotAllowedError')) {
          throw e;
        }
      });
    }
  }

  /// Stops the audio that is currently playing.
  Future<void> stop() async {
    if (_vibrationTimer != null) {
      _vibrationTimer?.cancel();
      Vibration.cancel();
    }

    await _audioPlayer?.setReleaseMode(ReleaseMode.release);
    await _audioPlayer?.stop();
    await _audioPlayer?.release();
  }

  /// Initializes the [_audioPlayer].
  Future<void> _initAudio() async {
    try {
      _audioPlayer = AudioPlayer();
      await AudioCache.instance
          .loadAll(['audio/ringing.mp3', 'audio/chinese.mp3']);
    } on MissingPluginException {
      _audioPlayer = null;
    }
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
