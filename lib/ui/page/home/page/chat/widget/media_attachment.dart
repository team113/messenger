import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '/domain/model/attachment.dart';
import '/ui/page/home/page/chat/widget/video_thumbnail/video_thumbnail.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/svg/svg.dart';

/// Visual representation of an media [Attachment].
class MediaAttachment extends StatefulWidget {
  const MediaAttachment({required this.attachment, this.size, super.key});

  /// [Attachment] to display.
  final Attachment attachment;

  /// Size of this [MediaAttachment].
  final double? size;

  @override
  State<MediaAttachment> createState() => _MediaAttachmentState();
}

class _MediaAttachmentState extends State<MediaAttachment> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MediaAttachment oldWidget) {
    if (oldWidget.attachment is LocalAttachment &&
        widget.attachment is! LocalAttachment) {
      int size = (oldWidget.attachment as LocalAttachment).file.size;
      Uint8List? bytes = (oldWidget.attachment as LocalAttachment).file.bytes;
      if (bytes != null && size == bytes.length) {
        FIFOCache.set(widget.attachment.original.url, bytes);
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final Attachment attachment = widget.attachment;

    final bool isImage = (attachment is ImageAttachment ||
        (attachment is LocalAttachment && attachment.file.isImage));
    // final bool isVideo = (attachment is FileAttachment && attachment.isVideo) ||
    //     (attachment is LocalAttachment && attachment.file.isVideo);

    if (isImage) {
      if (attachment is LocalAttachment) {
        if (attachment.file.bytes == null) {
          if (attachment.file.path == null) {
            return const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            if (attachment.file.isSvg) {
              return SvgLoader.file(
                File(attachment.file.path!),
                width: widget.size,
                height: widget.size,
              );
            } else {
              return Image.file(
                File(attachment.file.path!),
                fit: BoxFit.cover,
                width: widget.size,
                height: widget.size,
              );
            }
          }
        } else {
          if (attachment.file.isSvg) {
            return SvgLoader.bytes(
              attachment.file.bytes!,
              width: widget.size,
              height: widget.size,
            );
          } else {
            return Image.memory(
              attachment.file.bytes!,
              fit: BoxFit.cover,
              width: widget.size,
              height: widget.size,
            );
          }
        }
      } else {
        return RetryImage(
          attachment.original.url,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
        );
      }
    } else {
      if (attachment is LocalAttachment) {
        if (attachment.file.bytes == null) {
          return const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          return VideoThumbnail.bytes(bytes: attachment.file.bytes!);
        }
      } else {
        return VideoThumbnail.url(url: attachment.original.url);
      }
    }
  }
}
