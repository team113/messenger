import 'package:flutter/material.dart';
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
  IconData? get icon => Icons.mic;

  @override
  String get hint => 'Аудио сообщение';

  @override
  String get asset => 'microphone_on';
}

class VideoMessageButton extends ChatButton {
  const VideoMessageButton(super.c);

  @override
  IconData? get icon => Icons.video_camera_back;

  @override
  String get hint => 'Видео сообщение';

  @override
  String get asset => 'video_on';
}

class AttachmentButton extends ChatButton {
  const AttachmentButton(super.c);

  @override
  IconData? get icon => Icons.attachment;

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
  String get hint => 'Прикрепление';

  @override
  String get asset => 'video_on';
}

class DonateButton extends ChatButton {
  const DonateButton(super.c);

  @override
  IconData? get icon => Icons.monetization_on_outlined;

  @override
  String get hint => 'Донат';

  @override
  String get asset => 'video_on';
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
