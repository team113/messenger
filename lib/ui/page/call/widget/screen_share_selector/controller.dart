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
import '/domain/model/ongoing_call.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of a [MuteChatView].
class ScreenShareSelectorController extends GetxController {
  ScreenShareSelectorController(
    this._callService, {
    required this.chatId,
    required this.displays,
    this.pop,
  });

  /// ID of the [Chat] to mute.
  final ChatId chatId;

  /// Possible [MediaDisplayInfo]s to share screen.
  final List<MediaDisplayInfo> displays;

  /// Callback, called when a [MuteChatView] this controller is bound to should
  /// be popped from the [Navigator].
  final void Function()? pop;

  /// Subscription for the [ChatService.chats] changes.
  late final StreamSubscription? _chatsSubscription;

  /// [ChatService] for [pop]ping the view when a [Chat] identified by the
  /// [chatId] is removed.
  final CallService _callService;

  /// Handle to a media manager tracking all the connected devices.
  late MediaManagerHandle mediaManager;

  /// Client for communication with a media server.
  late Jason _jason;

  /// Indicates whether this controller was initialized and [renderers] can be
  /// used.
  final RxBool isReady = RxBool(false);

  /// Renderers of the [displays].
  final Map<MediaDisplayInfo, RtcVideoRenderer> renderers =
      <MediaDisplayInfo, RtcVideoRenderer>{};

  /// Stored [LocalMediaTrack]s to free in the [onClose].
  final List<LocalMediaTrack> _localTracks = [];

  @override
  void onInit() {
    _chatsSubscription = _callService.calls.changes.listen((e) {
      switch (e.op) {
        case OperationKind.removed:
          if (chatId == e.key) {
            pop?.call();
          }
          break;

        case OperationKind.added:
        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    _jason = Jason();
    mediaManager = _jason.mediaManager();
    _initRenderers();

    super.onInit();
  }

  @override
  void onClose() {
    _chatsSubscription?.cancel();
    mediaManager.free();
    _jason.free();

    for (RtcVideoRenderer t in renderers.values) {
      t.dispose();
    }

    for (LocalMediaTrack t in _localTracks) {
      t.free();
    }

    super.onClose();
  }

  /// Initializes the [renderers].
  Future<void> _initRenderers() async {
    for (var e in displays) {
      List<LocalMediaTrack> tracks = await mediaManager.initLocalTracks(
        _mediaStreamSettings(screenShareDevice: e.deviceId()),
      );
      _localTracks.addAll(tracks);

      RtcVideoRenderer renderer = RtcVideoRenderer(tracks.first);
      await renderer.initialize();
      renderer.srcObject = tracks.first.getTrack();

      renderers[e] = renderer;
    }

    isReady.value = true;
  }

  /// Returns [MediaStreamSettings] with enabled screen sharing.
  MediaStreamSettings _mediaStreamSettings({
    required String screenShareDevice,
  }) {
    MediaStreamSettings settings = MediaStreamSettings();

    DisplayVideoTrackConstraints constraints = DisplayVideoTrackConstraints();
    constraints.deviceId(screenShareDevice);
    constraints.idealFrameRate(10);
    constraints.exactFrameRate(10);

    settings.displayVideo(constraints);
    return settings;
  }
}
