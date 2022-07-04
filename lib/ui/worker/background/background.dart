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

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:messenger/fluent/fluent_localization.dart';

import '/domain/model/session.dart';
import '/provider/hive/session.dart';
import '/routes.dart';
import '/store/model/session_data.dart';
import '/util/platform_utils.dart';
import 'src/main.dart';

/// Worker responsible for a [FlutterBackgroundService] management.
class BackgroundWorker extends GetxService {
  BackgroundWorker(this._sessionProvider);

  /// [SessionDataHiveProvider] listening [Credentials] changes.
  final SessionDataHiveProvider _sessionProvider;

  /// [FlutterBackgroundService] itself.
  final FlutterBackgroundService _service = FlutterBackgroundService();

  /// [StreamSubscription] to [SessionDataHiveProvider.boxEvents] sending new
  /// [Credentials] to the [_service].
  StreamSubscription? _sessionSubscription;

  /// [StreamSubscription]s to [FlutterBackgroundService.on] used to communicate
  /// with the [_service].
  final List<StreamSubscription> _onDataReceived = [];

  /// [Timer] sending "keep alive" messages to the [_service].
  Timer? _keepAliveTimer;

  /// Interval of the [_keepAliveTimer].
  static const _keepAliveInterval = Duration(seconds: 5);

  /// [Worker] reacting on the [RouterState.lifecycle] changes.
  Worker? _lifecycleWorker;

  @override
  void onInit() {
    if (PlatformUtils.isAndroid && !PlatformUtils.isWeb) {
      _initService();

      var lastCreds = _sessionProvider.getCredentials();
      _sessionSubscription = _sessionProvider.boxEvents.listen((e) {
        // If session is deleted, then ask the [_service] to stop.
        if (e.deleted) {
          lastCreds = null;
          _service.invoke('stop');
          _dispose();
        } else {
          var creds = (e.value as SessionData).credentials;
          // Otherwise if [Credentials] mismatch is detected, update the
          // [_service].
          if (creds?.session.token != lastCreds?.session.token ||
              creds?.rememberedSession.token !=
                  lastCreds?.rememberedSession.token) {
            lastCreds = creds;

            if (creds == null) {
              _service.invoke('stop');
              _dispose();
            } else {
              // Start the service, if not already. Otherwise, send the new
              // token to it.
              if (_onDataReceived.isEmpty) {
                _initService();
              } else {
                _service.invoke('token', creds.toJson());
              }
            }
          }
        }
      });
    }

    super.onInit();
  }

  @override
  void onClose() {
    _dispose();
    _sessionSubscription?.cancel();
    super.onClose();
  }

  /// Returns a [Stream] of the data from the background service.
  Stream on(String method) {
    if (PlatformUtils.isAndroid && !PlatformUtils.isWeb) {
      return _service.on(method);
    }

    return const Stream.empty();
  }

  /// Initializes the [_service].
  Future<void> _initService() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Do not initialize the service if no [Credentials] are stored.
    if (_sessionProvider.getCredentials() == null) {
      return;
    }

    for (var e in _onDataReceived) {
      e.cancel();
    }
    _onDataReceived.clear();

    _onDataReceived.add(_service.on('requireToken').listen((e) {
      var session = _sessionProvider.getCredentials();
      FlutterBackgroundService().invoke('token', session!.toJson());
    }));

    _onDataReceived.add(_service.on('token').listen((e) {
      _sessionProvider.setCredentials(Credentials.fromJson(e!));
    }));

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        autoStart: true,
        onStart: background,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: background,
        onBackground: onIosBackground,
      ),
    );

    bool isRunning = await _service.isRunning();
    if (isRunning) {
      _sendLifecycleUpdate();
      _lifecycleWorker = ever(router.lifecycle, (_) => _sendLifecycleUpdate());

      _keepAliveTimer = Timer.periodic(_keepAliveInterval, (_) {
        FlutterBackgroundService().isRunning().then((bool b) {
          if (b) {
            FlutterBackgroundService().invoke('ka');
          } else {
            _keepAliveTimer?.cancel();
          }
        });
      });

      // TODO: Use [Worker] to react on [LocalizationUtils.chosen] changes.
      await LocalizationUtils.init();
    }
  }

  /// Disposes the [_service] related resources.
  void _dispose() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _lifecycleWorker?.dispose();
    _lifecycleWorker = null;

    for (var e in _onDataReceived) {
      e.cancel();
    }
    _onDataReceived.clear();
  }

  /// Sends a [RouterState.lifecycle] value to the [_service].
  void _sendLifecycleUpdate() {
    switch (router.lifecycle.value) {
      case AppLifecycleState.resumed:
        try {
          FlutterBackgroundService().invoke('foreground');
        } catch (_) {
          // No-op.
        }
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        try {
          FlutterBackgroundService().invoke('background');
        } catch (_) {
          // No-op.
        }
        break;

      case AppLifecycleState.detached:
        try {
          FlutterBackgroundService().invoke('detached');
        } catch (_) {
          // No-op.
        }
        break;

      default:
        break;
    }
  }
}
