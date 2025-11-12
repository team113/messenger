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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller.dart';
import '../widget/call_button.dart';
import '../widget/call_title.dart';
import '../widget/dock.dart';
import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/widget/svg/svg.dart';
import '/util/media_utils.dart';
import '/util/platform_utils.dart';

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
  Widget build({bool hinted = true, bool big = false, bool expanded = false});
}

/// [CallButton] toggling a more panel.
class MoreButton extends CallButton {
  const MoreButton(super.c);

  @override
  bool get isRemovable => false;

  @override
  String get hint => 'btn_call_more'.l10n;

  @override
  Widget build({bool hinted = true, bool big = false, bool expanded = false}) {
    return CallButtonWidget(
      hint: hint,
      asset: SvgIcons.callMore,
      hinted: hinted,
      expanded: expanded,
      big: big,
      constrained: c.isMobile,
      onPressed: c.toggleMore,
    );
  }
}

/// [CallButton] toggling a local video.
class VideoButton extends CallButton {
  const VideoButton(super.c);

  @override
  String get hint {
    bool isVideo =
        c.videoState.value == LocalTrackState.enabled ||
        c.videoState.value == LocalTrackState.enabling;

    return c.isMobile
        ? isVideo
              ? 'btn_call_video_off_desc'.l10n
              : 'btn_call_video_on_desc'.l10n
        : isVideo
        ? 'btn_call_video_off'.l10n
        : 'btn_call_video_on'.l10n;
  }

  @override
  Widget build({
    bool hinted = true,
    bool big = false,
    bool expanded = false,
    bool opaque = false,
  }) {
    return Obx(() {
      bool isVideo =
          c.videoState.value == LocalTrackState.enabled ||
          c.videoState.value == LocalTrackState.enabling;
      return CallButtonWidget(
        hint: hint,
        asset: isVideo ? SvgIcons.callVideoOn : SvgIcons.callVideoOff,
        hinted: hinted,
        expanded: expanded,
        big: big,
        constrained: c.isMobile,
        opaque: opaque,
        onPressed: c.toggleVideo,
      );
    });
  }
}

/// [CallButton] toggling a local audio.
class AudioButton extends CallButton {
  const AudioButton(super.c);

  @override
  String get hint {
    bool isAudio =
        c.audioState.value == LocalTrackState.enabled ||
        c.audioState.value == LocalTrackState.enabling;

    return c.isMobile
        ? isAudio
              ? 'btn_call_audio_off_desc'.l10n
              : 'btn_call_audio_on_desc'.l10n
        : isAudio
        ? 'btn_call_audio_off'.l10n
        : 'btn_call_audio_on'.l10n;
  }

  @override
  Widget build({
    bool hinted = true,
    bool big = false,
    bool expanded = false,
    bool opaque = false,
  }) {
    return Obx(() {
      bool isAudio =
          c.audioState.value == LocalTrackState.enabled ||
          c.audioState.value == LocalTrackState.enabling;
      return CallButtonWidget(
        hint: hint,
        asset: isAudio ? SvgIcons.callMicrophoneOn : SvgIcons.callMicrophoneOff,
        hinted: hinted,
        expanded: expanded,
        big: big,
        constrained: c.isMobile,
        opaque: opaque,
        onPressed: c.toggleAudio,
      );
    });
  }
}

/// [CallButton] toggling a local screen-sharing.
class ScreenButton extends CallButton {
  const ScreenButton(super.c);

  @override
  String get hint {
    bool isScreen =
        c.screenShareState.value == LocalTrackState.enabled ||
        c.screenShareState.value == LocalTrackState.enabling;

    return c.isMobile
        ? isScreen
              ? 'btn_call_screen_off_desc'.l10n
              : 'btn_call_screen_on_desc'.l10n
        : isScreen
        ? 'btn_call_screen_off'.l10n
        : 'btn_call_screen_on'.l10n;
  }

  @override
  Widget build({bool hinted = true, bool big = false, bool expanded = false}) {
    return Obx(() {
      bool isScreen =
          c.screenShareState.value == LocalTrackState.enabled ||
          c.screenShareState.value == LocalTrackState.enabling;
      return CallButtonWidget(
        hint: hint,
        asset: isScreen
            ? SvgIcons.callScreenShareOff
            : SvgIcons.callScreenShareOn,
        hinted: hinted,
        expanded: expanded,
        big: big,
        constrained: c.isMobile,
        onPressed: () => c.toggleScreenShare(router.context!),
      );
    });
  }
}

/// [CallButton] toggling hand.
class HandButton extends CallButton {
  const HandButton(super.c);

  @override
  String get hint => c.isMobile
      ? c.me.isHandRaised.value
            ? 'btn_call_hand_down_desc'.l10n
            : 'btn_call_hand_up_desc'.l10n
      : c.me.isHandRaised.value
      ? 'btn_call_hand_down'.l10n
      : 'btn_call_hand_up'.l10n;

  @override
  Widget build({bool hinted = true, bool big = false, bool expanded = false}) {
    return Obx(() {
      return CallButtonWidget(
        hint: hint,
        asset: c.me.isHandRaised.value
            ? SvgIcons.callHandDown
            : SvgIcons.callHandUp,
        hinted: hinted,
        expanded: expanded,
        big: big,
        constrained: c.isMobile,
        onPressed: c.toggleHand,
      );
    });
  }
}

/// [CallButton] invoking the [CallController.openSettings].
class SettingsButton extends CallButton {
  const SettingsButton(super.c);

  @override
  String get hint => 'btn_call_settings'.l10n;

  @override
  Widget build({bool hinted = true, bool big = false, bool expanded = false}) {
    return CallButtonWidget(
      hint: hint,
      asset: SvgIcons.callSettings,
      hinted: hinted,
      expanded: expanded,
      big: big,
      constrained: c.isMobile,
      onPressed: () => c.openSettings(router.context!),
    );
  }
}

/// [CallButton] invoking the [CallController.openAddMember].
class ParticipantsButton extends CallButton {
  const ParticipantsButton(super.c);

  @override
  String get hint => c.isGroup
      ? c.isMobile
            ? 'btn_participants_desc'.l10n
            : 'btn_participants'.l10n
      : c.isMobile
      ? 'btn_add_participant_desc'.l10n
      : 'btn_add_participant'.l10n;

  @override
  Widget build({bool hinted = true, bool big = false, bool expanded = false}) {
    return CallButtonWidget(
      hint: hint,
      asset: SvgIcons.callParticipants,
      offset: const Offset(2, 0),
      hinted: hinted,
      expanded: expanded,
      big: big,
      constrained: c.isMobile,
      onPressed: c.isMonolog ? null : () => c.openAddMember(router.context!),
    );
  }
}

/// [CallButton] toggling the remote video.
class RemoteVideoButton extends CallButton {
  const RemoteVideoButton(super.c);

  @override
  String get hint => c.isMobile
      ? c.isRemoteVideoEnabled.value
            ? 'btn_call_remote_video_off_desc'.l10n
            : 'btn_call_remote_video_on_desc'.l10n
      : c.isRemoteVideoEnabled.value
      ? 'btn_call_remote_video_off'.l10n
      : 'btn_call_remote_video_on'.l10n;

  @override
  Widget build({bool hinted = true, bool big = false, bool expanded = false}) {
    return Obx(() {
      return CallButtonWidget(
        hint: hint,
        asset: c.isRemoteVideoEnabled.value
            ? SvgIcons.callIncomingVideoOn
            : SvgIcons.callIncomingVideoOff,
        hinted: hinted,
        expanded: expanded,
        big: big,
        constrained: c.isMobile,
        onPressed: c.toggleRemoteVideos,
      );
    });
  }
}

/// [CallButton] toggling the remote audio.
class RemoteAudioButton extends CallButton {
  const RemoteAudioButton(super.c);

  @override
  String get hint => c.isMobile
      ? c.isRemoteAudioEnabled.value
            ? 'btn_call_remote_audio_off_desc'.l10n
            : 'btn_call_remote_audio_on_desc'.l10n
      : c.isRemoteAudioEnabled.value
      ? 'btn_call_remote_audio_off'.l10n
      : 'btn_call_remote_audio_on'.l10n;

  @override
  Widget build({bool hinted = true, bool big = false, bool expanded = false}) {
    return Obx(() {
      return CallButtonWidget(
        hint: hint,
        asset: c.isRemoteAudioEnabled.value
            ? SvgIcons.callIncomingAudioOn
            : SvgIcons.callIncomingAudioOff,
        hinted: hinted,
        expanded: expanded,
        big: big,
        constrained: c.isMobile,
        onPressed: c.toggleRemoteAudios,
      );
    });
  }
}

/// [CallButton] accepting a call without video.
class AcceptAudioButton extends CallButton {
  const AcceptAudioButton(super.c, {this.highlight = false});

  /// Indicator whether this [AcceptAudioButton] should be highlighted.
  final bool highlight;

  @override
  String get hint => 'btn_call_answer_with_audio'.l10n;

  @override
  Widget build({bool hinted = true, bool expanded = false, bool big = false}) {
    final style = Theme.of(router.context!).style;

    return CallButtonWidget(
      hint: hint,
      asset: expanded
          ? SvgIcons.acceptAudioCall
          : SvgIcons.acceptAudioCallSmall,
      color: style.colors.accept,
      hinted: hinted,
      expanded: expanded,
      big: big,
      constrained: c.isMobile,
      border: highlight
          ? Border.all(color: style.colors.onPrimaryOpacity50, width: 1.5)
          : null,
      onPressed: () => c.join(withVideo: false),
    );
  }
}

/// [CallButton] accepting a call with video.
class AcceptVideoButton extends CallButton {
  const AcceptVideoButton(super.c, {this.highlight = false});

  /// Indicator whether this [AcceptVideoButton] should be highlighted.
  final bool highlight;

  @override
  String get hint => 'btn_call_answer_with_video'.l10n;

  @override
  Widget build({bool hinted = true, bool expanded = false, bool big = false}) {
    final style = Theme.of(router.context!).style;

    return CallButtonWidget(
      hint: hint,
      asset: SvgIcons.callVideoOn,
      color: style.colors.accept,
      hinted: hinted,
      expanded: expanded,
      big: big,
      constrained: c.isMobile,
      border: highlight
          ? Border.all(color: style.colors.onPrimaryOpacity50, width: 1.5)
          : null,
      onPressed: () => c.join(withVideo: true),
    );
  }
}

/// [CallButton] declining a call.
class DeclineButton extends CallButton {
  const DeclineButton(super.c);

  @override
  String get hint => 'btn_call_decline'.l10n;

  @override
  Widget build({bool hinted = true, bool expanded = false, bool big = false}) {
    final style = Theme.of(router.context!).style;

    return CallButtonWidget(
      hint: hint,
      asset: SvgIcons.callEndBig,
      color: style.colors.declineOpacity50,
      hinted: hinted,
      expanded: expanded,
      big: big,
      constrained: c.isMobile,
      onPressed: c.decline,
    );
  }
}

/// [CallButton] ending the call.
class EndCallButton extends CallButton {
  const EndCallButton(super.c);

  @override
  bool get isRemovable => false;

  @override
  String get hint =>
      c.isMobile ? 'btn_call_end_desc'.l10n : 'btn_call_end'.l10n;

  @override
  Widget build({
    bool hinted = true,
    bool big = false,
    bool expanded = false,
    bool opaque = false,
  }) {
    final style = Theme.of(router.context!).style;

    return CallButtonWidget(
      asset: SvgIcons.callEndBig,
      hint: hint,
      color: style.colors.declineOpacity50,
      hinted: hinted,
      expanded: expanded,
      big: big,
      constrained: c.isMobile,
      opaque: opaque,
      onPressed: c.drop,
    );
  }
}

/// [CallButton] switching a speaker output.
class SpeakerButton extends CallButton {
  const SpeakerButton(super.c);

  @override
  String get hint => c.isMobile
      ? 'btn_call_toggle_speaker_desc'.l10n
      : 'btn_call_toggle_speaker'.l10n;

  @override
  Widget build({
    bool hinted = true,
    bool big = false,
    bool expanded = false,
    bool opaque = false,
  }) {
    Widget button(SvgData asset, void Function()? onPressed) {
      return CallButtonWidget(
        hint: hint,
        asset: asset,
        hinted: hinted,
        expanded: expanded,
        big: big,
        constrained: c.isMobile,
        opaque: opaque,
        onPressed: onPressed,
      );
    }

    // Web seems to decide for itself the output device source on mobile.
    if (PlatformUtils.isMobile && PlatformUtils.isWeb) {
      return button(SvgIcons.callIncomingAudioOn, null);
    } else {
      return Obx(() {
        final SvgData asset = switch (c.speaker) {
          AudioSpeakerKind.earpiece => SvgIcons.callAudioEarpiece,
          AudioSpeakerKind.speaker => SvgIcons.callSpeakerOn,
          AudioSpeakerKind.headphones => SvgIcons.callHeadphones,
        };

        return button(asset, c.toggleSpeaker);
      });
    }
  }
}

/// [CallButton] switching a local video stream.
class SwitchButton extends CallButton {
  const SwitchButton(super.c);

  @override
  String get hint => c.isMobile
      ? 'btn_call_switch_camera_desc'.l10n
      : 'btn_call_switch_camera'.l10n;

  @override
  Widget build({
    bool hinted = true,
    bool big = false,
    bool expanded = false,
    bool opaque = false,
  }) {
    return Obx(() {
      return CallButtonWidget(
        hint: hint,
        asset: c.cameraSwitched.value
            ? SvgIcons.callCameraFront
            : SvgIcons.callCameraBack,
        hinted: hinted,
        expanded: expanded,
        big: big,
        constrained: c.isMobile,
        opaque: opaque,
        onPressed: c.switchCamera,
      );
    });
  }
}

/// Returns a [Widget] building the title call information.
Widget callTitle(CallController c) {
  return Obx(() {
    final bool isOutgoing =
        (c.outgoing || c.state.value == OngoingCallState.local) && !c.started;
    final bool isDialog = c.chat.value?.chat.value.isDialog == true;
    final bool withDots =
        c.state.value != OngoingCallState.active &&
        (c.state.value == OngoingCallState.joining || isOutgoing);

    final Map<String, dynamic> args = {'by': 'x'};
    if (!isOutgoing && !isDialog) {
      args['by'] = c.callerName;
    }

    final String state = c.state.value == OngoingCallState.active
        ? c.duration.value.toString().split('.').first.padLeft(8, '0')
        : c.state.value == OngoingCallState.joining
        ? 'label_call_joining'.l10n
        : isOutgoing
        ? 'label_call_calling'.l10n
        : c.withVideo == true
        ? 'label_video_call'.l10nfmt(args)
        : 'label_audio_call'.l10nfmt(args);

    return CallTitle(
      title: c.chat.value?.title(),
      state: state,
      withDots: withDots,
    );
  });
}
