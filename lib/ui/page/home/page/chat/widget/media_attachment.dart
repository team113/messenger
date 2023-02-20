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

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/domain/model/file.dart';
import '/ui/page/home/page/chat/widget/video_thumbnail/video_thumbnail.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/svg/svg.dart';

/// Visual representation of a media [Attachment].
class MediaAttachment extends StatefulWidget {
  const MediaAttachment({
    super.key,
    required this.attachment,
    this.width,
    this.height,
    this.fit,
    this.autoLoad = true,
    this.onError,
  });

  /// [Attachment] to display.
  final Attachment attachment;

  /// Width of this [MediaAttachment].
  final double? width;

  /// Height of this [MediaAttachment].
  final double? height;

  /// [BoxFit] to apply to this [MediaAttachment].
  final BoxFit? fit;

  /// Indicator whether the [attachment] provided should be fetched as soon as
  /// this [MediaAttachment] is displayed.
  final bool autoLoad;

  /// Callback, called on the [Attachment] fetching errors.
  final Future<void> Function()? onError;

  @override
  State<MediaAttachment> createState() => _MediaAttachmentState();
}

/// State of a [MediaAttachment] caching [LocalAttachment]s on the
/// [didUpdateWidget] callbacks.
class _MediaAttachmentState extends State<MediaAttachment> {
  @override
  void didUpdateWidget(covariant MediaAttachment oldWidget) {
    if (oldWidget.attachment is LocalAttachment &&
        widget.attachment is! LocalAttachment) {
      final int size = (oldWidget.attachment as LocalAttachment).file.size;
      final Uint8List? bytes =
          (oldWidget.attachment as LocalAttachment).file.bytes.value;
      if (bytes != null && size == bytes.length) {
        FIFOCache.set(sha256.convert(bytes).toString(), bytes);
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final Attachment attachment = widget.attachment;

    final bool isImage = (attachment is ImageAttachment ||
        (attachment is LocalAttachment && attachment.file.isImage));

    if (isImage) {
      if (attachment is LocalAttachment) {
        return Obx(() {
          if (attachment.file.bytes.value == null) {
            return const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            if (attachment.file.isSvg) {
              return SvgLoader.bytes(
                attachment.file.bytes.value!,
                width: widget.width,
                height: widget.height,
              );
            } else {
              return Image.memory(
                attachment.file.bytes.value!,
                fit: widget.fit,
                width: widget.width,
                height: widget.height,
              );
            }
          }
        });
      } else {
        final StorageFile image;

        final StorageFile original = (attachment as ImageAttachment).original;
        if (original.checksum != null && FIFOCache.exists(original.checksum!)) {
          image = original;
        } else {
          image = attachment.big;
        }

        return RetryImage(
          image.url,
          checksum: image.checksum,
          fallback: attachment.small.url,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          onForbidden: widget.onError,
          cancelable: true,
          autoLoad: widget.autoLoad,
        );
      }
    } else {
      if (attachment is LocalAttachment) {
        return Obx(() {
          if (attachment.file.bytes.value == null) {
            return const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            return VideoThumbnail.bytes(
              bytes: attachment.file.bytes.value!,
              height: widget.height,
            );
          }
        });
      } else {
        return VideoThumbnail.url(
          url: attachment.original.url,
          checksum: attachment.original.checksum,
          height: widget.height,
          onError: widget.onError,
        );
      }
    }
  }
}
