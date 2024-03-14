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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/service/call.dart';
import '/util/media_utils.dart';
import '/util/obs/obs.dart';
import 'view.dart';

export 'view.dart';

/// Controller of a [ScreenShareView].
class ScreenShareController extends GetxController {
  ScreenShareController(
    this._callService, {
    required this.call,
    required this.pop,
  });

  /// [OngoingCall] this [ScreenShareController] is bound to.
  final Rx<OngoingCall> call;

  /// Callback, called when a [ScreenShareView] this controller is bound to
  /// should be popped from the [Navigator].
  final void Function()? pop;

  /// [RtcVideoRenderer]s of the [OngoingCall.displays].
  final RxMap<MediaDisplayDetails, RtcVideoRenderer> renderers =
      RxMap<MediaDisplayDetails, RtcVideoRenderer>();

  /// Currently selected [MediaDisplayDetails].
  final Rx<MediaDisplayDetails?> selected = Rx(null);

  /// Subscription for the [CallService.calls] changes.
  late final StreamSubscription? _callsSubscription;

  /// Subscription for the [OngoingCall.displays] updating the [renderers].
  late final StreamSubscription? _displaysSubscription;

  /// [CallService] for [pop]ping the view when [ChatCall] in the [Chat]
  /// identified by the [OngoingCall.chatId] is removed.
  final CallService _callService;

  /// Stored [LocalMediaTrack]s to free in the [onClose].
  final List<LocalMediaTrack> _localTracks = [];

  @override
  void onInit() {
    _callsSubscription = _callService.calls.changes.listen((e) {
      switch (e.op) {
        case OperationKind.removed:
          if (call.value.chatId.value == e.key) {
            pop?.call();
          }
          break;

        case OperationKind.added:
        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    _displaysSubscription = call.value.displays.listen((e) {
      for (MediaDisplayDetails display in e) {
        if (renderers[display] == null) {
          initRenderer(display);
        }
      }
    });

    for (var e in call.value.displays) {
      initRenderer(e);
    }

    selected.value = call.value.displays.firstOrNull;

    super.onInit();
  }

  @override
  void onClose() {
    _callsSubscription?.cancel();
    _displaysSubscription?.cancel();
    freeTracks();
    super.onClose();
  }

  /// Initializes a [RtcVideoRenderer] for the provided [display].
  Future<void> initRenderer(MediaDisplayDetails display) async {
    final List<LocalMediaTrack> tracks = await MediaUtils.getTracks(
      screen: ScreenPreferences(device: display.deviceId(), framerate: 5),
    );

    _localTracks.addAll(tracks);

    final RtcVideoRenderer renderer = RtcVideoRenderer(tracks.first);
    await renderer.initialize();
    renderer.srcObject = tracks.first.getTrack();

    renderers[display] = renderer;
  }

  /// Disposes the [renderers] and frees the [LocalMediaTrack]s being used.
  void freeTracks() {
    for (RtcVideoRenderer t in renderers.values) {
      t.dispose();
    }
    renderers.clear();

    for (LocalMediaTrack t in _localTracks) {
      t.free();
    }
    _localTracks.clear();
  }
}
