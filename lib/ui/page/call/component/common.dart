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
import '/ui/widget/svg/svg.dart';

/// Button used in call's bottom panel.
abstract class CallButton {
  CallButton(this.c);

  /// CallController of this button.
  final CallController c;

  /// Indicates that this button must be hide or not.
  bool hide = false;

  /// Indicates whether this [CallButton] can be removed from the
  /// [ReorderableDock] it's placed in, if any.
  bool get isRemovable => true;

  /// Returns a text-represented hint for this [CallButton].
  String get hint;

  /// Builds the [Widget] representation of this [CallButton].
  Widget build(BuildContext context, bool minimized, {bool small = false});

  /// Return button widget.
  Widget _button({
    IconData? icon,
    String? asset,
    VoidCallback? onPressed,
    Color? color,
    bool minimized = false,
    bool small = false,
  }) =>
      Obx(
        () => IgnorePointer(
          ignoring: c.draggableButton.value != null,
          child: RoundFloatingButton(
            onPressed: onPressed,
            color: color ?? const Color.fromARGB(122, 78, 90, 120),
            scale: !small ? 1 : (c.buttonSize.value / 60),
            hint: (small &&
                    c.draggableButton.value == null &&
                    c.hideHint.value == false)
                ? hint
                : null,
            withText: !small,
            children: [
              if (icon != null)
                Icon(icon, color: Colors.white)
              else if (asset != null)
                SvgLoader.asset(
                  'assets/icons/$asset.svg',
                  width: 60,
                ),
            ],
          ),
        ),
      );
}

/// [CallButton] toggling a local video.
class VideoCallButton extends CallButton {
  VideoCallButton(CallController c) : super(c);

  @override
  String get hint {
    bool isVideo = c.videoState.value == LocalTrackState.enabled ||
        c.videoState.value == LocalTrackState.enabling;
    return isVideo ? 'btn_call_video_off'.tr : 'btn_call_video_on'.tr;
  }

  @override
  Widget build(BuildContext context, bool minimized, {bool small = false}) =>
      Obx(() {
        bool isVideo = c.videoState.value == LocalTrackState.enabled ||
            c.videoState.value == LocalTrackState.enabling;

        return _button(
          asset: 'video_${isVideo ? 'on' : 'off'}',
          onPressed: c.toggleVideo,
          minimized: minimized,
          small: small,
        );
      });
}

/// [CallButton] ends call.
class EndCallButton extends CallButton {
  EndCallButton(CallController c) : super(c);

  @override
  bool get isRemovable => false;

  @override
  String get hint => 'btn_call_end'.tr;

  @override
  Widget build(BuildContext context, bool minimized, {bool small = false}) =>
      _button(
        asset: 'call_end',
        onPressed: c.drop,
        color: CallController.endColor,
        minimized: minimized,
        small: small,
      );
}

/// [CallButton] toggling a more panel.
class MoreCallButton extends CallButton {
  MoreCallButton(CallController c) : super(c);

  @override
  bool get isRemovable => false;

  @override
  String get hint => 'btn_call_more'.tr;

  @override
  Widget build(BuildContext context, bool minimized, {bool small = false}) =>
      _button(
        asset: 'more',
        onPressed: c.toggleMore,
        minimized: minimized,
        small: small,
      );
}

/// [CallButton] toggling a local audio.
class AudioCallButton extends CallButton {
  AudioCallButton(CallController c) : super(c);

  @override
  String get hint {
    bool isAudio = c.audioState.value == LocalTrackState.enabled ||
        c.audioState.value == LocalTrackState.enabling;
    return isAudio ? 'btn_call_audio_off'.tr : 'btn_call_audio_on'.tr;
  }

  @override
  Widget build(BuildContext context, bool minimized, {bool small = false}) =>
      Obx(() {
        bool isAudio = c.audioState.value == LocalTrackState.enabled ||
            c.audioState.value == LocalTrackState.enabling;

        return _button(
          asset: 'microphone_${isAudio ? 'on' : 'off'}',
          onPressed: c.toggleAudio,
          minimized: minimized,
          small: small,
        );
      });
}

/// [CallButton] toggling a share screen.
class ScreenCallButton extends CallButton {
  ScreenCallButton(CallController c) : super(c);

  @override
  String get hint {
    bool isScreen = c.screenShareState.value == LocalTrackState.enabled ||
        c.screenShareState.value == LocalTrackState.enabling;
    return isScreen ? 'btn_call_screen_off'.tr : 'btn_call_screen_on'.tr;
  }

  @override
  Widget build(BuildContext context, bool minimized, {bool small = false}) =>
      Obx(() {
        bool isScreen = c.screenShareState.value == LocalTrackState.enabled ||
            c.screenShareState.value == LocalTrackState.enabling;

        return _button(
          asset: 'screen_share_${isScreen ? 'off' : 'on'}',
          onPressed: c.toggleScreenShare,
          minimized: minimized,
          small: small,
        );
      });
}

/// [CallButton] toggling hand.
class HandCallButton extends CallButton {
  HandCallButton(CallController c) : super(c);

  @override
  String get hint =>
      c.isHandRaised.value ? 'btn_call_hand_down'.tr : 'btn_call_hand_up'.tr;

  @override
  Widget build(BuildContext context, bool minimized, {bool small = false}) =>
      Obx(() => _button(
            asset: 'hand_${c.isHandRaised.value ? 'down' : 'up'}',
            onPressed: c.toggleHand,
            minimized: minimized,
            small: small,
          ));
}

/// [CallButton] opens settings panel.
class SettingsCallButton extends CallButton {
  SettingsCallButton(CallController c) : super(c);

  @override
  String get hint => 'btn_call_settings'.tr;

  @override
  Widget build(BuildContext context, bool minimized, {bool small = false}) =>
      _button(
        asset: 'settings2',
        onPressed: () => c.openSettings(context),
        minimized: minimized,
        small: small,
      );
}

/// [CallButton] adds member to call.
class AddMemberCallButton extends CallButton {
  AddMemberCallButton(CallController c) : super(c);

  @override
  String get hint => 'btn_add_participant'.tr;

  @override
  Widget build(BuildContext context, bool minimized, {bool small = false}) =>
      _button(
        asset: 'add_user2',
        onPressed: () => c.openAddMember(context),
        minimized: minimized,
        small: small,
      );
}

/// [CallButton] toggling fullscreen.
class FullscreenCallButton extends CallButton {
  FullscreenCallButton(CallController c) : super(c);

  @override
  String get hint =>
      c.fullscreen.value ? 'btn_fullscreen_exit'.tr : 'btn_fullscreen_enter'.tr;

  @override
  Widget build(BuildContext context, bool minimized, {bool small = false}) =>
      Obx(() => _button(
            asset: 'fullscreen_${c.fullscreen.value ? 'exit' : 'enter'}',
            onPressed: c.toggleFullscreen,
            minimized: minimized,
            small: small,
          ));
}

/// [CallButton] toggling remote video.
class DisableRemoteVideoCallButton extends CallButton {
  DisableRemoteVideoCallButton(CallController c) : super(c);

  @override
  String get hint => c.isRemoteVideoEnabled.value
      ? 'btn_call_disable_video'.tr
      : 'btn_call_enable_video'.tr;

  @override
  Widget build(BuildContext context, bool minimized, {bool small = false}) =>
      Obx(() => _button(
            asset:
                'incoming_video_${c.isRemoteVideoEnabled.value ? 'on' : 'off'}',
            onPressed: c.toggleRemoteVideos,
            minimized: minimized,
            small: small,
          ));
}

/// [CallButton] toggling remote audio.
class DisableRemoteAudioCallButton extends CallButton {
  DisableRemoteAudioCallButton(CallController c) : super(c);

  @override
  String get hint => c.isRemoteAudioEnabled.value
      ? 'btn_call_disable_incoming_audio'.tr
      : 'btn_call_enable_incoming_audio'.tr;

  @override
  Widget build(BuildContext context, bool minimized, {bool small = false}) =>
      Obx(() => _button(
            asset: 'speaker_${c.isRemoteAudioEnabled.value ? 'on' : 'off'}',
            onPressed: c.toggleRemoteAudios,
            minimized: minimized,
            small: small,
          ));
}

/// [RoundFloatingButton] accepting a call without video.
Widget acceptAudioButton(CallController c) => RoundFloatingButton(
      onPressed: () => c.join(withVideo: false),
      text: 'btn_call_answer_with_audio'.tr,
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
      text: 'btn_call_answer_with_video'.tr,
      color: CallController.acceptColor,
      withBlur: true,
      children: [SvgLoader.asset('assets/icons/video_on.svg', width: 60)],
    );

/// [RoundFloatingButton] declining a call.
Widget declineButton(CallController c) => RoundFloatingButton(
      onPressed: c.decline,
      text: 'btn_call_decline'.tr,
      color: CallController.endColor,
      withBlur: true,
      children: [SvgLoader.asset('assets/icons/call_end.svg', width: 60)],
    );

/// [RoundFloatingButton] dropping a call.
Widget dropButton(CallController c, [double? scale]) => RoundFloatingButton(
      hint: 'btn_call_end'.tr,
      onPressed: c.drop,
      color: CallController.endColor,
      scale: scale ?? 1,
      children: [SvgLoader.asset('assets/icons/call_end.svg', width: 60)],
    );

/// [RoundFloatingButton] canceling an outgoing call.
Widget cancelButton(CallController c) => RoundFloatingButton(
      hint: 'btn_call_cancel'.tr,
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
        hint: isVideo ? 'btn_call_video_off'.tr : 'btn_call_video_on'.tr,
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
        hint: isAudio ? 'btn_call_audio_off'.tr : 'btn_call_audio_on'.tr,
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
      hint: 'btn_call_toggle_speaker'.tr,
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
        hint: 'btn_call_switch_camera'.tr,
        onPressed: c.switchCamera,
        scale: scale ?? 1,
        withBlur: c.state.value != OngoingCallState.active &&
            c.state.value != OngoingCallState.joining,
        children: [
          SvgLoader.asset(
            'assets/icons/camera_${c.cameraSwitched.value ? 'front' : 'back'}.svg',
            width: 28,
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
              hint:
                  isScreen ? 'btn_call_screen_off'.tr : 'btn_call_screen_on'.tr,
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
                ? 'label_call_joining'.tr
                : isOutgoing
                    ? 'label_call_calling'.tr
                    : c.withVideo == true
                        ? 'label_video_call'.tr
                        : 'label_audio_call'.tr;
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
