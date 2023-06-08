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

import '/domain/model/attachment.dart';
import '/domain/model/file.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/widget/gallery_popup.dart';

/// Wrapper around [GalleryPopup] showing a chat gallery.
class ChatGallery extends StatefulWidget {
  const ChatGallery({
    super.key,
    required this.attachments,
    this.initial = 0,
    this.initialKey,
  });

  /// [List] of [GalleryAttachment]s to display in a gallery.
  final Iterable<GalleryAttachment> attachments;

  /// Optional [GlobalKey] of the [Object] to animate gallery from/to.
  final GlobalKey? initialKey;

  /// Initial gallery index of the [GalleryAttachment]s in [attachments].
  final int initial;

  @override
  State<ChatGallery> createState() => _ChatGalleryState();
}

/// State of the [ChatGallery] used to update [GalleryItem.link]s on fetching
/// errors.
class _ChatGalleryState extends State<ChatGallery> {
  @override
  Widget build(BuildContext context) {
    List<GalleryItem> gallery = [];
    for (var o in widget.attachments) {
      final StorageFile file = o.attachment.original;
      GalleryItem? item;

      if (o.attachment is FileAttachment) {
        item = GalleryItem.video(
          file.url,
          o.attachment.filename,
          size: file.size,
          checksum: file.checksum,
          onError: () async {
            await o.onForbidden?.call();
            setState(() {});
          },
        );
      } else if (o.attachment is ImageAttachment) {
        item = GalleryItem.image(
          file.url,
          o.attachment.filename,
          size: file.size,
          checksum: file.checksum,
          onError: () async {
            await o.onForbidden?.call();
            setState(() {});
          },
        );
      }

      gallery.add(item!);
    }

    return GalleryPopup(
      children: gallery,
      initial: widget.initial,
      initialKey: widget.initialKey,
    );
  }
}
