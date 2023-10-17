import 'package:flutter/material.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/page/chat/message_field/controller.dart';
import 'package:messenger/ui/page/home/page/chat/widget/attachment_selector.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/util/platform_utils.dart';

import 'donate.dart';
import 'more.dart';

abstract class ChatButton {
  ChatButton(this.c);

  final MessageFieldController c;

  final GlobalKey key = GlobalKey();

  /// Returns a text-represented hint for this [CallButton].
  String get hint;

  SvgData get asset;
  Offset get offset => Offset.zero;

  SvgData? get assetMini;
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
  String get hint => 'Аудио сообщение';

  @override
  SvgData get asset => SvgIcons.audioMessage;

  @override
  SvgData get assetMini => SvgIcons.audioMessageSmall;
}

class VideoMessageButton extends ChatButton {
  VideoMessageButton(super.c);

  @override
  String get hint => 'Видео сообщение';

  @override
  SvgData get asset => SvgIcons.videoMessage;

  @override
  SvgData get assetMini => SvgIcons.videoMessageSmall;
}

class AttachmentButton extends ChatButton {
  AttachmentButton(super.c);

  @override
  void Function(bool)? get onPressed => (_) async {
        if (!PlatformUtils.isMobile || PlatformUtils.isWeb) {
          await c.pickFile();
        } else {
          c.field.focus.unfocus();
          await AttachmentSourceSelector.show(
            router.context!,
            onPickFile: c.pickFile,
            onTakePhoto: c.pickImageFromCamera,
            onPickMedia: c.pickMedia,
            onTakeVideo: c.pickVideoFromCamera,
          );
        }
      };

  @override
  String get hint => 'Файл';

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
  SvgData get asset => SvgIcons.takePhoto;

  @override
  SvgData get assetMini => SvgIcons.takePhotoSmall;
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
  SvgData get assetMini => SvgIcons.takeVideoSmall;

  @override
  Offset get offsetMini => const Offset(3, 0);
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
  String get hint => 'Подарок';

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
  String get hint => 'Стикер';

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
  String get hint => 'Стикер';

  @override
  SvgData get asset => SvgIcons.smile;

  @override
  SvgData get assetMini => SvgIcons.smileSmall;
}
