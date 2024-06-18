// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:async';

import 'package:flutter/material.dart';

import '/domain/model/attachment.dart';
import '/domain/model/file.dart';
import '/ui/page/home/widget/gallery_popup.dart';

/// [Attachment] to show in a [ChatGallery] along with its [onForbidden]
/// re-fetching it in case of forbidden error.
class GalleryAttachment {
  const GalleryAttachment(this.attachment, this.onForbidden);

  /// [Attachment] of this [GalleryAttachment].
  final Attachment attachment;

  /// Callback, called when the [attachment] loading fails with a forbidden
  /// network error.
  final FutureOr<void> Function()? onForbidden;
}

/// [GalleryPopup] displaying the provided [GalleryAttachment]s.
class ChatGallery extends StatefulWidget {
  const ChatGallery({
    super.key,
    required this.attachments,
    this.initial = (0, null),
  });

  /// [GalleryAttachment]s to display in a [GalleryPopup].
  final Iterable<GalleryAttachment> attachments;

  /// Initial index of a [GalleryAttachment] from the [attachments] to display
  /// along with its optional [GlobalKey] to animate the [GalleryPopup] from/to.
  final (int, GlobalKey?) initial;

  @override
  State<ChatGallery> createState() => _ChatGalleryState();
}

/// State of a [ChatGallery] updating the [GalleryItem.link]s on fetching
/// errors.
class _ChatGalleryState extends State<ChatGallery> {
  @override
  Widget build(BuildContext context) {
    final List<GalleryItem> gallery = [];

    for (var o in widget.attachments) {
      final StorageFile file = o.attachment.original;

      if (o.attachment is FileAttachment) {
        gallery.add(
          GalleryItem.video(
            file.url,
            o.attachment.filename,
            size: file.size,
            checksum: file.checksum,
            onError: () async {
              await o.onForbidden?.call();
              setState(() {});
            },
          ),
        );
      } else if (o.attachment is ImageAttachment) {
        file as ImageFile;

        gallery.add(
          GalleryItem.image(
            file.url,
            o.attachment.filename,
            size: file.size,
            width: file.width,
            height: file.height,
            checksum: file.checksum,
            thumbhash: (o.attachment as ImageAttachment).big.thumbhash,
            onError: () async {
              await o.onForbidden?.call();
              setState(() {});
            },
          ),
        );
      }
    }

    return GalleryPopup(
      children: gallery,
      initial: widget.initial.$1,
      initialKey: widget.initial.$2,
      onPageChanged: (i) {
        // TODO: Invoke next/previous here.
      },
    );
  }
}
