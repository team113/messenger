import 'package:flutter/material.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/page/chat/message_field/controller.dart';
import 'package:messenger/ui/page/home/page/chat/widget/attachment_selector.dart';
import 'package:messenger/util/platform_utils.dart';

abstract class ChatButton {
  const ChatButton(this.c);

  final MessageFieldController c;

  /// Returns a text-represented hint for this [CallButton].
  String get hint;

  String get asset;
  double get assetWidth => 26;
  double get assetHeight => 22;
  Offset get offset => Offset.zero;

  String? get assetMini => null;
  double? get assetMiniWidth => 26;
  double? get assetMiniHeight => 22;
  Offset get offsetMini => Offset.zero;

  void Function()? get onPressed => null;

  IconData? get icon => null;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) =>
      other is ChatButton && runtimeType == other.runtimeType;
}

class AudioMessageButton extends ChatButton {
  const AudioMessageButton(super.c);

  @override
  String get hint => 'Аудио сообщение';

  @override
  String get asset => 'audio_message2';

  @override
  double get assetWidth => 18.87;

  @override
  double get assetHeight => 23.8;

  @override
  String get assetMini => 'audio_message_mini';

  @override
  double get assetMiniWidth => 17.41;

  @override
  double get assetMiniHeight => 21.9;
}

class VideoMessageButton extends ChatButton {
  const VideoMessageButton(super.c);

  @override
  String get hint => 'Видео сообщение';

  @override
  String get asset => 'video_message2';

  @override
  double get assetWidth => 23.11;

  @override
  double get assetHeight => 21;

  @override
  String get assetMini => 'video_message_mini';

  @override
  double get assetMiniWidth => 20.89;

  @override
  double get assetMiniHeight => 19;
}

class AttachmentButton extends ChatButton {
  const AttachmentButton(super.c);

  @override
  void Function()? get onPressed => () async {
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
  String get asset => 'attachment';

  @override
  double get assetWidth => 20.66;

  @override
  double get assetHeight => 23;

  @override
  String get assetMini => 'attachment_mini';

  @override
  double get assetMiniWidth => 18.88;

  @override
  double get assetMiniHeight => 21;
}

class TakePhotoButton extends ChatButton {
  const TakePhotoButton(super.c);

  @override
  void Function()? get onPressed => () async {
        c.field.focus.unfocus();
        await c.pickImageFromCamera();
      };

  @override
  String get hint =>
      PlatformUtils.isAndroid ? 'label_take_photo'.l10n : 'label_camera'.l10n;

  // @override
  // String get asset => 'make_photo';

  @override
  String get asset => 'take_photo1';
  @override
  double get assetWidth => 22;
  @override
  double get assetHeight => 22;

  @override
  String get assetMini => 'take_photo1_mini1';
  @override
  double get assetMiniWidth => 20;
  @override
  double get assetMiniHeight => 20;
}

class TakeVideoButton extends ChatButton {
  const TakeVideoButton(super.c);

  @override
  void Function()? get onPressed => () async {
        c.field.focus.unfocus();
        await c.pickVideoFromCamera();
      };

  @override
  String get hint => 'label_take_video'.l10n;

  // @override
  // String get asset => 'video_message1';

  @override
  String get asset => 'take_video2';
  @override
  double get assetWidth => 27.99;
  @override
  double get assetHeight => 22;

  @override
  String get assetMini => 'take_video2_mini';
  @override
  double get assetMiniWidth => 25.71;
  @override
  double get assetMiniHeight => 20;

  @override
  Offset get offsetMini => const Offset(3, 0);
}

class GalleryButton extends ChatButton {
  const GalleryButton(super.c);

  @override
  void Function()? get onPressed => () async {
        c.field.focus.unfocus();
        await c.pickMedia();
      };

  @override
  String get hint => 'label_gallery'.l10n;

  @override
  String get asset => 'gallery_outlined';

  @override
  double get assetWidth => 22;

  @override
  double get assetHeight => 22;

  @override
  String get assetMini => 'gallery_outlined_mini';

  @override
  double get assetMiniWidth => 20;

  @override
  double get assetMiniHeight => 20;
}

class FileButton extends ChatButton {
  const FileButton(super.c);

  @override
  void Function()? get onPressed => () async {
        c.field.focus.unfocus();
        await c.pickFile();
      };

  @override
  String get hint => 'label_file'.l10n;

  @override
  String get asset => 'file_outlined';

  @override
  double get assetWidth => 18.8;

  @override
  double get assetHeight => 23;

  @override
  String get assetMini => 'file_outlined_mini';

  @override
  double get assetMiniWidth => 17.2;

  @override
  double get assetMiniHeight => 21;
}

class DonateButton extends ChatButton {
  const DonateButton(super.c);

  @override
  String get hint => 'Донат';

  @override
  String get asset => 'donate1';

  @override
  double get assetWidth => 24.93;

  @override
  double get assetHeight => 24;

  @override
  Offset get offset => const Offset(0, -1);

  @override
  String get assetMini => 'donate_mini';

  @override
  double get assetMiniWidth => 22.84;

  @override
  double get assetMiniHeight => 22;
}

class ContactButton extends ChatButton {
  const ContactButton(super.c);

  @override
  IconData? get icon => Icons.person;

  @override
  String get hint => 'Контакт';

  @override
  String get asset => 'video_on';
}

class GeopositionButton extends ChatButton {
  const GeopositionButton(super.c);

  @override
  IconData? get icon => Icons.pin_drop;

  @override
  String get hint => 'Геопозиция';

  @override
  String get asset => 'video_on';
}

class StickerButton extends ChatButton {
  const StickerButton(super.c);

  @override
  String get hint => 'Стикер';

  @override
  String get asset => 'smile';

  @override
  double get assetWidth => 23;

  @override
  double get assetHeight => 23;

  @override
  Offset get offset => const Offset(0, -1);

  @override
  String get assetMini => 'smile_mini';

  @override
  double get assetMiniWidth => 21;

  @override
  double get assetMiniHeight => 21;
}
