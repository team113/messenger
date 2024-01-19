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

import 'package:flutter/material.dart';

import 'svg.dart';

/// Data of a SVG to display in [SvgImage].
class SvgData {
  const SvgData(
    this.asset, {
    this.width,
    this.height,
  });

  /// Asset of the SVG.
  final String asset;

  /// Width of the SVG.
  final double? width;

  /// Height of the SVG.
  final double? height;
}

/// [SvgImage.icon] wrapper.
class SvgIcon extends StatelessWidget {
  const SvgIcon(this.data, {super.key, this.width, this.height});

  /// [SvgData] to pass to the [SvgImage].
  final SvgData data;

  /// Optional width to display [data] of.
  final double? width;

  /// Optional height to display [data] of.
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SvgImage.icon(data, width: width, height: height);
  }
}

/// [SvgData]s of the SVG icons available.
class SvgIcons {
  static const SvgData chat = SvgData(
    'assets/icons/chat.svg',
    width: 21.39,
    height: 22.63,
  );

  static const SvgData chatAudioCall = SvgData(
    'assets/icons/chat_audio_call.svg',
    width: 21,
    height: 21.02,
  );

  static const SvgData chatAudioCallDisabled = SvgData(
    'assets/icons/chat_audio_call_disabled.svg',
    width: 21,
    height: 21.02,
  );

  static const SvgData chatVideoCall = SvgData(
    'assets/icons/chat_video_call.svg',
    width: 27.71,
    height: 19,
  );

  static const SvgData chatVideoCallDisabled = SvgData(
    'assets/icons/chat_video_call_disabled.svg',
    width: 27.71,
    height: 19,
  );

  static const SvgData callEnd = SvgData(
    'assets/icons/call_end.svg',
    width: 21.11,
    height: 8.1,
  );

  static const SvgData callEndSmall = SvgData(
    'assets/icons/call_end_small.svg',
    width: 14.78,
    height: 5.67,
  );

  static const SvgData callStart = SvgData(
    'assets/icons/call_start.svg',
    width: 15.98,
    height: 16.02,
  );

  static const SvgData callStartSmall = SvgData(
    'assets/icons/call_start_small.svg',
    width: 9.99,
    height: 10,
  );

  static const SvgData home = SvgData(
    'assets/icons/home.svg',
    width: 21.43,
    height: 21,
  );

  static const SvgData shareThick = SvgData(
    'assets/icons/share_thick.svg',
    width: 17.57,
    height: 18.31,
  );

  static const SvgData copyThick = SvgData(
    'assets/icons/copy_thick.svg',
    width: 16.18,
    height: 18.8,
  );

  static const SvgData search = SvgData(
    'assets/icons/search.svg',
    width: 17.76,
    height: 17.77,
  );

  static const SvgData closePrimary = SvgData(
    'assets/icons/close_primary.svg',
    width: 15,
    height: 15,
  );

  static const SvgData closeSmallPrimary = SvgData(
    'assets/icons/close_small_primary.svg',
    width: 10.4,
    height: 10.4,
  );

  static const SvgData closeSmall = SvgData(
    'assets/icons/close_small_white.svg',
    width: 10.4,
    height: 10.4,
  );

  static const SvgData searchExit = SvgData(
    'assets/icons/search_exit.svg',
    width: 11,
    height: 11,
  );

  static const SvgData chatsSwitch = SvgData(
    'assets/icons/chats_switch.svg',
    width: 27.01,
    height: 23.36,
  );

  static const SvgData contactsSwitch = SvgData(
    'assets/icons/contacts_switch.svg',
    width: 27.01,
    height: 23.36,
  );

  static const SvgData register = SvgData(
    'assets/icons/register.svg',
    width: 23,
    height: 23,
  );

  static const SvgData password = SvgData(
    'assets/icons/password.svg',
    width: 19,
    height: 21,
  );

  static const SvgData passwordSmall = SvgData(
    'assets/icons/password_small.svg',
    width: 17.1,
    height: 19,
  );

  static const SvgData passwordSmallWhite = SvgData(
    'assets/icons/password_small_white.svg',
    width: 17.1,
    height: 19,
  );

  static const SvgData qrCode = SvgData(
    'assets/icons/qr_code.svg',
    width: 20,
    height: 20,
  );

  static const SvgData googlePlay = SvgData(
    'assets/icons/google_play.svg',
    width: 20.35,
    height: 22.02,
  );

  static const SvgData google = SvgData(
    'assets/icons/google.svg',
    width: 21.57,
    height: 22.01,
  );

  static const SvgData googleBig = SvgData(
    'assets/icons/google_big.svg',
    width: 97.99,
    height: 100,
  );

  static const SvgData appleBig = SvgData(
    'assets/icons/apple_big.svg',
    width: 78.04,
    height: 100,
  );

  static const SvgData githubBig = SvgData(
    'assets/icons/github_big.svg',
    width: 100.65,
    height: 100,
  );

  static const SvgData apple = SvgData(
    'assets/icons/apple.svg',
    width: 21.07,
    height: 27,
  );

  static const SvgData windows = SvgData(
    'assets/icons/windows.svg',
    width: 23.93,
    height: 24,
  );

  static const SvgData linux = SvgData(
    'assets/icons/linux.svg',
    width: 22.09,
    height: 26,
  );

  static const SvgData rustWhite = SvgData(
    'assets/icons/rust_white.svg',
    width: 32.04,
    height: 31.97,
  );

  static const SvgData rust = SvgData(
    'assets/icons/rust.svg',
    width: 32.04,
    height: 31.97,
  );

  static const SvgData android = SvgData(
    'assets/icons/android.svg',
    width: 21,
    height: 25.02,
  );

  static const SvgData appStore = SvgData(
    'assets/icons/app_store.svg',
    width: 23,
    height: 23,
  );

  static const SvgData freelance = SvgData(
    'assets/icons/freelance.svg',
    width: 32.2,
    height: 32,
  );

  static const SvgData freelanceWhite = SvgData(
    'assets/icons/freelance_white.svg',
    width: 32.2,
    height: 32,
  );

  static const SvgData frontend = SvgData(
    'assets/icons/frontend.svg',
    width: 25.85,
    height: 32,
  );

  static const SvgData frontendWhite = SvgData(
    'assets/icons/frontend_white.svg',
    width: 25.85,
    height: 32,
  );

  static const SvgData enter = SvgData(
    'assets/icons/enter.svg',
    width: 20.21,
    height: 25,
  );

  static const SvgData oneTime = SvgData(
    'assets/icons/one_time.svg',
    width: 19.88,
    height: 26,
  );

  static const SvgData email = SvgData(
    'assets/icons/email.svg',
    width: 21.93,
    height: 22.5,
  );

  static const SvgData phone = SvgData(
    'assets/icons/phone.svg',
    width: 17.61,
    height: 25,
  );

  static const SvgData github = SvgData(
    'assets/icons/github.svg',
    width: 26.17,
    height: 26,
  );

  static const SvgData share = SvgData(
    'assets/icons/share.svg',
    width: 14.54,
    height: 16.5,
  );

  static const SvgData visibleOff = SvgData(
    'assets/icons/visible_off.svg',
    width: 17.07,
    height: 15.14,
  );

  static const SvgData visibleOn = SvgData(
    'assets/icons/visible_on.svg',
    width: 17.07,
    height: 11.97,
  );

  static const SvgData copy = SvgData(
    'assets/icons/copy.svg',
    width: 14.53,
    height: 17,
  );

  static const SvgData copySmall = SvgData(
    'assets/icons/copy_small.svg',
    width: 10.24,
    height: 12,
  );

  static const SvgData wallet = SvgData(
    'assets/icons/wallet.svg',
    width: 34.01,
    height: 29.73,
  );

  static const SvgData walletOpened = SvgData(
    'assets/icons/wallet_opened.svg',
    width: 34.01,
    height: 29.73,
  );

  static const SvgData walletClosed = SvgData(
    'assets/icons/wallet_closed.svg',
    width: 34.01,
    height: 26,
  );

  static const SvgData partner = SvgData(
    'assets/icons/partner.svg',
    width: 36,
    height: 28,
  );

  static const SvgData publics = SvgData(
    'assets/icons/publics.svg',
    width: 32,
    height: 31,
  );

  static const SvgData publicsMuted = SvgData(
    'assets/icons/publics_muted.svg',
    width: 32,
    height: 31,
  );

  static const SvgData chats = SvgData(
    'assets/icons/chats.svg',
    width: 39.26,
    height: 33.5,
  );

  static const SvgData contacts = SvgData(
    'assets/icons/contacts.svg',
    width: 32,
    height: 32,
  );

  static const SvgData chatsMuted = SvgData(
    'assets/icons/chats_muted.svg',
    width: 39.26,
    height: 33.5,
  );

  static const SvgData backSmall = SvgData(
    'assets/icons/back_small.svg',
    width: 6.5,
    height: 11,
  );

  static const SvgData back = SvgData(
    'assets/icons/back.svg',
    width: 9,
    height: 16,
  );

  static const SvgData publicInformation = SvgData(
    'assets/icons/public_information6.svg',
    width: 34,
    height: 34,
  );

  static const SvgData publicInformationWhite = SvgData(
    'assets/icons/public_information6_white.svg',
    width: 34,
    height: 34,
  );

  static const SvgData addAccount = SvgData(
    'assets/icons/add_account.svg',
    width: 21.47,
    height: 20,
  );

  static const SvgData delete = SvgData(
    'assets/icons/delete.svg',
    width: 16.75,
    height: 15.99,
  );

  static const SvgData notes = SvgData(
    'assets/icons/notes.svg',
    width: 31.44,
    height: 31.67,
  );

  static const SvgData mute = SvgData(
    'assets/icons/mute.svg',
    width: 17.85,
    height: 16,
  );

  static const SvgData unmute = SvgData(
    'assets/icons/unmute.svg',
    width: 17.85,
    height: 16,
  );

  static const SvgData muted = SvgData(
    'assets/icons/muted.svg',
    width: 14.25,
    height: 15,
  );

  static const SvgData mutedWhite = SvgData(
    'assets/icons/muted_white.svg',
    width: 14.25,
    height: 15,
  );

  static const SvgData fileSmall = SvgData(
    'assets/icons/file_small.svg',
    width: 11.44,
    height: 14.3,
  );

  static const SvgData fileSmallWhite = SvgData(
    'assets/icons/file_white_small.svg',
    width: 11.44,
    height: 14.3,
  );

  static const SvgData fileWhite = SvgData(
    'assets/icons/file_white.svg',
    width: 23.2,
    height: 29,
  );

  static const SvgData addUser = SvgData(
    'assets/icons/add_user.svg',
    width: 19.35,
    height: 18.32,
  );

  static const SvgData chatMore = SvgData(
    'assets/icons/chat_more.svg',
    width: 22,
    height: 22,
  );

  static const SvgData menuSigning = SvgData(
    'assets/icons/menu_signing.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuBackground = SvgData(
    'assets/icons/menu_background.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuChats = SvgData(
    'assets/icons/menu_chats.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuLink = SvgData(
    'assets/icons/menu_link.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuMedia = SvgData(
    'assets/icons/menu_media.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuCalls = SvgData(
    'assets/icons/menu_calls.svg',
    width: 32,
    height: 32,
  );

  static const SvgData blocked = SvgData(
    'assets/icons/blocked.svg',
    width: 15,
    height: 15,
  );

  static const SvgData blockedWhite = SvgData(
    'assets/icons/blocked_white.svg',
    width: 15,
    height: 15,
  );

  static const SvgData sent = SvgData(
    'assets/icons/sent.svg',
    width: 12.42,
    height: 9,
  );

  static const SvgData sentWhite = SvgData(
    'assets/icons/sent_white.svg',
    width: 12.42,
    height: 9,
  );

  static const SvgData delivered = SvgData(
    'assets/icons/delivered.svg',
    height: 9,
  );

  static const SvgData deliveredWhite = SvgData(
    'assets/icons/delivered_white.svg',
    height: 9,
  );

  static const SvgData halfReadWhite = SvgData(
    'assets/icons/half_read_white.svg',
    height: 9,
  );

  static const SvgData halfRead = SvgData(
    'assets/icons/half_read.svg',
    height: 9,
  );

  static const SvgData read = SvgData(
    'assets/icons/read.svg',
    height: 9,
  );

  static const SvgData readWhite = SvgData(
    'assets/icons/read_white.svg',
    height: 9,
  );

  static const SvgData sending = SvgData(
    'assets/icons/sending.svg',
    height: 13,
  );

  static const SvgData sendingWhite = SvgData(
    'assets/icons/sending_white.svg',
    height: 13,
  );

  static const SvgData error = SvgData(
    'assets/icons/error.svg',
    height: 13,
  );

  static const SvgData forward = SvgData(
    'assets/icons/forward.svg',
    width: 26,
    height: 22,
  );

  static const SvgData forwardDisabled = SvgData(
    'assets/icons/forward_disabled.svg',
    width: 26,
    height: 22,
  );

  static const SvgData send = SvgData(
    'assets/icons/send.svg',
    width: 25.44,
    height: 21.91,
  );

  static const SvgData readSmall = SvgData(
    'assets/icons/read.svg',
    height: 7,
  );

  static const SvgData halfReadSmall = SvgData(
    'assets/icons/half_read.svg',
    height: 7,
  );

  static const SvgData sendingSmall = SvgData(
    'assets/icons/sending.svg',
    height: 10,
  );

  static const SvgData deliveredSmall = SvgData(
    'assets/icons/delivered.svg',
    height: 7,
  );

  static const SvgData errorSmall = SvgData(
    'assets/icons/error.svg',
    height: 10,
  );

  static const SvgData sentSmall = SvgData(
    'assets/icons/sent.svg',
    height: 7,
  );

  static const SvgData audioMessage = SvgData(
    'assets/icons/audio_message.svg',
    width: 18.87,
    height: 23.8,
  );

  static const SvgData audioMessageSmall = SvgData(
    'assets/icons/audio_message_small.svg',
    width: 17.41,
    height: 21.9,
  );

  static const SvgData videoMessage = SvgData(
    'assets/icons/video_message.svg',
    width: 23.11,
    height: 21,
  );

  static const SvgData videoMessageSmall = SvgData(
    'assets/icons/video_message_small.svg',
    width: 20.89,
    height: 19,
  );

  static const SvgData fileOutlined = SvgData(
    'assets/icons/file_outlined.svg',
    width: 18.8,
    height: 23,
  );

  static const SvgData fileOutlinedSmall = SvgData(
    'assets/icons/file_outlined_small.svg',
    width: 17.2,
    height: 21,
  );

  static const SvgData takePhoto = SvgData(
    'assets/icons/take_photo.svg',
    width: 22,
    height: 22,
  );

  static const SvgData takePhotoSmall = SvgData(
    'assets/icons/take_photo_small.svg',
    width: 20,
    height: 20,
  );

  static const SvgData takeVideo = SvgData(
    'assets/icons/record_video.svg',
    width: 27.77,
    height: 24.65,
  );

  static const SvgData takeVideoSmall = SvgData(
    'assets/icons/record_video_small.svg',
    width: 25.52,
    height: 22.65,
  );

  static const SvgData gallery = SvgData(
    'assets/icons/gallery.svg',
    width: 22,
    height: 22,
  );

  static const SvgData gallerySmall = SvgData(
    'assets/icons/gallery_small.svg',
    width: 20,
    height: 20,
  );

  static const SvgData gift = SvgData(
    'assets/icons/gift.svg',
    width: 24.93,
    height: 24,
  );

  static const SvgData giftSmall = SvgData(
    'assets/icons/gift_small.svg',
    width: 22.84,
    height: 21.99,
  );

  static const SvgData smile = SvgData(
    'assets/icons/smile.svg',
    width: 23,
    height: 23,
  );

  static const SvgData smileSmall = SvgData(
    'assets/icons/smile_small.svg',
    width: 21,
    height: 21,
  );

  static const SvgData pin = SvgData(
    'assets/icons/pin.svg',
    width: 9.65,
    height: 17,
  );

  static const SvgData pinDisabled = SvgData(
    'assets/icons/pin_disabled.svg',
    width: 9.65,
    height: 17,
  );

  static const SvgData unpin = SvgData(
    'assets/icons/unpin.svg',
    width: 15.5,
    height: 16.98,
  );

  static const SvgData reply = SvgData(
    'assets/icons/reply.svg',
    width: 19.53,
    height: 19,
  );

  static const SvgData replyWhite = SvgData(
    'assets/icons/reply_white.svg',
    width: 19.53,
    height: 19,
  );

  static const SvgData forwardSmall = SvgData(
    'assets/icons/forward_small.svg',
    width: 19.53,
    height: 19,
  );

  static const SvgData forwardSmallWhite = SvgData(
    'assets/icons/forward_small_white.svg',
    width: 19.53,
    height: 19,
  );

  static const SvgData edit = SvgData(
    'assets/icons/edit.svg',
    width: 19,
    height: 19,
  );

  static const SvgData editWhite = SvgData(
    'assets/icons/edit_white.svg',
    width: 19,
    height: 19,
  );

  static const SvgData more = SvgData(
    'assets/icons/more.svg',
    width: 4,
    height: 16,
  );

  static const SvgData pinOutlined = SvgData(
    'assets/icons/pin_outlined.svg',
    width: 13.02,
    height: 18.01,
  );

  static const SvgData unpinOutlined = SvgData(
    'assets/icons/unpin_outlined.svg',
    width: 13.02,
    height: 19.73,
  );

  static const SvgData deleteThick = SvgData(
    'assets/icons/delete_small.svg',
    width: 18.84,
    height: 18,
  );

  static const SvgData info = SvgData(
    'assets/icons/info.svg',
    width: 19,
    height: 19,
  );

  static const SvgData infoWhite = SvgData(
    'assets/icons/info_white.svg',
    width: 19,
    height: 19,
  );

  static const SvgData copy19 = SvgData(
    'assets/icons/copy19.svg',
    width: 16.3,
    height: 19,
  );

  static const SvgData copy19White = SvgData(
    'assets/icons/copy19_white.svg',
    width: 16.3,
    height: 19,
  );

  static const SvgData darkMode = SvgData(
    'assets/icons/dark_mode.svg',
    width: 20.97,
    height: 21,
  );

  static const SvgData lightMode = SvgData(
    'assets/icons/light_mode.svg',
    width: 23.06,
    height: 23,
  );

  static const SvgData palette = SvgData(
    'assets/icons/palette.svg',
    width: 21.02,
    height: 21.01,
  );

  static const SvgData typography = SvgData(
    'assets/icons/typography.svg',
    width: 24.26,
    height: 16.25,
  );

  static const SvgData widgets = SvgData(
    'assets/icons/widgets.svg',
    width: 18.98,
    height: 18.98,
  );

  static const SvgData icons = SvgData(
    'assets/icons/icons.svg',
    width: 21.15,
    height: 19.01,
  );

  static const SvgData callMore = SvgData(
    'assets/icons/call_more.svg',
    width: 27,
    height: 27,
  );

  static const SvgData callEndBig = SvgData(
    'assets/icons/call_end_big.svg',
    width: 40,
  );

  static const SvgData callVideoOn = SvgData(
    'assets/icons/call_camera_on.svg',
    width: 35.88,
    height: 30.66,
  );

  static const SvgData callVideoOff = SvgData(
    'assets/icons/call_camera_off.svg',
    width: 35.88,
    height: 30.66,
  );

  // TODO
  static const SvgData callMicrophoneOn = SvgData(
    'assets/icons/call_microphone_on.svg',
    width: 30.66,
    height: 30.66,
  );

  // TODO
  static const SvgData callMicrophoneOff = SvgData(
    'assets/icons/call_microphone_off.svg',
    width: 30.66,
    height: 30.66,
  );

  static const SvgData callScreenShareOn = SvgData(
    'assets/icons/screen_share_on.svg',
    width: 28,
    height: 28.31,
  );

  static const SvgData callScreenShareOff = SvgData(
    'assets/icons/screen_share_off.svg',
    width: 28,
    height: 28.31,
  );

  static const SvgData callHandDown = SvgData(
    'assets/icons/hand_down.svg',
    width: 30.66,
    height: 31.81,
  );

  static const SvgData callHandUp = SvgData(
    'assets/icons/hand_up.svg',
    width: 30.66,
    height: 31.81,
  );

  static const SvgData handUpBig = SvgData(
    'assets/icons/hand_up_big.svg',
    width: 46,
    height: 57.51,
  );

  static const SvgData callSettings = SvgData(
    'assets/icons/call_settings.svg',
    width: 32,
    height: 32,
  );

  static const SvgData callParticipants = SvgData(
    'assets/icons/call_participants.svg',
    width: 29.36,
    height: 26.83,
  );

  static const SvgData callIncomingVideoOn = SvgData(
    'assets/icons/incoming_video_on.svg',
    width: 28.78,
    height: 28,
  );

  static const SvgData callIncomingVideoOff = SvgData(
    'assets/icons/incoming_video_off.svg',
    width: 28.78,
    height: 28,
  );

  static const SvgData callIncomingAudioOn = SvgData(
    'assets/icons/speaker_on.svg',
    width: 27.89,
    height: 25,
  );

  static const SvgData callIncomingAudioOff = SvgData(
    'assets/icons/speaker_off.svg',
    width: 27.89,
    height: 25,
  );

  static const SvgData addBig = SvgData(
    'assets/icons/add_big.svg',
    width: 20.4,
    height: 20.4,
  );

  static const SvgData addBigger = SvgData(
    'assets/icons/add_bigger.svg',
    width: 29,
    height: 29,
  );

  static const SvgData audioOffSmall = SvgData(
    'assets/icons/audio_off_small.svg',
    width: 16.73,
    height: 15,
  );

  static const SvgData microphoneOffSmall = SvgData(
    'assets/icons/microphone_off_small.svg',
    width: 15,
    height: 15,
  );

  static const SvgData lowSignalSmall = SvgData(
    'assets/icons/low_signal_level.svg',
    width: 12.19,
    height: 14,
  );

  static const SvgData screenShareSmall = SvgData(
    'assets/icons/screen_share_small.svg',
    width: 15.53,
    height: 12.2,
  );

  static const SvgData videoOffSmall = SvgData(
    'assets/icons/video_off_small.svg',
    width: 19.89,
    height: 17,
  );

  static const SvgData menuBlocklist = SvgData(
    'assets/icons/menu_blocklist.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuDanger = SvgData(
    'assets/icons/menu_danger.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuDonate = SvgData(
    'assets/icons/menu_donate.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuDownload = SvgData(
    'assets/icons/menu_download.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuLanguage = SvgData(
    'assets/icons/menu_language.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuLogout = SvgData(
    'assets/icons/menu_logout.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuNotifications = SvgData(
    'assets/icons/menu_notifications.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuPayment = SvgData(
    'assets/icons/menu_payment.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuStorage = SvgData(
    'assets/icons/menu_storage.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuWelcome = SvgData(
    'assets/icons/menu_welcome.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuWork = SvgData(
    'assets/icons/menu_work.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuDevices = SvgData(
    'assets/icons/menu_devices.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuStyle = SvgData(
    'assets/icons/menu_style.svg',
    width: 32,
    height: 32,
  );

  static const SvgData menuProfile = SvgData(
    'assets/icons/menu_profile.svg',
    width: 32,
    height: 32,
  );

  static const List<SvgData> head = [
    SvgData(
      'assets/images/logo/head_0.svg',
      width: 206.33,
      height: 220.68,
    ),
    SvgData(
      'assets/images/logo/head_1.svg',
      width: 206.33,
      height: 220.68,
    ),
    SvgData(
      'assets/images/logo/head_2.svg',
      width: 206.33,
      height: 220.68,
    ),
    SvgData(
      'assets/images/logo/head_3.svg',
      width: 206.33,
      height: 220.68,
    ),
    SvgData(
      'assets/images/logo/head_4.svg',
      width: 206.33,
      height: 220.68,
    ),
    SvgData(
      'assets/images/logo/head_5.svg',
      width: 206.33,
      height: 220.68,
    ),
    SvgData(
      'assets/images/logo/head_6.svg',
      width: 206.33,
      height: 220.68,
    ),
    SvgData(
      'assets/images/logo/head_7.svg',
      width: 206.33,
      height: 220.68,
    ),
    SvgData(
      'assets/images/logo/head_8.svg',
      width: 206.33,
      height: 220.68,
    ),
    SvgData(
      'assets/images/logo/head_9.svg',
      width: 206.33,
      height: 220.68,
    ),
  ];

  static const SvgData fullscreenEnterSmall = SvgData(
    'assets/icons/fullscreen_enter_small.svg',
    width: 12,
    height: 12,
  );

  static const SvgData fullscreenExitSmall = SvgData(
    'assets/icons/fullscreen_exit_small.svg',
    width: 12,
    height: 12,
  );

  static const SvgData fullscreenEnter = SvgData(
    'assets/icons/fullscreen_enter.svg',
    width: 22,
    height: 22,
  );

  static const SvgData fullscreenExit = SvgData(
    'assets/icons/fullscreen_exit.svg',
    width: 22,
    height: 22,
  );

  static const SvgData arrowLeft = SvgData(
    'assets/icons/arrow_left.svg',
    width: 9.81,
    height: 16.7,
  );

  static const SvgData arrowLeftDisabled = SvgData(
    'assets/icons/arrow_left_disabled.svg',
    width: 9.81,
    height: 16.7,
  );

  static const SvgData arrowRight = SvgData(
    'assets/icons/arrow_right.svg',
    width: 9.81,
    height: 16.7,
  );

  static const SvgData arrowRightDisabled = SvgData(
    'assets/icons/arrow_right_disabled.svg',
    width: 9.81,
    height: 16.7,
  );

  static const SvgData close = SvgData(
    'assets/icons/close.svg',
    width: 16.05,
    height: 16.05,
  );

  static const SvgData callAudio = SvgData(
    'assets/icons/call_audio.svg',
    height: 12,
  );

  static const SvgData callAudioMissed = SvgData(
    'assets/icons/call_audio_red.svg',
    height: 12,
  );

  static const SvgData callAudioWhite = SvgData(
    'assets/icons/call_audio_white.svg',
    height: 12,
  );

  static const SvgData callAudioDisabled = SvgData(
    'assets/icons/call_audio_grey.svg',
    height: 12,
  );

  static const SvgData callVideo = SvgData(
    'assets/icons/call_video.svg',
    height: 11,
  );

  static const SvgData callVideoMissed = SvgData(
    'assets/icons/call_video_red.svg',
    height: 11,
  );

  static const SvgData callVideoWhite = SvgData(
    'assets/icons/call_video_white.svg',
    height: 11,
  );

  static const SvgData callVideoDisabled = SvgData(
    'assets/icons/call_video_grey.svg',
    height: 11,
  );

  static const SvgData download = SvgData(
    'assets/icons/download.svg',
    width: 42,
    height: 42,
  );

  static const SvgData acceptAudioCall = SvgData(
    'assets/icons/call_audio_white.svg',
    height: 29,
  );

  static const SvgData acceptAudioCallSmall = SvgData(
    'assets/icons/call_audio_white.svg',
    height: 24,
  );

  static const SvgData mutedSmall = SvgData(
    'assets/icons/muted_small.svg',
    width: 9.5,
    height: 10,
  );

  static const SvgData noVideo = SvgData(
    'assets/icons/no_video.svg',
    width: 49.15,
    height: 42,
  );

  static const SvgData sortAbc = SvgData(
    'assets/icons/sort_abc.svg',
    width: 29.69,
    height: 21,
  );

  static const SvgData sortTime = SvgData(
    'assets/icons/sort_time.svg',
    width: 29.69,
    height: 21,
  );

  static const SvgData timer = SvgData(
    'assets/icons/timer.svg',
    width: 17,
    height: 17,
  );

  static const SvgData errorBig = SvgData(
    'assets/icons/error_big.svg',
    width: 17,
    height: 17,
  );

  static const SvgData favorite = SvgData(
    'assets/icons/favorite.svg',
    width: 24.28,
    height: 23.09,
  );

  static const SvgData notificationsOn = SvgData(
    'assets/icons/notifications_on.svg',
    width: 21.2,
    height: 24,
  );

  static const SvgData notificationsOff = SvgData(
    'assets/icons/notifications_off.svg',
    width: 24.6,
    height: 25,
  );

  static const SvgData chatVideoCallFilled = SvgData(
    'assets/icons/chat_video_call_filled.svg',
    width: 27.71,
    height: 19,
  );

  static const SvgData chatAudioCallFilled = SvgData(
    'assets/icons/chat_audio_call_filled.svg',
    width: 21,
    height: 21,
  );

  static const SvgData coin = SvgData(
    'assets/icons/coin.svg',
    width: 18,
    height: 18,
  );

  static const SvgData makeAudioCall = SvgData(
    'assets/icons/make_audio_call.svg',
    width: 18,
    height: 18,
  );

  static const SvgData makeAudioCallWhite = SvgData(
    'assets/icons/make_audio_call_white.svg',
    width: 18,
    height: 18,
  );

  static const SvgData makeAudioCallDisabled = SvgData(
    'assets/icons/make_audio_call_disabled.svg',
    width: 18,
    height: 18,
  );

  static const SvgData makeVideoCall = SvgData(
    'assets/icons/make_video_call.svg',
    width: 21.93,
    height: 15,
  );

  static const SvgData makeVideoCallWhite = SvgData(
    'assets/icons/make_video_call_white.svg',
    width: 21.93,
    height: 15,
  );

  static const SvgData makeVideoCallDisabled = SvgData(
    'assets/icons/make_video_call_disabled.svg',
    width: 21.93,
    height: 15,
  );

  static const SvgData favoriteSmall = SvgData(
    'assets/icons/favorite_small.svg',
    width: 20.57,
    height: 19.57,
  );

  static const SvgData favoriteSmallWhite = SvgData(
    'assets/icons/favorite_small_white.svg',
    width: 20.57,
    height: 19.57,
  );

  static const SvgData unfavoriteSmall = SvgData(
    'assets/icons/unfavorite_small.svg',
    width: 20.57,
    height: 19.57,
  );

  static const SvgData unfavoriteSmallWhite = SvgData(
    'assets/icons/unfavorite_small_white.svg',
    width: 20.57,
    height: 19.57,
  );

  static const SvgData muteSmall = SvgData(
    'assets/icons/mute_small.svg',
    width: 19.68,
    height: 20,
  );

  static const SvgData muteSmallWhite = SvgData(
    'assets/icons/mute_small_white.svg',
    width: 19.68,
    height: 20,
  );

  static const SvgData unmuteSmall = SvgData(
    'assets/icons/unmute_small.svg',
    width: 19.68,
    height: 20,
  );

  static const SvgData unmuteSmallWhite = SvgData(
    'assets/icons/unmute_small_white.svg',
    width: 19.68,
    height: 20,
  );

  static const SvgData block = SvgData(
    'assets/icons/block.svg',
    width: 19,
    height: 19,
  );

  static const SvgData blockWhite = SvgData(
    'assets/icons/block_white.svg',
    width: 19,
    height: 19,
  );

  static const SvgData blockSmall = SvgData(
    'assets/icons/block.svg',
    width: 16,
    height: 16,
  );

  static const SvgData cleanHistory = SvgData(
    'assets/icons/clean_history.svg',
    width: 17.21,
    height: 18,
  );

  static const SvgData cleanHistoryWhite = SvgData(
    'assets/icons/clean_history_white.svg',
    width: 17.21,
    height: 18,
  );

  static const SvgData cleanHistorySmall = SvgData(
    'assets/icons/clean_history_small.svg',
    width: 15.28,
    height: 16,
  );

  static const SvgData addContact = SvgData(
    'assets/icons/add_contact.svg',
    width: 21.01,
    height: 19.43,
  );

  static const SvgData addContactWhite = SvgData(
    'assets/icons/add_contact_white.svg',
    width: 21.01,
    height: 19.43,
  );

  static const SvgData deleteContact = SvgData(
    'assets/icons/delete_contact.svg',
    width: 21.01,
    height: 19.43,
  );

  static const SvgData deleteContactWhite = SvgData(
    'assets/icons/delete_contact_white.svg',
    width: 21.01,
    height: 19.43,
  );

  static const SvgData group = SvgData(
    'assets/icons/group.svg',
    width: 21.29,
    height: 18,
  );

  static const SvgData groupWhite = SvgData(
    'assets/icons/group_white.svg',
    width: 21.29,
    height: 18,
  );

  static const SvgData select = SvgData(
    'assets/icons/select.svg',
    width: 19,
    height: 19,
  );

  static const SvgData selectWhite = SvgData(
    'assets/icons/select_white.svg',
    width: 19,
    height: 19,
  );

  static const SvgData sortAbcSmall = SvgData(
    'assets/icons/sort_abc_small.svg',
    width: 20.36,
    height: 16.75,
  );

  static const SvgData sortTimeSmall = SvgData(
    'assets/icons/sort_time_small.svg',
    width: 20.36,
    height: 16.75,
  );

  static const SvgData centerVideo = SvgData(
    'assets/icons/center_video.svg',
    width: 22.5,
    height: 20.85,
  );

  static const SvgData uncenterVideo = SvgData(
    'assets/icons/uncenter_video.svg',
    width: 22.5,
    height: 20.85,
  );

  static const SvgData incomingVideoOff = SvgData(
    'assets/icons/incoming_video_off_small.svg',
    width: 22.5,
    height: 20.85,
  );

  static const SvgData incomingVideoOn = SvgData(
    'assets/icons/incoming_video_on_small.svg',
    width: 22.5,
    height: 20.85,
  );

  static const SvgData incomingAudioOn = SvgData(
    'assets/icons/incoming_audio_on.svg',
    width: 20.39,
    height: 18,
  );

  static const SvgData incomingAudioOff = SvgData(
    'assets/icons/incoming_audio_off.svg',
    width: 20.39,
    height: 18,
  );

  static const SvgData cameraOn = SvgData(
    'assets/icons/camera_on.svg',
    width: 22.92,
    height: 18.5,
  );

  static const SvgData cameraOff = SvgData(
    'assets/icons/camera_off.svg',
    width: 22.92,
    height: 18.5,
  );

  static const SvgData micOff = SvgData(
    'assets/icons/mic_off.svg',
    width: 18.2,
    height: 19,
  );

  static const SvgData micOn = SvgData(
    'assets/icons/mic_on.svg',
    width: 18.2,
    height: 19,
  );

  static const SvgData removeFromCall = SvgData(
    'assets/icons/remove_from_call.svg',
    width: 21.36,
    height: 20.51,
  );

  static const SvgData deleteBig = SvgData(
    'assets/icons/delete_big.svg',
    width: 23.01,
    height: 22,
  );

  static const SvgData deleteBigDisabled = SvgData(
    'assets/icons/delete_big_disabled.svg',
    width: 23.01,
    height: 22,
  );

  static const SvgData callCameraFront = SvgData(
    'assets/icons/camera_front.svg',
    width: 27.57,
    height: 23.8,
  );

  static const SvgData callCameraBack = SvgData(
    'assets/icons/camera_back.svg',
    width: 27.57,
    height: 23.8,
  );

  static const SvgData activeCallStart = SvgData(
    'assets/icons/active_call_start.svg',
    width: 8,
    height: 8,
  );

  static const SvgData activeCallEnd = SvgData(
    'assets/icons/active_call_end.svg',
    width: 9.59,
    height: 4.21,
  );

  static const SvgData clearSearch = SvgData(
    'assets/icons/clear_search.svg',
    width: 21.8,
    height: 16.8,
  );

  static const SvgData deleteGallery = SvgData(
    'assets/icons/delete_gallery.svg',
    width: 28.22,
    height: 27,
  );

  static const SvgData sendSmall = SvgData(
    'assets/icons/send_small.svg',
    width: 19.22,
    height: 16.5,
  );

  static const SvgData sendSmallWhite = SvgData(
    'assets/icons/send_small_white.svg',
    width: 19.22,
    height: 16.5,
  );

  static const SvgData leaveGroup = SvgData(
    'assets/icons/leave_group.svg',
    width: 16.28,
    height: 19,
  );

  static const SvgData leaveGroupWhite = SvgData(
    'assets/icons/leave_group_white.svg',
    width: 16.28,
    height: 19,
  );

  static const SvgData leaveGroupSmall = SvgData(
    'assets/icons/leave_group_small.svg',
    width: 12.88,
    height: 16,
  );

  static const SvgData report = SvgData(
    'assets/icons/report.svg',
    width: 16,
    height: 16,
  );

  static const SvgData delete19 = SvgData(
    'assets/icons/delete19.svg',
    width: 19.88,
    height: 19,
  );

  static const SvgData delete19White = SvgData(
    'assets/icons/delete19_white.svg',
    width: 19.88,
    height: 19,
  );

  static const SvgData download19 = SvgData(
    'assets/icons/download19.svg',
    width: 12.89,
    height: 19,
  );

  static const SvgData download19White = SvgData(
    'assets/icons/download19_white.svg',
    width: 12.89,
    height: 19,
  );

  static const SvgData addMember = SvgData(
    'assets/icons/add_member.svg',
    width: 17,
    height: 17,
  );

  static const SvgData complaint = SvgData(
    'assets/icons/complaint.svg',
    width: 16,
    height: 16,
  );

  static const SvgData unblock = SvgData(
    'assets/icons/unblock.svg',
    width: 16,
    height: 16,
  );

  static const SvgData menuNav = SvgData(
    'assets/icons/menu_nav.svg',
    width: 32,
    height: 32,
  );
}
