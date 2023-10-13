import 'package:flutter/material.dart';

import 'svg.dart';

class SvgData {
  const SvgData(
    this.asset, {
    this.width,
    this.height,
  });

  final String asset;
  final double? width;
  final double? height;
}

class SvgIcon extends StatelessWidget {
  const SvgIcon(this.data, {super.key, this.height});

  final SvgData data;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SvgImage.icon(data, height: height);
  }
}

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

  static const SvgData chatVideoCall = SvgData(
    'assets/icons/chat_video_call.svg',
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

  // Think about colors naming.
  static const SvgData closePrimary = SvgData(
    'assets/icons/close_primary.svg',
    width: 15,
    height: 15,
  );

  // Think about colors naming.
  static const SvgData closeSmallPrimary = SvgData(
    'assets/icons/close_small_primary.svg',
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
    height: 22.51,
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

  // TODO
  static const SvgData notes = SvgData(
    'assets/icons/notes.svg',
    width: 31.43,
    height: 31.67,
  );

  // TODO
  static const SvgData mute = SvgData(
    'assets/icons/mute.svg',
    width: 17.85,
    height: 16,
  );

  // TODO
  static const SvgData unmute = SvgData(
    'assets/icons/unmute.svg',
    width: 17.85,
    height: 16,
  );

  // TODO
  static const SvgData muted = SvgData(
    'assets/icons/muted.svg',
    width: 19.99,
    height: 15,
  );

  // TODO
  static const SvgData mutedWhite = SvgData(
    'assets/icons/muted_light.svg',
    width: 19.99,
    height: 15,
  );

  // TODO
  static const SvgData fileSmall = SvgData(
    'assets/icons/file_dark.svg',
    height: 14.3,
  );

  // TODO
  static const SvgData fileSmallWhite = SvgData(
    'assets/icons/file.svg',
    height: 14.3,
  );

  // TODO
  static const SvgData fileWhite = SvgData(
    'assets/icons/file.svg',
    height: 29,
  );

  static const SvgData addUser = SvgData(
    'assets/icons/add_user.svg',
    width: 19.35,
    height: 18.32,
  );

// TODO:
  static const SvgData chatMore = SvgData(
    'assets/icons/chat_more1.svg',
    height: 22,
    width: 22,
  );
}
