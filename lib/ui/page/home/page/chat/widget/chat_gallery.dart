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
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/file.dart';
import '/domain/repository/paginated.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/util/obs/obs.dart';

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
    this.paginated,
    this.initial,
    this.rect,
  });

  /// [GalleryAttachment]s to display in a [GalleryPopup].
  final Paginated<ChatItemId, Rx<ChatItem>>? paginated;

  /// Initial index of a [GalleryAttachment] from the [attachments] to display
  /// along with its optional [GlobalKey] to animate the [GalleryPopup] from/to.
  final Attachment? initial;

  final GlobalKey? rect;

  @override
  State<ChatGallery> createState() => _ChatGalleryState();
}

/// State of a [ChatGallery] updating the [GalleryItem.link]s on fetching
/// errors.
class _ChatGalleryState extends State<ChatGallery> {
  StreamSubscription? _updates;
  StreamSubscription? _subscription;

  final List<_GalleryItem> _items = [];

  GalleryItem? _initial;

  List<GalleryItem> get _gallery => [
        if (_initial != null) _initial!,
        ..._items.expand((e) => e.gallery),
      ];

  int get _index => max(
        _gallery.indexWhere(
          (e) => e.checksum == widget.initial?.original.checksum,
        ),
        0,
      );

  @override
  void initState() {
    if (widget.initial != null) {
      _initial = _parse(widget.initial!);
    }

    widget.paginated?.around().then((_) {
      _initial = null;
      setState(() {});
    });

    _updates = widget.paginated?.updates.listen(null);
    _subscription = widget.paginated?.items.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          _add(e.value!.value);
          break;

        case OperationKind.updated:
          // TODO?
          break;

        case OperationKind.removed:
          // No-op?
          break;
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _updates?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GalleryPopup(
      children: _gallery,
      initial: _index,
      initialKey: widget.rect,
      onPageChanged: (i) async {
        if (i == 0) {
          await widget.paginated?.previous();
        }

        // TODO: Invoke next here as well.
      },
    );
  }

  void _add(ChatItem item) {
    print('add($item)');

    final List<Attachment> attachments = [];

    if (item is ChatMessage) {
      attachments.addAll(
        item.attachments.where(
          (e) => e is ImageAttachment || (e is FileAttachment && e.isVideo),
        ),
      );
    } else if (item is ChatForward) {
      final ChatItemQuote quote = item.quote;

      if (quote is ChatMessageQuote) {
        attachments.addAll(
          quote.attachments.where(
            (e) => e is ImageAttachment || (e is FileAttachment && e.isVideo),
          ),
        );
      }
    }

    _items.add(
      _GalleryItem(
        item: item,
        gallery: attachments.map(_parse).whereNotNull().toList(),
      ),
    );

    _items.sort((a, b) {
      return a.item.key.compareTo(b.item.key);
    });

    setState(() {});
  }

  GalleryItem? _parse(Attachment o) {
    final StorageFile file = o.original;

    if (o is FileAttachment) {
      return GalleryItem.video(
        file.url,
        o.filename,
        size: file.size,
        checksum: file.checksum,
        // onError: () async {
        //   await o.onForbidden?.call();
        //   setState(() {});
        // },
      );
    } else if (o is ImageAttachment) {
      file as ImageFile;

      return GalleryItem.image(
        file.url,
        o.filename,
        size: file.size,
        width: file.width,
        height: file.height,
        checksum: file.checksum,
        thumbhash: o.big.thumbhash,
        // onError: () async {
        //   await o.onForbidden?.call();
        //   setState(() {});
        // },
      );
    }

    return null;
  }
}

class _GalleryItem {
  _GalleryItem({
    required this.item,
    required this.gallery,
  });

  ChatItem item;
  List<GalleryItem> gallery;
}
