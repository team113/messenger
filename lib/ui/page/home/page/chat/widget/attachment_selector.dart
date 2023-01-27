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
import '/ui/page/call/widget/round_button.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';

/// Modal for choosing a source to pick an [Attachment] from.
///
/// Intended to be displayed with the [show] method.
class AttachmentSourceSelector extends StatelessWidget {
  const AttachmentSourceSelector({
    Key? key,
    this.onTakePhoto,
    this.onTakeVideo,
    this.onPickMedia,
    this.onPickFile,
  }) : super(key: key);

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
    Widget button({
      required String text,
      IconData? icon,
      Widget? child,
      void Function()? onPressed,
    }) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: RoundFloatingButton(
          text: text,
          withBlur: false,
          onPressed: () {
            onPressed?.call();
            Navigator.of(context).pop();
          },
          style: const TextStyle(fontSize: 15, color: Colors.black),
          color: Theme.of(context).colorScheme.secondary,
          child: SizedBox(
            width: 60,
            height: 60,
            child: child ?? Icon(icon, color: Colors.white, size: 30),
          ),
        ),
      );
    }

    List<Widget> children = [
      button(
        text:
            PlatformUtils.isAndroid ? 'label_photo'.l10n : 'label_camera'.l10n,
        onPressed: onTakePhoto,
        child: SvgLoader.asset(
          'assets/icons/make_photo.svg',
          width: 60,
          height: 60,
        ),
      ),
      if (PlatformUtils.isAndroid)
        button(
          text: 'label_video'.l10n,
          onPressed: onTakeVideo,
          child: SvgLoader.asset(
            'assets/icons/video_on.svg',
            width: 60,
            height: 60,
          ),
        ),
      button(
        text: 'label_gallery'.l10n,
        onPressed: onPickMedia,
        child: SvgLoader.asset(
          'assets/icons/gallery.svg',
          width: 60,
          height: 60,
        ),
      ),
      button(
        text: 'label_file'.l10n,
        onPressed: onPickFile,
        child: SvgLoader.asset(
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
          color: const Color(0xFFEEEEEE),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
