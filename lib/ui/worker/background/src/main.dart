// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'dart:math';

import 'package:callkeep/callkeep.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:universal_io/io.dart';
import 'package:path_provider_android/path_provider_android.dart';
import 'package:path_provider_ios/path_provider_ios.dart';

import '/api/backend/schema.dart';
import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/session.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/provider/gql/graphql.dart';
import '/provider/hive/session.dart';
import '/routes.dart';

/// Background service iOS handler.
///
/// Not really useful for our use-case.
FutureOr<bool> onIosBackground(ServiceInstance _) => true;

/// Entry point of a background service.
Future<void> background(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS) FlutterBackgroundServiceIOS.registerWith();
  if (Platform.isAndroid) FlutterBackgroundServiceAndroid.registerWith();

  await _BackgroundService(service).init();
}

/// [FlutterBackgroundService] displaying incoming call notifications via
/// [FlutterCallkeep] on background.
class _BackgroundService {
  _BackgroundService(this._service);

  /// [ServiceInstance] itself.
  final ServiceInstance _service;

  /// [GraphQlProvider], used to communicate with backend.
  final GraphQlProvider _provider = GraphQlProvider();

  /// [FlutterCallkeep], used to display calls via native call APIs.
  final FlutterCallkeep _callKeep = FlutterCallkeep();

  /// [FlutterLocalNotificationsPlugin] displaying an incoming call notification
  /// in case the [FlutterCallkeep] has no permissions to do so.
  FlutterLocalNotificationsPlugin? _notificationPlugin;

  /// [Credentials] to use in the [_provider].
  Credentials? _credentials;

  /// [Timer], used to [_renewSession] after some period of time.
  Timer? _renewSessionTimer;

  /// [StreamSubscription] to the [GraphQlProvider.incomingCallsTopEvents].
  StreamSubscription? _subscription;

  /// Indicator whether the main application is in foreground or not.
  bool _isInForeground = true;

  /// Indicator whether the main application is considered alive or not.
  bool _connectionEstablished = true;

  /// [Timer] setting the [_connectionEstablished] to `false` if no message
  /// has been received for some time.
  Timer? _connectionFailureTimer;

  /// [Duration] of the [_connectionFailureTimer] to consider the application as
  /// non-active.
  static const Duration _connectionFailureDuration = Duration(seconds: 6);

  /// [Duration] of the [_renewSessionTimer] renewing the session.
  ///
  /// Should be enough to determine if [_connectionEstablished] is still `true`.
  static const Duration _renewSessionTimerDuration = Duration(seconds: 7);

  /// List of all the incoming calls.
  final List<String> _incomingCalls = [];

  /// List of calls being considered as accepted, so the [FlutterCallkeep]
  /// doesn't send a decline request on them.
  ///
  /// [FlutterCallkeep] is used in the following way:
  /// 1. When an incoming call is registered, the native call notification is
  ///    shown.
  /// 2. If user declines the call, then the native call is being rejected and
  ///    the corresponding callback is fired, so a decline request is sent.
  /// 3. If user accepts the call, then the native call is still being rejected
  ///    (as we don't want to use the native active call interface), so the
  ///    callback is still fired. That's where the [_acceptedCalls] are useful
  ///    as they contain the accepted call, so no decline request is sent.
  final List<String> _acceptedCalls = [];

  /// Indicator whether the [_renewSession] request has been fulfilled or not.
  ///
  /// Used in the [_connectionFailureTimer] to prevent repeating the
  /// [_renewSession] on the main application connection loss.
  bool _renewFulfilled = true;

  /// Initializes this [_BackgroundService].
  Future<void> init() async {
    if (_service is AndroidServiceInstance) {
      (_service as AndroidServiceInstance).setAsForegroundService();
    }

    await Config.init();
    await _initCallKeep();

    if (Platform.isAndroid) {
      PathProviderAndroid.registerWith();
    } else if (Platform.isIOS) {
      PathProviderIOS.registerWith();
    }

    _provider.authExceptionHandler = (e) async {
      _renewFulfilled = false;
      return _renewSession();
    };

    _resetConnectionTimer();

    await _initL10n();
    _initService();

    // Start a [Timer] fetching the [_credentials] from the [Hive] in case
    // [_connectionEstablished] is `false` after some time meaning the main
    // application is non-active.
    Timer(_renewSessionTimerDuration, () async {
      if (!_connectionEstablished && _credentials == null) {
        await Hive.initFlutter('hive');
        var sessionProvider = SessionDataHiveProvider();
        await sessionProvider.init();

        _credentials = sessionProvider.getCredentials();
        _provider.token = _credentials?.session.token;
        _provider.reconnect();

        if (_subscription == null) {
          _subscribe();
        }

        await sessionProvider.close();
        await Hive.close();
      }
    });
  }

  /// Initializes the [FlutterCallkeep].
  Future<void> _initCallKeep() async {
    await _callKeep.setup(
      null,
      {
        'ios': {'appName': 'Gapopa'},
        'android': {
          'alertTitle': 'label_call_permissions_title'.td,
          'alertDescription': 'label_call_permissions_description'.td,
          'cancelButton': 'btn_dismiss'.td,
          'okButton': 'btn_allow'.td,
          'foregroundService': {
            'channelId': 'com.team113.messenger',
            'channelName': 'Foreground calls service',
            'notificationTitle': 'My app is running on background',
            'notificationIcon': 'mipmap/ic_notification_launcher',
          },
          'additionalPermissions': <String>[],
        },
      },
      backgroundMode: true,
    );

    _callKeep.on(CallKeepPerformAnswerCallAction(),
        (CallKeepPerformAnswerCallAction event) async {
      _acceptedCalls.add(event.callUUID!);
      _incomingCalls.remove(event.callUUID!);
      await _callKeep.rejectCall(event.callUUID!);
      await _callKeep.backToForeground();
      Future.delayed(1.seconds, () {
        _service.invoke('answer', {'callId': event.callUUID});

        // To be sure the call is answered.
        Future.delayed(1.seconds, () {
          _service.invoke('answer', {'callId': event.callUUID});
        });
      });
    });

    _callKeep.on(CallKeepPerformEndCallAction(),
        (CallKeepPerformEndCallAction event) async {
      _incomingCalls.remove(event.callUUID!);
      if (!_acceptedCalls.contains(event.callUUID!)) {
        await _provider.declineChatCall(ChatId(event.callUUID!));
      } else {
        _acceptedCalls.remove(event.callUUID!);
      }
    });
  }

  /// Initializes the [_service].
  void _initService() {
    _service.on('stop').listen((event) {
      _resetConnectionTimer();
      _service.stopSelf();
    });

    _service.on('foreground').listen((event) {
      _resetConnectionTimer();
      _isInForeground = true;
      _acceptedCalls.addAll(_incomingCalls);
      _incomingCalls.clear();
      _callKeep.endAllCalls();
    });

    _service.on('background').listen((event) {
      _resetConnectionTimer();
      _isInForeground = false;
    });

    _service.on('detached').listen((event) {
      _resetConnectionTimer();
      _isInForeground = false;
      _connectionEstablished = false;
      _connectionFailureTimer?.cancel();
    });

    _service.on('token').listen((event) {
      _resetConnectionTimer();

      _renewFulfilled = true;
      _credentials = Credentials.fromJson(event!);

      _renewSessionTimer?.cancel();
      _provider.token = _credentials?.session.token;
      _provider.reconnect();

      if (_subscription == null) {
        _subscribe();
      }
    });

    _service.on('l10n').listen((event) {
      _resetConnectionTimer();
      _initL10n(event!['locale']);
    });

    _service.on('ka').listen((_) {
      _resetConnectionTimer();
    });

    _service.invoke('requireToken');

    _setForegroundNotificationInfo(
      title: 'label_service_initialized'.td,
      content: '${DateTime.now()}',
    );
  }

  /// Starts the [_renewSessionTimer] renewing the [_credentials].
  Future<void> _renewSession() async {
    _renewSessionTimer?.cancel();
    _renewSessionTimer = Timer(
      _connectionEstablished ? _renewSessionTimerDuration : Duration.zero,
      () async {
        if (!_connectionEstablished) {
          if (_credentials?.rememberedSession.expireAt
                  .isAfter(PreciseDateTime.now().toUtc()) ==
              true) {
            try {
              _renewFulfilled = true;

              var result = await _provider
                  .renewSession(_credentials!.rememberedSession.token);
              var ok = (result.renewSession
                  as RenewSession$Mutation$RenewSession$RenewSessionOk);
              _credentials = Credentials(
                Session(ok.session.token, ok.session.expireAt),
                RememberedSession(
                  ok.remembered.token,
                  ok.remembered.expireAt,
                ),
                ok.user.id,
              );

              // Store the [Credentials] in the [Hive].
              Future(() async {
                // Re-initialization is required every time since [Hive] may
                // behave poorly between isolates.
                await Hive.initFlutter('hive');
                var sessionProvider = SessionDataHiveProvider();
                await sessionProvider.init();
                await sessionProvider.setCredentials(_credentials!);
                await sessionProvider.close();
                await Hive.close();
              });

              _service.invoke('token', _credentials!.toJson());

              _provider.token = _credentials?.session.token;
              _provider.reconnect();
            } on RenewSessionException catch (_) {
              _service.invoke('requireToken');
            }
          } else {
            _service.invoke('requireToken');
          }
        }
      },
    );
  }

  /// Resets the [_connectionFailureTimer] timer and sets the
  /// [_connectionEstablished] to `true`.
  void _resetConnectionTimer() {
    _connectionEstablished = true;
    _connectionFailureTimer?.cancel();
    _connectionFailureTimer = Timer(_connectionFailureDuration, () {
      _connectionEstablished = false;
      if (!_renewFulfilled) {
        _renewSession();
      }
    });
  }

  /// Returns the lazily initialized [FlutterLocalNotificationsPlugin].
  Future<FlutterLocalNotificationsPlugin> _getNotificationPlugin() async {
    if (_notificationPlugin == null) {
      _notificationPlugin = FlutterLocalNotificationsPlugin();
      await _notificationPlugin!.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
    }

    return _notificationPlugin!;
  }

  /// Initializes the [L10n] of the provided [locale].
  Future<void> _initL10n([String? locale]) async {
    if ((locale ?? 'en_US') != L10n.chosen.value) {
      locale ??= Platform.localeName.replaceAll('-', '_');
      if (!L10n.languages.containsKey(locale)) {
        locale = 'en_US';
      }

      L10n.chosen.value = locale;
      await L10n.load();
    }
  }

  /// Displays an incoming call notification for the provided [chatId] with the
  /// provided [name].
  void _displayIncomingCall(ChatId chatId, String name) {
    _callKeep.displayIncomingCall(chatId.val, name, handleType: 'generic');

    // Show a notification if phone account permission is not granted.
    Future(() => _callKeep.hasPhoneAccount()).then((b) {
      if (!b) {
        _getNotificationPlugin().then((v) {
          v.show(
            Random().nextInt(1 << 31),
            'label_incoming_call'.td,
            name,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'com.team113.messenger',
                'Gapopa',
              ),
            ),
            payload: '${Routes.chat}/$chatId',
          );
        });
      }
    });
  }

  /// Subscribes to the [GraphQlProvider.incomingCallsTopEvents].
  Future<void> _subscribe() async {
    _subscription = (await _provider.incomingCallsTopEvents(3)).listen(
      (event) {
        GraphQlProviderExceptions.fire(event);
        var e = IncomingCallsTopEvents$Subscription.fromJson(event.data!)
            .incomingChatCallsTopEvents;
        switch (e.$$typename) {
          case 'SubscriptionInitialized':
            _setForegroundNotificationInfo(
              title: 'label_service_connected'.td,
              content: '${DateTime.now()}',
            );
            break;

          case 'IncomingChatCallsTop':
            if (!_isInForeground || !_connectionEstablished) {
              _callKeep.endAllCalls();
              var calls =
                  (e as IncomingCallsTopEvents$Subscription$IncomingChatCallsTopEvents$IncomingChatCallsTop)
                      .list;
              for (var call in calls) {
                _incomingCalls.add(call.chatId.val);

                // TODO: Display `Chat` name instead of the `ChatCall.caller`.
                _displayIncomingCall(
                  call.chatId,
                  call.caller?.name?.val ??
                      call.caller?.num.val ??
                      ('dot_symbol'.td * 3),
                );
              }

              _setForegroundNotificationInfo(
                title: 'label_service_connected'.td,
                content: '${DateTime.now()}',
              );
            }
            break;

          case 'EventIncomingChatCallsTopChatCallAdded':
            if (!_isInForeground || !_connectionEstablished) {
              var call =
                  (e as IncomingCallsTopEvents$Subscription$IncomingChatCallsTopEvents$EventIncomingChatCallsTopChatCallAdded)
                      .call;
              _incomingCalls.add(call.chatId.val);

              _setForegroundNotificationInfo(
                title: 'label_service_connected'.td,
                content: '${DateTime.now()}',
              );

              // TODO: Display `Chat` name instead of the `ChatCall.caller`.
              _displayIncomingCall(
                call.chatId,
                call.caller?.name?.val ??
                    call.caller?.num.val ??
                    ('dot_symbol'.td * 3),
              );
            }
            break;

          case 'EventIncomingChatCallsTopChatCallRemoved':
            var call =
                (e as IncomingCallsTopEvents$Subscription$IncomingChatCallsTopEvents$EventIncomingChatCallsTopChatCallRemoved)
                    .call;
            _incomingCalls.remove(call.chatId.val);

            _setForegroundNotificationInfo(
              title: 'label_service_connected'.td,
              content: '${DateTime.now()}',
            );

            _callKeep.endCall(call.chatId.val);
            _callKeep.reportEndCallWithUUID(call.chatId.val, 0);
            break;
        }
      },
      onError: (e) {
        if (e is ResubscriptionRequiredException) {
          _setForegroundNotificationInfo(
            title: 'label_service_reconnecting'.td,
            content: '${DateTime.now()}',
          );
          _subscribe();
        } else {
          _setForegroundNotificationInfo(
            title: 'label_service_encountered_error'.td,
            content: e,
          );
          throw e;
        }
      },
    );
  }

  /// Sets the foreground notification info to the provided [title] with
  /// [content], if [_service] is [AndroidServiceInstance].
  Future<void> _setForegroundNotificationInfo({
    required String title,
    required String content,
  }) {
    if (_service is AndroidServiceInstance) {
      return (_service as AndroidServiceInstance)
          .setForegroundNotificationInfo(title: title, content: content);
    }

    return Future.value();
  }
}
