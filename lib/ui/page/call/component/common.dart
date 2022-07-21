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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller.dart';
import '../widget/call_title.dart';
import '../widget/round_button.dart';
import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/ui/widget/svg/svg.dart';

/// [RoundFloatingButton] accepting a call without video.
Widget acceptAudioButton(CallController c) => RoundFloatingButton(
      onPressed: () => c.join(withVideo: false),
      text: 'btn_call_answer_with_audio'.l10n,
      color: CallController.acceptColor,
      withBlur: true,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Center(
            child:
                SvgLoader.asset('assets/icons/audio_call_start.svg', width: 29),
          ),
        )
      ],
    );

/// [RoundFloatingButton] accepting a call with video.
Widget acceptVideoButton(CallController c) => RoundFloatingButton(
      onPressed: () => c.join(withVideo: true),
      text: 'btn_call_answer_with_video'.l10n,
      color: CallController.acceptColor,
      withBlur: true,
      children: [SvgLoader.asset('assets/icons/video_on.svg', width: 60)],
    );

/// [RoundFloatingButton] declining a call.
Widget declineButton(CallController c) => RoundFloatingButton(
      onPressed: c.decline,
      text: 'btn_call_decline'.l10n,
      color: CallController.endColor,
      withBlur: true,
      children: [SvgLoader.asset('assets/icons/call_end.svg', width: 60)],
    );

/// [RoundFloatingButton] dropping a call.
Widget dropButton(CallController c, [double? scale]) => RoundFloatingButton(
      hint: 'btn_call_end'.l10n,
      onPressed: c.drop,
      color: CallController.endColor,
      scale: scale ?? 1,
      children: [SvgLoader.asset('assets/icons/call_end.svg', width: 60)],
    );

/// [RoundFloatingButton] canceling an outgoing call.
Widget cancelButton(CallController c) => RoundFloatingButton(
      hint: 'btn_call_cancel'.l10n,
      onPressed: c.drop,
      color: CallController.endColor,
      withBlur: true,
      children: [SvgLoader.asset('assets/icons/call_end.svg', width: 60)],
    );

/// [RoundFloatingButton] toggling a local video.
Widget videoButton(CallController c, [double? scale]) => Obx(() {
      bool isVideo = c.videoState.value == LocalTrackState.enabled ||
          c.videoState.value == LocalTrackState.enabling;
      return RoundFloatingButton(
        hint: isVideo ? 'btn_call_video_off'.l10n : 'btn_call_video_on'.l10n,
        onPressed: c.toggleVideo,
        scale: scale ?? 1,
        withBlur: c.state.value != OngoingCallState.active &&
            c.state.value != OngoingCallState.joining,
        children: [
          SvgLoader.asset(
            'assets/icons/video_${isVideo ? 'on' : 'off'}.svg',
            width: 60,
          ),
        ],
      );
    });

/// [RoundFloatingButton] toggling a local audio.
Widget audioButton(CallController c, [double? scale]) => Obx(() {
      bool isAudio = c.audioState.value == LocalTrackState.enabled ||
          c.audioState.value == LocalTrackState.enabling;
      return RoundFloatingButton(
        hint: isAudio ? 'btn_call_audio_off'.l10n : 'btn_call_audio_on'.l10n,
        onPressed: c.toggleAudio,
        scale: scale ?? 1,
        withBlur: c.state.value != OngoingCallState.active &&
            c.state.value != OngoingCallState.joining,
        children: [
          SvgLoader.asset(
            'assets/icons/microphone_${isAudio ? 'on' : 'off'}.svg',
            width: 60,
          ),
        ],
      );
    });

/// [RoundFloatingButton] switching a speaker output.
Widget speakerButton(CallController c, [double? scale]) => RoundFloatingButton(
      hint: 'btn_call_toggle_speaker'.l10n,
      onPressed: c.toggleSpeaker,
      scale: scale ?? 1,
      withBlur: c.state.value != OngoingCallState.active &&
          c.state.value != OngoingCallState.joining,
      children: [
        SvgLoader.asset(
          'assets/icons/speaker_${c.speakerSwitched.value ? 'on' : 'off'}.svg',
          width: 60,
        ),
      ],
    );

/// [RoundFloatingButton] switching a local video stream.
Widget switchButton(CallController c, [double? scale]) => Obx(
      () => RoundFloatingButton(
        hint: 'btn_call_switch_camera'.l10n,
        onPressed: c.switchCamera,
        scale: scale ?? 1,
        withBlur: c.state.value != OngoingCallState.active &&
            c.state.value != OngoingCallState.joining,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: SvgLoader.asset(
                'assets/icons/camera_${c.cameraSwitched.value ? 'front' : 'back'}.svg',
                width: 28,
              ),
            ),
          )
        ],
      ),
    );

/// [RoundFloatingButton] toggling a local screen-sharing.
Widget screenButton(CallController c, [double? scale]) => Obx(
      () {
        bool isScreen = c.screenShareState.value == LocalTrackState.enabled ||
            c.screenShareState.value == LocalTrackState.enabling;
        return Stack(
          alignment: Alignment.center,
          children: [
            RoundFloatingButton(
              hint: isScreen
                  ? 'btn_call_screen_off'.l10n
                  : 'btn_call_screen_on'.l10n,
              onPressed: c.toggleScreenShare,
              scale: scale ?? 1,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SvgLoader.asset(
                    'assets/icons/screen_share_${isScreen ? 'off' : 'on'}.svg',
                    width: 60,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

/// [RoundFloatingButton] raising a hand.
Widget handButton(CallController c, [double? scale]) => Obx(
      () => RoundFloatingButton(
        hint: c.isHandRaised.value
            ? 'btn_call_hand_down'.l10n
            : 'btn_call_hand_up'.l10n,
        onPressed: c.toggleHand,
        scale: scale ?? 1,
        children: [
          SvgLoader.asset(
            'assets/icons/hand_${c.isHandRaised.value ? 'down' : 'up'}.svg',
            width: 60,
          )
        ],
      ),
    );

/// [RoundFloatingButton] invoking the [CallController.openAddMember].
Widget addParticipantButton(
  CallController c,
  BuildContext context, [
  double? scale,
]) =>
    withDescription(
      RoundFloatingButton(
        onPressed: () => c.openAddMember(context),
        scale: scale ?? 1,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: SvgLoader.asset(
              'assets/icons/add_user_small.svg',
              width: 60,
            ),
          )
        ],
      ),
      Text('btn_add_participant_desc'.l10n),
    );

/// [RoundFloatingButton] disabling the remote video.
Widget disableVideo(CallController c, [double? scale]) => Obx(
      () => withDescription(
        RoundFloatingButton(
          onPressed: c.toggleRemoteVideos,
          scale: scale ?? 1,
          children: [
            SvgLoader.asset(
              'assets/icons/incoming_video_${c.isRemoteVideoEnabled.value ? 'on' : 'off'}.svg',
              width: 60,
            )
          ],
        ),
        Text(c.isRemoteVideoEnabled.value
            ? 'btn_call_remote_video_off_desc'.l10n
            : 'btn_call_remote_video_on_desc'.l10n),
      ),
    );

/// [RoundFloatingButton] disabling the remote audio.
Widget disableAudio(CallController c, [double? scale]) => Obx(
      () => withDescription(
        RoundFloatingButton(
          onPressed: c.toggleRemoteAudios,
          scale: scale ?? 1,
          children: [
            SvgLoader.asset(
              'assets/icons/speaker_${c.isRemoteAudioEnabled.value ? 'on' : 'off'}.svg',
              width: 60,
            )
          ],
        ),
        Text(c.isRemoteAudioEnabled.value
            ? 'btn_call_remote_audio_off_desc'.l10n
            : 'btn_call_remote_audio_on_desc'.l10n),
      ),
    );

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
          c.me,
          chat: c.chat.value?.chat.value,
          title: c.chat.value?.title.value,
          avatar: c.chat.value?.avatar.value,
          state: state,
          withDots: withDots,
        );
      },
    );
