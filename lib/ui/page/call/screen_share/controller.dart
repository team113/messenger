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

import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/service/call.dart';
import '/util/obs/obs.dart';
import 'view.dart';

export 'view.dart';

/// Controller of a [ScreenShareView].
class ScreenShareController extends GetxController {
  ScreenShareController(
    this._callService, {
    required this.chatId,
    required this.displays,
    this.pop,
  });

  /// ID of a [Chat] this [ScreenShareSelector] is bound to.
  final Rx<ChatId> chatId;

  /// Available [MediaDisplayInfo]s for screen sharing.
  final RxList<MediaDisplayInfo> displays;

  /// Callback, called when a [ScreenShareSelector] this controller is bound to
  /// should be popped from the [Navigator].
  final void Function()? pop;

  /// Renderers of the [displays].
  final RxMap<MediaDisplayInfo, RtcVideoRenderer> renderers =
      RxMap<MediaDisplayInfo, RtcVideoRenderer>();

  /// Subscription for the [CallService.calls] changes.
  late final StreamSubscription? _chatsSubscription;

  /// Subscription for the [displays] updating the [renderers].
  late final StreamSubscription? _displaysSubscription;

  /// [CallService] for [pop]ping the view when [ChatCall] in the [Chat]
  /// identified by the [chatId] is removed.
  final CallService _callService;

  /// Handle to a media manager tracking all the connected devices.
  late MediaManagerHandle _mediaManager;

  /// Client for communication with a media server.
  late Jason _jason;

  /// Stored [LocalMediaTrack]s to free in the [onClose].
  final List<LocalMediaTrack> _localTracks = [];

  @override
  void onInit() {
    _chatsSubscription = _callService.calls.changes.listen((e) {
      switch (e.op) {
        case OperationKind.removed:
          if (chatId.value == e.key) {
            pop?.call();
          }
          break;

        case OperationKind.added:
        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    _displaysSubscription = displays.listen((e) {
      for (var display in e) {
        if (renderers[display] == null) {
          initRenderer(display);
        }
      }
    });

    _jason = Jason();
    _mediaManager = _jason.mediaManager();
    _initRenderers();

    super.onInit();
  }

  @override
  void onClose() {
    _chatsSubscription?.cancel();
    _displaysSubscription?.cancel();
    _mediaManager.free();
    _jason.free();

    for (RtcVideoRenderer t in renderers.values) {
      t.dispose();
    }

    for (LocalMediaTrack t in _localTracks) {
      t.free();
    }

    super.onClose();
  }

  /// Initializes a [RtcVideoRenderer] for the provided [display].
  Future<void> initRenderer(MediaDisplayInfo display) async {
    List<LocalMediaTrack> tracks = await _mediaManager.initLocalTracks(
      _mediaStreamSettings(display.deviceId()),
    );

    _localTracks.addAll(tracks);

    final RtcVideoRenderer renderer = RtcVideoRenderer(tracks.first);
    await renderer.initialize();
    renderer.srcObject = tracks.first.getTrack();

    renderers[display] = renderer;
  }

  /// Initializes the [renderers].
  void _initRenderers() {
    for (var e in displays) {
      initRenderer(e);
    }
  }

  /// Returns [MediaStreamSettings] with enabled screen sharing.
  MediaStreamSettings _mediaStreamSettings(String screenShareDevice) {
    MediaStreamSettings settings = MediaStreamSettings();

    DisplayVideoTrackConstraints constraints = DisplayVideoTrackConstraints();
    constraints.deviceId(screenShareDevice);
    constraints.idealFrameRate(5);
    constraints.exactFrameRate(5);

    settings.displayVideo(constraints);
    return settings;
  }
}
