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

/// [PlayerView] with the fixed [MediaItem]s list.
class RegularGallery extends StatelessWidget {
  const RegularGallery({
    super.key,
    this.items = const [],
    this.resourceId,
    this.onReply,
    this.onShare,
    this.onScrollTo,
  });

  /// [MediaItem]s themselves.
  final List<MediaItem> items;

  /// [ResourceId] to pass to a [PlayerView].
  final ResourceId? resourceId;

  /// Callback, called when a reply action within [Post] is triggered.
  final void Function(Post)? onReply;

  /// Callback, called when a share action within [Post] is triggered.
  final void Function(Post)? onShare;

  /// Callback, called when a scroll to [Post] action is triggered.
  final void Function(Post)? onScrollTo;

  @override
  Widget build(BuildContext context) {
    return PlayerView(
      source: FixedItemsPaginated({
        for (var e in items) ...{e.id: e},
      }),
      resourceId: resourceId,
      onReply: onReply,
      onShare: onShare,
      onScrollTo: onScrollTo,
    );
  }
}

/// [PlayerView] displaying the provided [Paginated] of [Attachment]s.
class PaginatedGallery extends StatefulWidget {
  const PaginatedGallery({
    super.key,
    this.paginated,
    this.resourceId,
    this.initial,
    this.onReply,
    this.onShare,
    this.onScrollTo,
  });

  /// [Paginated] to display in a [PlayerView].
  final Paginated<ChatItemId, Rx<ChatItem>>? paginated;

  /// [ResourceId] to pass to a [PlayerView].
  final ResourceId? resourceId;

  /// Initial [Attachment] and a [ChatItem] containing it to display initially
  /// in a [PlayerView].
  final (String, int)? initial;

  /// Callback, called when a reply action within [Post] is triggered.
  final void Function(Post)? onReply;

  /// Callback, called when a reply action within [Post] is triggered.
  final void Function(Post)? onShare;

  /// Callback, called when a scroll to [Post] action is triggered.
  final void Function(Post)? onScrollTo;

  @override
  State<PaginatedGallery> createState() => _PaginatedGalleryState();
}

/// State of a [PaginatedGallery] updating the [MediaItem]s on fetching errors.
class _PaginatedGalleryState extends State<PaginatedGallery> {
  /// [Paginated.updates] subscription keeping it alive.
  StreamSubscription? _updates;

  /// [Paginated.items] subscription for receiving items updates.
  StreamSubscription? _subscription;

  /// Initial [MediaItem] to display in a [PlayerView] widget.
  MediaItem? _initial;

  /// [FixedItemsPaginated] of the [MediaItem]s converted from the source
  /// [Paginated] of [ChatItem]s.
  late final FixedItemsPaginated<String, MediaItem> _paginated =
      FixedItemsPaginated(
        {},
        onNext: () async {
          _paginated.nextLoading.value = true;

          try {
            await widget.paginated?.next();
            _paginated.hasNext.value = widget.paginated?.hasNext.value ?? false;
          } finally {
            _paginated.nextLoading.value = false;
          }
        },
        onPrevious: () async {
          _paginated.previousLoading.value = true;

          try {
            await widget.paginated?.previous();
            _paginated.hasPrevious.value =
                widget.paginated?.hasPrevious.value ?? false;
          } finally {
            _paginated.previousLoading.value = false;
          }
        },
      );

  @override
  void initState() {
    _paginated.items.addAll({
      if (_initial != null) ...{_initial!.id: _initial!},
    });

    _paginated.hasNext.value = widget.paginated?.hasNext.value ?? false;
    _paginated.hasPrevious.value = widget.paginated?.hasPrevious.value ?? false;

    // After the initial page is fetched, try to fetch the previous one and set
    // the [_initial] to `null` so it doesn't mess the indexes in [PlayerView].
    widget.paginated?.around().then((_) async {
      _paginated.hasNext.value = widget.paginated?.hasNext.value ?? false;
      _paginated.hasPrevious.value =
          widget.paginated?.hasPrevious.value ?? false;

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
      final bool hasNext = widget.paginated?.hasNext.value ?? false;
      final bool hasPrevious = widget.paginated?.hasPrevious.value ?? false;

      _paginated.hasNext.value = hasNext;
      _paginated.hasPrevious.value = hasPrevious;

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
      resourceId: widget.resourceId,
      onReply: widget.onReply,
      onShare: widget.onShare,
      onScrollTo: widget.onScrollTo,
      initialKey: widget.initial?.$1,
      initialIndex: widget.initial?.$2 ?? 0,
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

    if (attachments.isNotEmpty) {
      final MediaItem media = MediaItem(attachments, item);
      _paginated.items[media.id] = media;
      setState(() {});
    }
  }
}
