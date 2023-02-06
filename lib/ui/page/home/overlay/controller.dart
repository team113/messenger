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

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/repository/settings.dart';
import '/domain/service/auth.dart';
import '/domain/service/call.dart';
import '/l10n/l10n.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

export 'view.dart';

/// Controller of an [OngoingCall]s overlay.
class CallOverlayController extends GetxController {
  CallOverlayController(
    this._callService,
    this._authService,
    this._settingsRepo,
  );

  /// Call service used to expose the [calls].
  final CallService _callService;

  /// Authentication service used to get the stored [Credentials].
  final AuthService _authService;

  /// Settings repository, used to get the stored [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// Reactive ordered list of [OngoingCall]s.
  final RxList<OverlayCall> calls = RxList<OverlayCall>([]);

  /// Subscription to [CallService.calls] map.
  late final StreamSubscription _subscription;

  /// [Worker]s reacting on [OngoingCall.call] changes, used to put the calls to
  /// the browser's storage.
  final Map<ChatId, Worker> _workers = {};

  /// Returns the stored [ApplicationSettings].
  Rx<ApplicationSettings?> get _settings => _settingsRepo.applicationSettings;

  @override
  void onInit() {
    _subscription = _callService.calls.changes.listen((event) async {
      switch (event.op) {
        case OperationKind.added:
          bool window = false;

          var ongoingCall = event.value!.value;
          if (PlatformUtils.isDesktop &&
              _settings.value?.enablePopups != false) {
            window = true;
            try {
              int? windowId = await PlatformUtils.openPopup(
                ongoingCall,
                _authService.credentials.value,
              );

              if (PlatformUtils.isWeb) {
                WebUtils.setCall(ongoingCall.toStored());
                if (ongoingCall.callChatItemId == null ||
                    ongoingCall.deviceId == null) {
                  _workers[event.key!] = ever(
                    ongoingCall.call,
                    (ChatCall? call) {
                      WebUtils.setCall(ongoingCall.toStored());

                      if (call?.id != null) {
                        _workers[event.key!]?.dispose();
                      }
                    },
                  );
                }
              } else {
                DesktopMultiWindow.invokeMethod(
                  windowId!,
                  'call',
                  json.encode(ongoingCall.toStored().toJson()),
                );

                if (ongoingCall.callChatItemId == null ||
                    ongoingCall.deviceId == null) {
                  _workers[event.key!] = ever(
                    ongoingCall.call,
                    (ChatCall? call) {
                      DesktopMultiWindow.invokeMethod(
                        windowId,
                        'call',
                        json.encode(ongoingCall.toStored()),
                      );

                      if (call?.id != null) {
                        _workers[event.key!]?.dispose();
                      }
                    },
                  );
                }
              }
            } catch (e) {
              if (PlatformUtils.isWeb) {
                Future.delayed(Duration.zero, () {
                  ongoingCall.addError('err_call_popup_was_blocked'.l10n);
                });
              }

              Log.error(e);
              window = false;
            }
          }

          if (!window) {
            // Otherwise the popup creation request failed or wasn't invoked, so
            // add this call to the [calls] to display it in the view.
            calls.add(OverlayCall(event.value!));
          }

          break;

        case OperationKind.removed:
          calls.removeWhere((e) => e.call == event.value!);
          PlatformUtils.removeCall(event.value!.value);
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }
    });
    super.onInit();
  }

  @override
  void onClose() {
    _subscription.cancel();
    _workers.forEach((_, e) => e.dispose());
    super.onClose();
  }

  /// Moves the given [call] to the end of the [calls].
  void orderFirst(OverlayCall call) {
    var index = calls.indexOf(call);
    if (index != calls.length - 1) {
      calls.removeAt(index);
      calls.add(call);
    }
  }
}

/// Reactive [OngoingCall] with a [GlobalKey] associated with it.
class OverlayCall {
  OverlayCall(this.call);

  /// [GlobalKey] identifying the [call].
  final GlobalKey key = GlobalKey();

  /// Reactive [OngoingCall] itself.
  final Rx<OngoingCall> call;
}
