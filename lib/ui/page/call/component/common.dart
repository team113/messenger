// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller.dart';
import '../widget/call_title.dart';
import '../widget/round_button.dart';
import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/routes.dart';

/// Button in a [CallView].
///
/// Intended to be placed in a [Dock] to be reordered around.
abstract class CallButton {
  const CallButton(this.c);

  /// [CallController] owning this [CallButton], used for changing the state.
  final CallController c;

  /// Indicates whether this [CallButton] can be removed from the [Dock].
  bool get isRemovable => true;

  /// Returns a text-represented hint for this [CallButton].
  String get hint;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) =>
      other is CallButton && runtimeType == other.runtimeType;

  /// Builds the [Widget] representation of this [CallButton].
  Widget build({bool hinted = true});

  /// Returns a styled [RoundFloatingButton] with the provided parameters.
  Widget _common({
    required String asset,
    VoidCallback? onPressed,
    bool hinted = true,
    bool expanded = false,
    bool withBlur = false,
    Color color = const Color(0x794E5A78),
    double assetWidth = 60,
  }) {
    return RoundFloatingButton(
      asset: asset,
      assetWidth: assetWidth,
      color: color,
      hint: !expanded && hinted ? hint : null,
      text: expanded ? hint : null,
      withBlur: withBlur,
      onPressed: onPressed,
    );
  }
}

/// [CallButton] toggling a more panel.
class MoreButton extends CallButton {
  const MoreButton(CallController c) : super(c);

  @override
  bool get isRemovable => false;

  @override
  String get hint => 'btn_call_more'.l10n;

  @override
  Widget build({bool hinted = true}) {
    return _common(
      asset: 'more',
      hinted: hinted,
      onPressed: c.toggleMore,
    );
  }
}

/// [CallButton] toggling a local video.
class VideoButton extends CallButton {
  const VideoButton(CallController c) : super(c);

  @override
  String get hint {
    bool isVideo = c.videoState.value == LocalTrackState.enabled ||
        c.videoState.value == LocalTrackState.enabling;
    return isVideo ? 'btn_call_video_off'.l10n : 'btn_call_video_on'.l10n;
  }

  @override
  Widget build({bool hinted = true, bool blur = false}) {
    return Obx(() {
      bool isVideo = c.videoState.value == LocalTrackState.enabled ||
          c.videoState.value == LocalTrackState.enabling;
      return _common(
        asset: 'video_${isVideo ? 'on' : 'off'}',
        hinted: hinted,
        withBlur: blur,
        onPressed: c.toggleVideo,
      );
    });
  }
}

/// [CallButton] toggling a local audio.
class AudioButton extends CallButton {
  const AudioButton(CallController c) : super(c);

  @override
  String get hint {
    bool isAudio = c.audioState.value == LocalTrackState.enabled ||
        c.audioState.value == LocalTrackState.enabling;
    return isAudio ? 'btn_call_audio_off'.l10n : 'btn_call_audio_on'.l10n;
  }

  @override
  Widget build({bool hinted = true, bool blur = false}) {
    return Obx(() {
      bool isAudio = c.audioState.value == LocalTrackState.enabled ||
          c.audioState.value == LocalTrackState.enabling;
      return _common(
        asset: 'microphone_${isAudio ? 'on' : 'off'}',
        hinted: hinted,
        withBlur: blur,
        onPressed: c.toggleAudio,
      );
    });
  }
}

/// [CallButton] toggling a local screen-sharing.
class ScreenButton extends CallButton {
  const ScreenButton(CallController c) : super(c);

  @override
  String get hint {
    bool isScreen = c.screenShareState.value == LocalTrackState.enabled ||
        c.screenShareState.value == LocalTrackState.enabling;
    return isScreen ? 'btn_call_screen_off'.l10n : 'btn_call_screen_on'.l10n;
  }

  @override
  Widget build({bool hinted = true}) {
    return Obx(() {
      bool isScreen = c.screenShareState.value == LocalTrackState.enabled ||
          c.screenShareState.value == LocalTrackState.enabling;
      return _common(
        asset: 'screen_share_${isScreen ? 'off' : 'on'}',
        hinted: hinted,
        onPressed: () => c.toggleScreenShare(router.context!),
      );
    });
  }
}

/// [CallButton] toggling hand.
class HandButton extends CallButton {
  const HandButton(CallController c) : super(c);

  @override
  String get hint => c.me.isHandRaised.value
      ? 'btn_call_hand_down'.l10n
      : 'btn_call_hand_up'.l10n;

  @override
  Widget build({bool hinted = true}) {
    return Obx(() {
      return _common(
        asset: 'hand_${c.me.isHandRaised.value ? 'down' : 'up'}',
        hinted: hinted,
        onPressed: c.toggleHand,
      );
    });
  }
}

/// [CallButton] invoking the [CallController.openSettings].
class SettingsButton extends CallButton {
  const SettingsButton(CallController c) : super(c);

  @override
  String get hint => 'btn_call_settings'.l10n;

  @override
  Widget build({bool hinted = true}) {
    return _common(
      asset: 'settings_small',
      hinted: hinted,
      onPressed: () => c.openSettings(router.context!),
    );
  }
}

/// [CallButton] invoking the [CallController.openAddMember].
class ParticipantsButton extends CallButton {
  const ParticipantsButton(CallController c) : super(c);

  @override
  String get hint => 'btn_participants'.l10n;

  @override
  Widget build({bool hinted = true}) {
    return _common(
      asset: 'add_user_small',
      hinted: hinted,
      onPressed: () => c.openAddMember(router.context!),
    );
  }
}

/// [CallButton] toggling the remote video.
class RemoteVideoButton extends CallButton {
  const RemoteVideoButton(CallController c) : super(c);

  @override
  String get hint => c.isRemoteVideoEnabled.value
      ? 'btn_call_remote_video_off'.l10n
      : 'btn_call_remote_video_on'.l10n;

  @override
  Widget build({bool hinted = true}) {
    return Obx(() {
      return _common(
        asset: 'incoming_video_${c.isRemoteVideoEnabled.value ? 'on' : 'off'}',
        hinted: hinted,
        onPressed: c.toggleRemoteVideos,
      );
    });
  }
}

/// [CallButton] toggling the remote audio.
class RemoteAudioButton extends CallButton {
  const RemoteAudioButton(CallController c) : super(c);

  @override
  String get hint => c.isRemoteAudioEnabled.value
      ? 'btn_call_remote_audio_off'.l10n
      : 'btn_call_remote_audio_on'.l10n;

  @override
  Widget build({bool hinted = true}) {
    return Obx(() {
      return _common(
        asset: 'speaker_${c.isRemoteAudioEnabled.value ? 'on' : 'off'}',
        hinted: hinted,
        onPressed: c.toggleRemoteAudios,
      );
    });
  }
}

/// [CallButton] accepting a call without video.
class AcceptAudioButton extends CallButton {
  const AcceptAudioButton(CallController c) : super(c);

  @override
  String get hint => 'btn_call_answer_with_audio'.l10n;

  @override
  Widget build({bool hinted = true, bool expanded = false}) {
    return _common(
      asset: 'audio_call_start',
      assetWidth: 29,
      color: CallController.acceptColor,
      hinted: hinted,
      expanded: expanded,
      withBlur: expanded,
      onPressed: () => c.join(withVideo: false),
    );
  }
}

/// [RoundFloatingButton] accepting a call with video.
class AcceptVideoButton extends CallButton {
  const AcceptVideoButton(CallController c) : super(c);

  @override
  String get hint => 'btn_call_answer_with_video'.l10n;

  @override
  Widget build({bool hinted = true, bool expanded = false}) {
    return _common(
      asset: 'video_on',
      color: CallController.acceptColor,
      hinted: hinted,
      expanded: expanded,
      withBlur: expanded,
      onPressed: () => c.join(withVideo: true),
    );
  }
}

/// [RoundFloatingButton] declining a call.
class DeclineButton extends CallButton {
  const DeclineButton(CallController c) : super(c);

  @override
  String get hint => 'btn_call_decline'.l10n;

  @override
  Widget build({bool hinted = true, bool expanded = false}) {
    return _common(
      asset: 'call_end',
      color: CallController.endColor,
      hinted: hinted,
      expanded: expanded,
      withBlur: expanded,
      onPressed: c.decline,
    );
  }
}

/// [RoundFloatingButton] dropping a call.
class DropButton extends CallButton {
  const DropButton(CallController c) : super(c);

  @override
  String get hint => 'btn_call_end'.l10n;

  @override
  Widget build({bool hinted = true}) {
    return _common(
      asset: 'call_end',
      color: CallController.endColor,
      hinted: hinted,
      onPressed: c.drop,
    );
  }
}

/// [RoundFloatingButton] canceling an outgoing call.
class CancelButton extends CallButton {
  const CancelButton(CallController c) : super(c);

  @override
  String get hint => 'btn_call_cancel'.l10n;

  @override
  Widget build({bool hinted = true, bool blur = false}) {
    return _common(
      asset: 'call_end',
      color: CallController.endColor,
      hinted: hinted,
      withBlur: blur,
      onPressed: c.drop,
    );
  }
}

/// [CallButton] ending the call.
class EndCallButton extends CallButton {
  const EndCallButton(CallController c) : super(c);

  @override
  bool get isRemovable => false;

  @override
  String get hint => 'btn_call_end'.l10n;

  @override
  Widget build({bool hinted = true}) {
    return _common(
      asset: 'call_end',
      color: CallController.endColor,
      hinted: hinted,
      onPressed: c.drop,
    );
  }
}

/// [RoundFloatingButton] switching a speaker output.
class SpeakerButton extends CallButton {
  const SpeakerButton(CallController c) : super(c);

  @override
  String get hint => 'btn_call_toggle_speaker'.l10n;

  @override
  Widget build({bool hinted = true, bool blur = false}) {
    return Obx(() {
      return _common(
        asset: 'speaker_${c.speakerSwitched.value ? 'on' : 'off'}',
        hinted: hinted,
        withBlur: blur,
        onPressed: c.toggleSpeaker,
      );
    });
  }
}

/// [RoundFloatingButton] switching a local video stream.
class SwitchButton extends CallButton {
  const SwitchButton(CallController c) : super(c);

  @override
  String get hint => 'btn_call_switch_camera'.l10n;

  @override
  Widget build({bool hinted = true, bool blur = false}) {
    return Obx(() {
      return _common(
        asset: 'camera_${c.cameraSwitched.value ? 'front' : 'back'}',
        assetWidth: 28,
        hinted: hinted,
        withBlur: blur,
        onPressed: c.toggleSpeaker,
      );
    });
  }
}

/// Returns a [Column] consisting of the [child] with the provided
/// [description].
Widget withDescription(Widget child, Widget description) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      child,
      const SizedBox(height: 6),
      DefaultTextStyle(
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        child: description,
      ),
    ],
  );
}

/// Title call information.
Widget callTitle(CallController c) => Obx(
      () {
        bool isOutgoing =
            (c.outgoing || c.state.value == OngoingCallState.local) &&
                !c.started;
        bool withDots = c.state.value != OngoingCallState.active &&
            (c.state.value == OngoingCallState.joining || isOutgoing);
        String state = c.state.value == OngoingCallState.active
            ? c.duration.value.toString().split('.').first.padLeft(8, '0')
            : c.state.value == OngoingCallState.joining
                ? 'label_call_joining'.l10n
                : isOutgoing
                    ? 'label_call_calling'.l10n
                    : c.withVideo == true
                        ? 'label_video_call'.l10n
                        : 'label_audio_call'.l10n;
        return CallTitle(
          c.me.id.userId,
          chat: c.chat.value?.chat.value,
          title: c.chat.value?.title.value,
          avatar: c.chat.value?.avatar.value,
          state: state,
          withDots: withDots,
        );
      },
    );
