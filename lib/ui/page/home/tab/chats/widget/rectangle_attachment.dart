// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model/attachment.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/video_thumbnail/video_thumbnail.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/svg/svg.dart';

/// Small rectangular [Attachment].
class RectangleAttachment extends StatelessWidget {
  const RectangleAttachment(
    this.attachment, {
    super.key,
    this.inverted = false,
    this.onError,
  });

  /// [Attachment] to display.
  final Attachment attachment;

  /// Indicator whether the icons displayed should have inverted colors.
  final bool inverted;

  /// Callback, called when 403 error happens with the provided [attachment]
  /// fetching.
  final Future<void> Function()? onError;

  @override
  Widget build(BuildContext context) {
    Widget? content;

    final style = Theme.of(router.context!).style;
    final Attachment e = attachment;

    if (e is LocalAttachment) {
      if (e.file.isImage && e.file.bytes.value != null) {
        content = Image.memory(e.file.bytes.value!, fit: BoxFit.cover);
      } else if (e.file.isVideo) {
        if (e.file.path == null) {
          if (e.file.bytes.value == null) {
            content = Container(
              color: inverted ? style.colors.onPrimary : style.colors.secondary,
              child: Icon(
                Icons.video_file,
                size: 18,
                color: inverted
                    ? style.colors.secondary
                    : style.colors.onPrimary,
              ),
            );
          } else {
            content = FittedBox(
              fit: BoxFit.cover,
              child: VideoThumbnail.bytes(
                e.file.bytes.value!,
                key: key,
                height: 300,
                interface: false,
                autoplay: true,
              ),
            );
          }
        } else {
          content = FittedBox(
            fit: BoxFit.cover,
            child: VideoThumbnail.file(
              e.file.path!,
              key: key,
              height: 300,
              interface: false,
              autoplay: true,
            ),
          );
        }
      } else {
        content = Container(
          color: inverted ? style.colors.onPrimary : style.colors.secondary,
          child: Center(
            child: SvgIcon(
              inverted ? SvgIcons.fileSmall : SvgIcons.fileSmallWhite,
            ),
          ),
        );
      }
    }

    if (e is ImageAttachment) {
      content = RetryImage(
        e.small.url,
        checksum: e.small.checksum,
        thumbhash: e.small.thumbhash,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        onForbidden: onError,
        displayProgress: false,
      );
    }

    if (e is FileAttachment) {
      if (e.isVideo) {
        content = FittedBox(
          fit: BoxFit.cover,
          child: VideoThumbnail.url(
            e.original.url,
            checksum: e.original.checksum,
            key: key,
            height: 300,
            onError: onError,
            interface: false,
            autoplay: true,
          ),
        );
      } else {
        content = Container(
          color: inverted ? style.colors.onPrimary : style.colors.secondary,
          child: Center(
            child: SvgIcon(
              inverted ? SvgIcons.fileSmall : SvgIcons.fileSmallWhite,
            ),
          ),
        );
      }
    }

    if (content != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(width: 30, height: 30, child: content),
      );
    }

    return const SizedBox();
  }
}
