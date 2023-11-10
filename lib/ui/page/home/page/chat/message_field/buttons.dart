import 'package:flutter/material.dart';

import '/l10n/l10n.dart';
import '/ui/page/home/page/chat/message_field/controller.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import 'donate.dart';
import 'more.dart';

abstract class ChatButton {
  ChatButton(this.c);

  final MessageFieldController c;

  final GlobalKey key = GlobalKey();

  bool get hidden => false;
  bool get enabled => onPressed != null;

  /// Returns a text-represented hint for this [CallButton].
  String get hint;

  SvgData get asset;
  SvgData? get disabled => null;
  Offset get offset => Offset.zero;

  SvgData? get assetMini => null;
  SvgData? get disabledMini => null;
  Offset get offsetMini => Offset.zero;

  void Function(bool)? get onPressed => null;
  void Function(bool)? get onHovered => null;

  IconData? get icon => null;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) =>
      other is ChatButton && runtimeType == other.runtimeType;
}

class AudioMessageButton extends ChatButton {
  AudioMessageButton(super.c);

  @override
  void Function(bool)? get onPressed => (_) {};

  @override
  String get hint => 'btn_audio_message'.l10n;

  @override
  SvgData get asset => SvgIcons.audioMessage;

  @override
  SvgData get assetMini => SvgIcons.audioMessageSmall;
}

class VideoMessageButton extends ChatButton {
  VideoMessageButton(super.c);

  @override
  void Function(bool)? get onPressed => (_) {};

  @override
  String get hint => 'btn_video_message'.l10n;

  @override
  SvgData get asset => SvgIcons.videoMessage;

  @override
  SvgData get assetMini => SvgIcons.videoMessageSmall;
}

class AttachmentButton extends ChatButton {
  AttachmentButton(super.c);

  @override
  void Function(bool)? get onPressed => (_) async {
        await c.pickFile();
        // if (!PlatformUtils.isMobile || PlatformUtils.isWeb) {
        //   await c.pickFile();
        // } else {
        //   c.field.focus.unfocus();
        //   await AttachmentSourceSelector.show(
        //     router.context!,
        //     onPickFile: c.pickFile,
        //     onTakePhoto: c.pickImageFromCamera,
        //     onPickMedia: c.pickMedia,
        //     onTakeVideo: c.pickVideoFromCamera,
        //   );
        // }
      };

  @override
  String get hint => 'btn_file'.l10n;

  @override
  SvgData get asset => SvgIcons.fileOutlined;

  @override
  SvgData get assetMini => SvgIcons.fileOutlinedSmall;
}

class TakePhotoButton extends ChatButton {
  TakePhotoButton(super.c);

  @override
  void Function(bool)? get onPressed => (_) async {
        c.field.focus.unfocus();
        await c.pickImageFromCamera();
      };

  @override
  String get hint =>
      PlatformUtils.isAndroid ? 'label_take_photo'.l10n : 'label_camera'.l10n;

  @override
  SvgData get asset =>
      PlatformUtils.isAndroid ? SvgIcons.takePhoto : SvgIcons.takeVideo;

  @override
  SvgData get assetMini => PlatformUtils.isAndroid
      ? SvgIcons.takePhotoSmall
      : SvgIcons.takeVideoSmall;
}

class TakeVideoButton extends ChatButton {
  TakeVideoButton(super.c);

  @override
  void Function(bool)? get onPressed => (_) async {
        c.field.focus.unfocus();
        await c.pickVideoFromCamera();
      };

  @override
  String get hint => 'label_take_video'.l10n;

  @override
  SvgData get asset => SvgIcons.takeVideo;

  @override
  Offset get offset => const Offset(0, -1.5);

  @override
  SvgData get assetMini => SvgIcons.takeVideoSmall;

  @override
  Offset get offsetMini => const Offset(2, 0);
}

class GalleryButton extends ChatButton {
  GalleryButton(super.c);

  @override
  void Function(bool)? get onPressed => (_) async {
        c.field.focus.unfocus();
        await c.pickMedia();
      };

  @override
  String get hint => 'label_gallery'.l10n;

  @override
  SvgData get asset => SvgIcons.gallery;

  @override
  SvgData get assetMini => SvgIcons.gallerySmall;
}

class FileButton extends ChatButton {
  FileButton(super.c);

  @override
  void Function(bool)? get onPressed => (_) async {
        c.field.focus.unfocus();
        await c.pickFile();
      };

  @override
  String get hint => 'label_file'.l10n;

  @override
  SvgData get asset => SvgIcons.fileOutlined;

  @override
  SvgData get assetMini => SvgIcons.fileOutlinedSmall;
}

class DonateButton extends ChatButton {
  DonateButton(super.c);

  @override
  String get hint => 'btn_gift'.l10n;

  @override
  void Function(bool)? get onHovered => (bool hovered) {
        c.removeEntries<MessageFieldDonate>();
        if (hovered) {
          c.addEntry<MessageFieldDonate>(
            MessageFieldDonate(
              c,
              globalKey: key.currentContext == null ? null : key,
            ),
            hovered,
          );
        }
      };

  @override
  void Function(bool)? get onPressed => (b) async {
        c.removeEntries<MessageFieldMore>();
        c.removeEntries<MessageFieldDonate>();
        c.addEntry<MessageFieldDonate>(
          MessageFieldDonate(
            c,
            globalKey: !b || key.currentContext == null ? null : key,
          ),
        );
      };

  @override
  SvgData get asset => SvgIcons.gift;

  @override
  Offset get offset => const Offset(0, -1);

  @override
  SvgData get assetMini => SvgIcons.giftSmall;
}

class StickerButton extends ChatButton {
  StickerButton(super.c);

  @override
  void Function(bool)? get onPressed => (_) {};

  @override
  String get hint => 'btn_sticker'.l10n;

  @override
  SvgData get asset => SvgIcons.smile;

  @override
  Offset get offset => const Offset(0, -1);

  @override
  SvgData get assetMini => SvgIcons.smileSmall;
}

class SendButton extends ChatButton {
  SendButton(super.c);

  @override
  String get hint => 'btn_sticker'.l10n;

  @override
  SvgData get asset => SvgIcons.smile;

  @override
  SvgData get assetMini => SvgIcons.smileSmall;
}

class AudioCallButton extends ChatButton {
  AudioCallButton(super.c);

  @override
  bool enabled = true;

  @override
  String get hint => 'btn_audio_call'.l10n;

  @override
  void Function(bool)? get onPressed => (b) => c.onCall?.call(false);

  @override
  SvgData get asset => SvgIcons.chatAudioCall;

  @override
  SvgData get disabled => SvgIcons.chatAudioCallDisabled;
}

class VideoCallButton extends ChatButton {
  VideoCallButton(super.c);

  @override
  bool enabled = true;

  @override
  String get hint => 'btn_video_call'.l10n;

  @override
  void Function(bool)? get onPressed => (b) => c.onCall?.call(true);

  @override
  SvgData get asset => SvgIcons.chatVideoCall;

  @override
  SvgData get disabled => SvgIcons.chatVideoCallDisabled;
}
