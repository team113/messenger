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

/// [GalleryPopup] displaying the provided [Paginated] of [Attachment]s.
class ChatGallery extends StatefulWidget {
  const ChatGallery({
    super.key,
    this.paginated,
    this.initial,
    this.rect,
    this.onForbidden,
  });

  /// [Paginated] to display in a [GalleryPopup].
  final Paginated<ChatItemId, Rx<ChatItem>>? paginated;

  /// Initial [Attachment] and a [ChatItem] containing it to display initially
  /// in a [GalleryPopup].
  final (ChatItem?, Attachment)? initial;

  /// [GlobalKey] of the widget to display [GalleryPopup] expanding from.
  final GlobalKey? rect;

  /// Callback, called when an [Attachment] loading fails with a forbidden
  /// network error.
  final FutureOr<void> Function(ChatItem?)? onForbidden;

  @override
  State<ChatGallery> createState() => _ChatGalleryState();
}

/// State of a [ChatGallery] updating the [GalleryItem.link]s on fetching
/// errors.
class _ChatGalleryState extends State<ChatGallery> {
  /// [Paginated.updates] subscription keeping it alive.
  StreamSubscription? _updates;

  /// [Paginated.items] subscription for receiving items updates.
  StreamSubscription? _subscription;

  /// [_GalleryItem]s to sort and then pass to the [_gallery].
  final List<_GalleryItem> _items = [];

  /// Initial [GalleryItem] to display in a [GalleryPopup] widget.
  GalleryItem? _initial;

  /// Returns the [GalleryItem] to pass to a [GalleryPopup].
  List<GalleryItem> get _gallery => [
        if (_initial != null) _initial!,
        ..._items.expand((e) => e.gallery),
      ];

  /// Index of the [_initial] attachment in the [_gallery] list.
  int get _index => max(
      _gallery.indexWhere(
        (e) => widget.initial?.$1 == null
            ? e.id?.endsWith('${widget.initial?.$2.id}') == true
            : e.id == '${widget.initial?.$1?.id}_${widget.initial?.$2.id}',
      ),
      0);

  @override
  void initState() {
    if (widget.initial != null) {
      _initial = _parse(widget.initial!.$2, item: widget.initial?.$1);
    }

    // After the initial page is fetched, try to fetch the previous one and set
    // the [_initial] to `null` so it doesn't mess the indexes in
    // [GalleryPopup].
    widget.paginated?.around().then((_) async {
      if (mounted) {
        _initial = null;
        setState(() {});

        final int i = _index;

        if (i == 0) {
          await widget.paginated?.previous();
        }
      }
    });

    _updates = widget.paginated?.updates.listen(null);
    _subscription = widget.paginated?.items.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          _add(e.value!.value);
          break;

        case OperationKind.updated:
          final existing = _items.firstWhereOrNull((o) => o.item.id == e.key);
          if (existing != null) {
            _items.remove(existing);
          }
          _add(e.value!.value);
          break;

        case OperationKind.removed:
          final existing = _items.firstWhereOrNull((o) => o.item.id == e.key);
          if (existing != null) {
            _items.remove(existing);
          }
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
    return Obx(() {
      return GalleryPopup(
        children: _gallery,
        initial: _index,
        initialKey: widget.rect,
        onPageChanged: (i) async {
          if (i == 0) {
            await widget.paginated?.previous();
          } else if (i == _gallery.length - 1) {
            await widget.paginated?.next();
          }
        },
        nextLoading: widget.paginated?.nextLoading.value ?? false,
        previousLoading: widget.paginated?.previousLoading.value ?? false,
      );
    });
  }

  /// Adds the [Attachment]s from the provided [item] to the [_items] and sorts
  /// those.
  void _add(ChatItem item) {
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
        gallery: attachments
            .map((e) => _parse(e, item: item))
            .whereNotNull()
            .toList(),
      ),
    );

    _items.sort((a, b) {
      return a.item.key.compareTo(b.item.key);
    });

    setState(() {});
  }

  /// Returns the [GalleryItem] used by [GalleryPopup] from the provided
  /// [Attachment] and its [ChatItem], if any.
  GalleryItem? _parse(Attachment o, {ChatItem? item}) {
    final StorageFile file = o.original;

    if (o is FileAttachment) {
      return GalleryItem.video(
        file.url,
        o.filename,
        id: '${item?.id}_${o.id}',
        size: file.size,
        checksum: file.checksum,
        onError: () async {
          await widget.onForbidden?.call(item);
          setState(() {});
        },
      );
    } else if (o is ImageAttachment) {
      file as ImageFile;

      return GalleryItem.image(
        file.url,
        o.filename,
        id: '${item?.id}_${o.id}',
        size: file.size,
        width: file.width,
        height: file.height,
        checksum: file.checksum,
        thumbhash: o.big.thumbhash,
        onError: () async {
          await widget.onForbidden?.call(item);
          setState(() {});
        },
      );
    }

    return null;
  }
}

/// [ChatItem] with the list of [GalleryItem]s it contains.
class _GalleryItem {
  const _GalleryItem({required this.item, required this.gallery});

  /// [ChatItem] this [_GalleryItem] is about.
  final ChatItem item;

  /// [GalleryItem] the [item] contains.
  final List<GalleryItem> gallery;
}
