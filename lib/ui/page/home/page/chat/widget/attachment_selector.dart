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
import '/themes.dart';
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
    final style = Theme.of(context).style;

    List<Widget> children = [
      _AttachmentButton(
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
        _AttachmentButton(
          text: 'label_video'.l10n,
          onPressed: onTakeVideo,
          child: SvgImage.asset(
            'assets/icons/video_on.svg',
            width: 60,
            height: 60,
          ),
        ),
      _AttachmentButton(
        text: 'label_gallery'.l10n,
        onPressed: onPickMedia,
        child: SvgImage.asset(
          'assets/icons/gallery.svg',
          width: 60,
          height: 60,
        ),
      ),
      _AttachmentButton(
        text: 'label_file'.l10n,
        onPressed: onPickFile,
        child: Center(
          child: SvgImage.asset('assets/icons/file.svg', height: 29),
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

/// Custom styled [RoundFloatingButton].
class _AttachmentButton extends StatelessWidget {
  const _AttachmentButton({this.text, this.child, this.onPressed});

  /// Text displayed on this [_AttachmentButton].
  final String? text;

  /// [Widget] displayed on this [_AttachmentButton].
  final Widget? child;

  /// Callback, called when this [_AttachmentButton] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: RoundFloatingButton(
        text: text,
        withBlur: false,
        onPressed: () {
          onPressed?.call();
          Navigator.of(context).pop();
        },
        style: fonts.titleMedium!,
        color: style.colors.primary,
        child: SizedBox(width: 60, height: 60, child: child),
      ),
    );
  }
}
