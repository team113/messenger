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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/domain/model/file.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/video_thumbnail/video_thumbnail.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/worker/cache.dart';

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
        CacheWorker.instance.add(bytes);
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final Attachment attachment = widget.attachment;

    final bool isImage = (attachment is ImageAttachment ||
        (attachment is LocalAttachment && attachment.file.isImage));

    final Widget child;

    if (isImage) {
      if (attachment is LocalAttachment) {
        child = Obx(() {
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
              return SvgImage.bytes(
                attachment.file.bytes.value!,
                width: widget.width,
                height: widget.height,
              );
            } else {
              final Size? dimensions = attachment.file.dimensions.value;
              final double ratio =
                  (dimensions?.width ?? 300) / (dimensions?.height ?? 300);

              return Image.memory(
                attachment.file.bytes.value!,
                fit: widget.fit ?? (ratio > 3 ? BoxFit.contain : BoxFit.cover),
                width: widget.width,
                height: widget.height,
              );
            }
          }
        });
      } else {
        final ImageFile file = attachment.original as ImageFile;
        final double ratio = (file.width ?? 300) / (file.height ?? 300);

        child = RetryImage.attachment(
          attachment as ImageAttachment,
          fit: widget.fit ?? (ratio > 3 ? BoxFit.contain : BoxFit.cover),
          width: widget.width,
          height: widget.height,
          onForbidden: widget.onError,
          cancelable: true,
          autoLoad: widget.autoLoad,
        );
      }
    } else {
      if (attachment is LocalAttachment) {
        if (attachment.file.path == null) {
          child = Obx(() {
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
                attachment.file.bytes.value!,
                height: widget.height,
                width: widget.width,
              );
            }
          });
        } else {
          child = VideoThumbnail.file(
            attachment.file.path!,
            height: widget.height,
            width: widget.width,
          );
        }
      } else {
        child = VideoThumbnail.url(
          attachment.original.url,
          checksum: attachment.original.checksum,
          height: widget.height,
          width: widget.width,
          onError: widget.onError,
        );
      }
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Obx(() {
          if (attachment.isDownloading) {
            return Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.colors.onBackgroundOpacity27,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Center(
                    child: Icon(Icons.download, color: style.colors.onPrimary),
                  ),
                ),
              ),
            );
          } else {
            return const SizedBox();
          }
        }),
      ],
    );
  }
}
