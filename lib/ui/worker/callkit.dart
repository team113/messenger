// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '/domain/model/session.dart';
import '/domain/service/auth.dart';
import '/domain/service/disposable_service.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';
import 'call.dart';

/// Worker listening for [FlutterCallkitIncoming] events to prevent it from
/// displaying when [AuthService] is unauthorized.
class CallKitWorker extends DisposableService {
  CallKitWorker(this._authService);

  /// [AuthService] for retrieving the current [Credentials] in
  /// [FlutterCallkitIncoming] events handling.
  final AuthService _authService;

  /// [FlutterCallkitIncoming.onEvent] subscription reacting on the native call
  /// interface events.
  StreamSubscription? _callKitSubscription;

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
    if (_isCallKit) {
      _callKitSubscription = FlutterCallkitIncoming.onEvent.listen((
        CallEvent? event,
      ) async {
        Log.debug('FlutterCallkitIncoming.onEvent -> $event', '$runtimeType');

        switch (event!.event) {
          case Event.actionCallAccept:
          case Event.actionCallDecline:
          case Event.actionCallIncoming:
            // If we have no authorization, then we should ignore the VoIP
            // notification completely.
            if (_authService.credentials.value == null) {
              final String? chatId = event.body['extra']?['chatId'];
              if (chatId != null) {
                await FlutterCallkitIncoming.endCall(chatId.base62ToUuid());
              }
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
          case Event.actionCallEnded:
          case Event.actionCallTimeout:
          case Event.actionCallToggleMute:
            // No-op.
            break;
        }
      });
    }

    super.onInit();
  }

  @override
  void onClose() {
    _callKitSubscription?.cancel();
    super.onClose();
  }
}
