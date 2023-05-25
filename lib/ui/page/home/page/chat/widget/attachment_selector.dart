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
import 'package:path/path.dart';

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import 'attachment_button.dart';

/// Modal for choosing a source to pick an [Attachment] from.
///
/// Intended to be displayed with the [show] method.
class AttachmentSourceSelector extends StatelessWidget {
  const AttachmentSourceSelector({
    super.key,
    this.onTakePhoto,
    this.onTakeVideo,
    this.onPickMedia,
    this.onPickFile,
  });

  /// Callback, called when a take photo action is triggered.
  final void Function()? onTakePhoto;

  /// Callback, called when a take video action is triggered.
  final void Function()? onTakeVideo;

  /// Callback, called when a pick media action is triggered.
  final void Function()? onPickMedia;

  /// Callback, called when a pick file action is triggered.
  final void Function()? onPickFile;

  /// Displays an [AttachmentSourceSelector] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    void Function()? onTakePhoto,
    void Function()? onTakeVideo,
    void Function()? onPickMedia,
    void Function()? onPickFile,
  }) {
    return ModalPopup.show(
      context: context,
      mobileConstraints: const BoxConstraints(),
      mobilePadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      desktopConstraints: const BoxConstraints(maxWidth: 400),
      child: AttachmentSourceSelector(
        onTakePhoto: onTakePhoto,
        onTakeVideo: onTakeVideo,
        onPickMedia: onPickMedia,
        onPickFile: onPickFile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    List<Widget> children = [
      AttachmentButton(
        icon: null,
        text:
            PlatformUtils.isAndroid ? 'label_photo'.l10n : 'label_camera'.l10n,
        onPressed: onTakePhoto,
        child: SvgImage.asset(
          'assets/icons/make_photo.svg',
          width: 60,
          height: 60,
        ),
      ),
      if (PlatformUtils.isAndroid)
        AttachmentButton(
          icon: null,
          text: 'label_video'.l10n,
          onPressed: onTakeVideo,
          child: SvgImage.asset(
            'assets/icons/video_on.svg',
            width: 60,
            height: 60,
          ),
        ),
      AttachmentButton(
        icon: null,
        text: 'label_gallery'.l10n,
        onPressed: onPickMedia,
        child: SvgImage.asset(
          'assets/icons/gallery.svg',
          width: 60,
          height: 60,
        ),
      ),
      AttachmentButton(
        icon: null,
        text: 'label_file'.l10n,
        onPressed: onPickFile,
        child: SvgImage.asset(
          'assets/icons/file.svg',
          width: 60,
          height: 60,
        ),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: children,
        ),
        const SizedBox(height: 40),
        OutlinedRoundedButton(
          key: const Key('CloseButton'),
          title: Text('btn_close'.l10n),
          onPressed: Navigator.of(context).pop,
          color: style.colors.secondaryHighlight,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
