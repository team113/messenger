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
import '/util/platform_utils.dart';

/// Button in a [MessageFieldView].
abstract class ChatButton {
  const ChatButton([this.onPressed]);

  /// Callback, called when this [CallButton] is pressed.
  final void Function()? onPressed;

  /// Returns a text-represented hint for this [CallButton].
  String get hint;

  /// Asset name of this [CallButton].
  String get asset;

  /// Asset width of this [CallButton].
  double get assetWidth => 26;

  /// Asset height of this [CallButton].
  double get assetHeight => 22;

  /// Asset offset of this [CallButton].
  Offset get offset => Offset.zero;

  /// Asset name of this [CallButton] in mini mode.
  String? get assetMini => null;

  /// Asset width of this [CallButton] in mini mode.
  double? get assetMiniWidth => 26;

  /// Asset height of this [CallButton] in mini mode.
  double? get assetMiniHeight => 22;

  /// Asset offset of this [CallButton] in mini mode.
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
  String get hint => 'label_audio_message'.l10n;

  @override
  String get asset => 'audio_message';

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

/// [ChatButton] recording an video massage.
class VideoMessageButton extends ChatButton {
  const VideoMessageButton([super.onPressed]);

  @override
  String get hint => 'label_video_message'.l10n;

  @override
  String get asset => 'video_message';

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

/// [ChatButton] attaching a file.
class AttachmentButton extends ChatButton {
  const AttachmentButton([super.onPressed]);

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

/// [ChatButton] taking a photo.
class TakePhotoButton extends ChatButton {
  const TakePhotoButton([super.onPressed]);

  @override
  String get hint =>
      PlatformUtils.isAndroid ? 'label_take_photo'.l10n : 'label_camera'.l10n;

  @override
  String get asset => 'take_photo';

  @override
  double get assetWidth => 22;

  @override
  double get assetHeight => 22;

  @override
  String get assetMini => 'take_photo_mini';

  @override
  double get assetMiniWidth => 20;

  @override
  double get assetMiniHeight => 20;
}

/// [ChatButton] taking a video.
class TakeVideoButton extends ChatButton {
  const TakeVideoButton([super.onPressed]);

  @override
  String get hint => 'label_take_video'.l10n;

  @override
  String get asset => 'take_video';

  @override
  double get assetWidth => 27.99;

  @override
  double get assetHeight => 22;

  @override
  String get assetMini => 'take_video_mini';

  @override
  double get assetMiniWidth => 25.71;

  @override
  double get assetMiniHeight => 20;

  @override
  Offset get offsetMini => const Offset(3, 0);
}

/// [ChatButton] opening a gallery.
class GalleryButton extends ChatButton {
  const GalleryButton([super.onPressed]);

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

/// [ChatButton] making a gift.
class DonateButton extends ChatButton {
  const DonateButton([super.onPressed]);

  @override
  String get hint => 'label_gift'.l10n;

  @override
  String get asset => 'donate';

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

/// [ChatButton] attaching a file.
class FileButton extends ChatButton {
  const FileButton([super.onPressed]);

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

/// [ChatButton] opening a stickers table.
class StickerButton extends ChatButton {
  const StickerButton([super.onPressed]);

  @override
  String get hint => 'label_sticker'.l10n;

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
