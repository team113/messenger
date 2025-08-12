// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/chat_item.dart';
import '/domain/repository/paginated.dart';
import '/ui/page/player/controller.dart';
import '/ui/page/player/view.dart';
import '/util/obs/obs.dart';

class RegularGallery extends StatelessWidget {
  const RegularGallery({
    super.key,
    this.items = const [],
    this.onReply,
    this.onShare,
  });

  final List<MediaItem> items;
  final void Function(MediaItem)? onReply;
  final void Function(MediaItem)? onShare;

  @override
  Widget build(BuildContext context) {
    return PlayerView(
      source: FixedItemsPaginated({
        for (var e in items) ...{e.id: e},
      }),
      onReply: onReply,
      onShare: onShare,
    );
  }
}

/// [PlayerView] displaying the provided [Paginated] of [Attachment]s.
class PaginatedGallery extends StatefulWidget {
  const PaginatedGallery({
    super.key,
    this.paginated,
    this.initial,
    this.rect,
    this.onForbidden,
    this.onReply,
    this.onShare,
  });

  /// [Paginated] to display in a [PlayerView].
  final Paginated<ChatItemId, Rx<ChatItem>>? paginated;

  /// Initial [Attachment] and a [ChatItem] containing it to display initially
  /// in a [PlayerView].
  final (ChatItem?, Attachment)? initial;

  /// [GlobalKey] of the widget to display [PlayerView] expanding from.
  final GlobalKey? rect;

  /// Callback, called when an [Attachment] loading fails with a forbidden
  /// network error.
  final FutureOr<void> Function(ChatItem?)? onForbidden;

  final void Function(MediaItem)? onReply;
  final void Function(MediaItem)? onShare;

  @override
  State<PaginatedGallery> createState() => _PaginatedGalleryState();
}

/// State of a [PaginatedGallery] updating the [GalleryItem.link]s on fetching
/// errors.
class _PaginatedGalleryState extends State<PaginatedGallery> {
  /// [Paginated.updates] subscription keeping it alive.
  StreamSubscription? _updates;

  /// [Paginated.items] subscription for receiving items updates.
  StreamSubscription? _subscription;

  /// Initial [MediaItem] to display in a [PlayerView] widget.
  MediaItem? _initial;

  final FixedItemsPaginated<String, MediaItem> _paginated = FixedItemsPaginated(
    {},
  );

  @override
  void initState() {
    _paginated.items.addAll({
      if (_initial != null) ...{_initial!.id: _initial!},
    });

    // After the initial page is fetched, try to fetch the previous one and set
    // the [_initial] to `null` so it doesn't mess the indexes in [PlayerView].
    widget.paginated?.around().then((_) async {
      if (mounted) {
        _initial = null;
        setState(() {});

        if (widget.paginated?.values.firstOrNull?.value.key.toString() ==
            _initial?.id) {
          await widget.paginated?.previous();
        }
      }
    });

    _updates = widget.paginated?.updates.listen(null);

    if (widget.paginated != null) {
      for (var e in widget.paginated!.items.values) {
        _add(e.value);
      }
    }

    _subscription = widget.paginated?.items.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
        case OperationKind.updated:
          // TODO: Refactor to change the values instead of removing?
          _paginated.items.removeWhere((key, _) => key.startsWith('${e.key}_'));
          _add(e.value!.value);
          break;

        case OperationKind.removed:
          _paginated.items.removeWhere((key, _) => key.startsWith('${e.key}_'));
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
    return PlayerView(
      source: _paginated,
      onReply: widget.onReply,
      onShare: widget.onShare,
      initialKey: widget.initial?.$1?.key.toString(),
      initialIndex: _parseInitialIndex(widget.initial?.$1),
    );
  }

  int _parseInitialIndex(ChatItem? item) {
    if (item is! ChatMessage) {
      return 0;
    }

    return max(
      0,
      item.attachments.indexWhere((e) => e.id == widget.initial?.$2.id),
    );
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

    final MediaItem media = MediaItem(attachments, item);
    _paginated.items[media.id] = media;

    setState(() {});
  }
}
