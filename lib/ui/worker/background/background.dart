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

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';

import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/provider/hive/account.dart';
import '/provider/hive/credentials.dart';
import '/routes.dart';
import '/util/platform_utils.dart';
import 'src/main.dart';

/// Worker responsible for a [FlutterBackgroundService] management.
class BackgroundWorker extends GetxService {
  BackgroundWorker(this._credentialsProvider, this._accountProvider);

  /// [CredentialsHiveProvider] listening [Credentials] changes.
  final CredentialsHiveProvider _credentialsProvider;

  /// [AccountHiveProvider] used to get the currently active [UserId].
  final AccountHiveProvider _accountProvider;

  /// [FlutterBackgroundService] itself.
  final FlutterBackgroundService _service = FlutterBackgroundService();

  /// [StreamSubscription] to [CredentialsHiveProvider.boxEvents] sending new
  /// [Credentials] to the [_service].
  StreamSubscription? _credentialsSubscription;

  /// [StreamSubscription]s to [FlutterBackgroundService.on] used to communicate
  /// with the [_service].
  final List<StreamSubscription> _onDataReceived = [];

  /// [Timer] sending "keep alive" messages to the [_service].
  Timer? _keepAliveTimer;

  /// Interval of the [_keepAliveTimer].
  static const _keepAliveInterval = Duration(seconds: 5);

  /// [Worker] reacting on the [RouterState.lifecycle] changes.
  Worker? _lifecycleWorker;

  /// [Worker] reacting on the [L10n.chosen] changes.
  Worker? _localizationWorker;

  /// Current [Credentials] being used in this [BackgroundWorker].
  Credentials? currentCreds;

  /// Returns the [Credentials] of the active [MyUser].
  Credentials? get _storedCreds {
    final UserId? id = _accountProvider.userId;
    final Credentials? creds = id != null ? _credentialsProvider.get(id) : null;

    return creds;
  }

  @override
  void onInit() {
    if (PlatformUtils.isAndroid && !PlatformUtils.isWeb) {
      _initService();

      _credentialsSubscription = _credentialsProvider.boxEvents.listen((e) {
        final key = UserId(e.key);

        if (key == currentCreds?.userId) {
          // If session is deleted, then ask the [_service] to stop.
          if (e.deleted) {
            _service.invoke('stop');
            _dispose();
          } else {
            final Credentials newCreds = e.value;

            // Start the service, if not already. Otherwise, send the new
            // token to it.
            if (_onDataReceived.isEmpty) {
              _initService();
            } else {
              _service.invoke('token', newCreds.toJson());
            }
          }
        } else {
          // No-op, as [Credentials] of non-active [MyUser] were changed.
        }
      });
    }

    super.onInit();
  }

  @override
  void onClose() {
    _dispose();
    _credentialsSubscription?.cancel();
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
    if (_storedCreds == null) {
      return;
    }

    currentCreds = _storedCreds;

    for (var e in _onDataReceived) {
      e.cancel();
    }
    _onDataReceived.clear();

    _onDataReceived.add(_service.on('requireToken').listen((e) {
      FlutterBackgroundService().invoke('token', currentCreds!.toJson());
    }));

    _onDataReceived.add(_service.on('token').listen((e) {
      _credentialsProvider.put(Credentials.fromJson(e!));
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

      FlutterBackgroundService()
          .invoke('l10n', {'locale': L10n.chosen.value.toString()});
      _localizationWorker = ever(L10n.chosen, (Language? locale) {
        FlutterBackgroundService()
            .invoke('l10n', {'locale': locale.toString()});
      });
    }
  }

  /// Disposes the [_service] related resources.
  void _dispose() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _lifecycleWorker?.dispose();
    _lifecycleWorker = null;
    _localizationWorker?.dispose();
    _localizationWorker = null;
    currentCreds = null;

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
