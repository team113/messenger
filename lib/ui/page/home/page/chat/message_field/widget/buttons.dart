// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import '/l10n/l10n.dart';
import '/ui/page/home/page/chat/message_field/controller.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';

/// Button in a [MessageFieldView].
abstract class ChatButton {
  const ChatButton([this.onPressed]);

  /// Callback, called when this [ChatButton] is pressed.
  final void Function()? onPressed;

  /// Returns a text-represented hint for this [ChatButton].
  String get hint;

  /// Asset name of this [ChatButton].
  SvgData get asset;

  /// Asset offset of this [ChatButton].
  Offset get offset => Offset.zero;

  /// Asset name of this [ChatButton] in mini mode.
  SvgData? get assetMini => null;

  /// Asset offset of this [ChatButton] in mini mode.
  Offset get offsetMini => Offset.zero;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) =>
      other is ChatButton && runtimeType == other.runtimeType;
}

/// [ChatButton] recording an audio massage.
class AudioMessageButton extends ChatButton {
  const AudioMessageButton([super.onPressed]);

  @override
  String get hint => 'btn_audio_message'.l10n;

  @override
  SvgData get asset => SvgIcons.audioMessage;

  @override
  SvgData get assetMini => SvgIcons.audioMessageSmall;
}

/// [ChatButton] recording a video massage.
class VideoMessageButton extends ChatButton {
  const VideoMessageButton([super.onPressed]);

  @override
  String get hint => 'btn_video_message'.l10n;

  @override
  SvgData get asset => SvgIcons.videoMessage;

  @override
  SvgData get assetMini => SvgIcons.videoMessageSmall;
}

/// [ChatButton] attaching a file.
class AttachmentButton extends ChatButton {
  const AttachmentButton([super.onPressed]);

  @override
  String get hint => 'btn_file'.l10n;

  @override
  SvgData get asset => SvgIcons.fileOutlined;

  @override
  SvgData get assetMini => SvgIcons.fileOutlinedSmall;
}

/// [ChatButton] taking a photo.
class TakePhotoButton extends ChatButton {
  const TakePhotoButton([super.onPressed]);

  @override
  String get hint =>
      PlatformUtils.isAndroid ? 'btn_take_photo'.l10n : 'btn_camera'.l10n;

  @override
  SvgData get asset =>
      PlatformUtils.isAndroid ? SvgIcons.takePhoto : SvgIcons.takeVideo;

  @override
  SvgData get assetMini => PlatformUtils.isAndroid
      ? SvgIcons.takePhotoSmall
      : SvgIcons.takeVideoSmall;
}

/// [ChatButton] taking a video.
class TakeVideoButton extends ChatButton {
  const TakeVideoButton([super.onPressed]);

  @override
  String get hint => 'btn_take_video'.l10n;

  @override
  SvgData get asset => SvgIcons.takeVideo;

  @override
  Offset get offset => const Offset(0, -1.5);

  @override
  SvgData get assetMini => SvgIcons.takeVideoSmall;

  @override
  Offset get offsetMini => const Offset(2, 0);
}

/// [ChatButton] opening a gallery.
class GalleryButton extends ChatButton {
  const GalleryButton([super.onPressed]);

  @override
  String get hint => 'btn_gallery'.l10n;

  @override
  SvgData get asset => SvgIcons.gallery;

  @override
  SvgData get assetMini => SvgIcons.gallerySmall;
}

/// [ChatButton] making a gift.
class DonateButton extends ChatButton {
  const DonateButton([super.onPressed]);

  @override
  String get hint => 'btn_gift'.l10n;

  @override
  SvgData get asset => SvgIcons.gift;

  @override
  Offset get offset => const Offset(0, -1);

  @override
  SvgData get assetMini => SvgIcons.giftSmall;
}

/// [ChatButton] attaching a file.
class FileButton extends ChatButton {
  const FileButton([super.onPressed]);

  @override
  String get hint => 'btn_file'.l10n;

  @override
  SvgData get asset => SvgIcons.fileOutlined;

  @override
  SvgData get assetMini => SvgIcons.fileOutlinedSmall;
}

/// [ChatButton] opening the stickers.
class StickerButton extends ChatButton {
  const StickerButton([super.onPressed]);

  @override
  String get hint => 'btn_sticker'.l10n;

  @override
  SvgData get asset => SvgIcons.smile;

  @override
  Offset get offset => const Offset(0, -1);

  @override
  SvgData get assetMini => SvgIcons.smileSmall;
}
