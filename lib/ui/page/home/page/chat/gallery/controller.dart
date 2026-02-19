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

import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '/config.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/paginated.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/chat/widget/chat_gallery.dart';
import '/ui/page/player/controller.dart';
import '/ui/page/player/view.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Possible [Routes.chats][Routes.files] or [Routes.media] page screens.
enum GalleryViewMode { files, media }

/// Controller of the [Routes.chats] [Routes.files] or [Routes.media] page.
class GalleryController extends GetxController {
  GalleryController({
    required this.chatService,
    required this.chatId,
    required this.viewMode,
  });

  /// ID of this [Chat].
  final ChatId chatId;

  /// Reactive state of the [Chat] this page is about.
  final Rx<RxChat?> chat = Rx(null);

  /// [ChatService] maintaining the [chat].
  final ChatService chatService;

  /// Current [GalleryView] view.
  ///
  /// May be:
  /// - `viewMode.files`, meaning [GalleryView] must shown only files attachments.
  /// - `viewMode.media`, meaning [GalleryView] must shown only media attachments.
  final GalleryViewMode viewMode;

  /// [GalleryView] [items] fetched from chat.
  final RxList<Attachment> items = RxList([]);

  /// Status of the [Chat] [GalleryView] fetching.
  ///
  /// May be:
  /// - `chatStatus.isLoading`, meaning [GalleryView] is being fetched from the service.
  /// - `chatStatus.isEmpty`, meaning [GalleryView] with specified [chatId] was empty.
  /// - `chatStatus.isSuccess`, meaning [GalleryView] is successfully fetched.
  /// - `chatStatus.isLoadingMore`, meaning a request is being made.
  final Rx<RxStatus> chatStatus = Rx<RxStatus>(RxStatus.loading());

  /// Status of the [GalleryView] [items] fetching.
  ///
  /// May be:
  /// - `itemsStatus.isLoading`, meaning [items] is being fetched from the service.
  /// - `itemsStatus.isEmpty`, meaning [items] with specified [chatId] was empty.
  /// - `itemsStatus.isSuccess`, meaning [items] is successfully fetched.
  /// - `itemsStatus.isLoadingMore`, meaning a request is being made.
  final Rx<RxStatus> itemsStatus = Rx<RxStatus>(RxStatus.loading());

  /// [TextFieldState] for report reason.
  final TextFieldState reporting = TextFieldState();

  /// [Map] of [GlobalKey]s used to prevent [MediaItem]s from rebuilding.
  final Map<String, GlobalKey> thumbnails = {};

  /// [ScrollController] to pass to a [GridView] or [SingleChildScrollView].
  final ScrollController scrollController = ScrollController();

  /// [Map] of [ChatItem]s associated with provided [Attachment]s
  /// [id] for quick search.
  final Map<String, ChatItem> _itemsToChatMap = {};

  /// [Paginated]es used by this [GalleryController].
  late Paginated<ChatItemId, Rx<ChatItem>>? _initialPaginated;

  /// [FixedItemsPaginated] of the [MediaItem]s converted from the source
  /// [Paginated] of [ChatItem]s.
  late final FixedItemsPaginated<String, MediaItem> _paginated =
      FixedItemsPaginated(
        {},
        onNext: () async {
          _paginated.nextLoading.value = true;

          try {
            await _initialPaginated?.next();
            _paginated.hasNext.value =
                _initialPaginated?.hasNext.value ?? false;
          } finally {
            _paginated.nextLoading.value = false;
          }
        },
        onPrevious: () async {
          _paginated.previousLoading.value = true;

          try {
            await _initialPaginated?.previous();
            _paginated.hasPrevious.value =
                _initialPaginated?.hasPrevious.value ?? false;
          } finally {
            _paginated.previousLoading.value = false;
          }
        },
      );

  @override
  onInit() {
    scrollController.addListener(_scrollListener);
    _fetchChat();
    super.onInit();
  }

  @override
  onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Downloads the provided [FileAttachment], if not downloaded already, or
  /// otherwise opens it or cancels the download.
  Future<void> downloadFile(FileAttachment attachment) async {
    if (attachment.isDownloading) {
      attachment.cancelDownload();
    } else if (await attachment.open() == false) {
      try {
        await attachment.download();
      } catch (e) {
        if (e is DioException && e.type == DioExceptionType.cancel) {
          return;
        }
        await Future.delayed(Duration.zero);
        await attachment.download();
      }
    }
  }

  /// TODO: Replace with GraphQL mutation when implemented.
  /// Reports the [chat].
  Future<void> reportChat() async {
    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');
    }

    try {
      await launchUrl(
        Uri(
          scheme: 'mailto',
          path: Config.support,
          query: encodeQueryParameters({
            'subject': '[Abuse] Report on ChatId($chatId)',
            'body': '${reporting.text}\n\n',
          }),
        ),
      );
    } catch (e) {
      await MessagePopup.error(
        'label_contact_us_via_provided_email'.l10nfmt({
          'email': Config.support,
        }),
      );
    }
  }

  /// Opens [chat] with current [chatId].
  void goToChat() => router.chat(chatId);

  /// Displays the provided [attachment] in [PlayerView].
  Future<void> showMediaPlayer(
    BuildContext context,
    Attachment attachment,
  ) async {
    final ChatItem? chatItem = _itemsToChatMap.containsKey(attachment.id.val)
        ? _itemsToChatMap[attachment.id.val]
        : null;

    final List<Attachment> itemAttachments = [];
    if (chatItem is ChatMessage) {
      itemAttachments.addAll(chatItem.attachments);
    } else if (chatItem is ChatForward) {
      final ChatItemQuote quote = chatItem.quote;
      if (quote is ChatMessageQuote) {
        itemAttachments.addAll(quote.attachments);
      }
    }
    final int initial = chatItem != null
        ? max(0, itemAttachments.indexOf(attachment))
        : 0;

    await PlayerView.show(
      context,
      gallery: PaginatedGallery(
        paginated: chatItem != null
            ? (SingleItemPaginated(chatItem.id, Rx(chatItem))..around())
            : null,
        resourceId: ResourceId(chatId: chatId),
        initial: chatItem != null ? (chatItem.key.toString(), initial) : null,
      ),
    );
  }

  /// Fetches the [chat].
  Future<void> _fetchChat() async {
    chat.value = await chatService.get(chatId);
    if (chat.value == null) {
      chatStatus.value = RxStatus.empty();
    } else {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => _buildInitialItems(),
      );
      chatStatus.value = RxStatus.success();
    }
  }

  /// Builds initial attachments [items] for current [chat] with
  /// specified [viewMode].
  Future<void> _buildInitialItems() async {
    items.value = [];
    _itemsToChatMap.clear();
    if (chat.value != null) {
      _initialPaginated = chat.value!.attachments(
        item: chat.value!.lastItem?.id,
      );
      if (_initialPaginated == null) return;
      await _initialPaginated!.around();

      _paginated.hasNext.value = _initialPaginated!.hasNext.value;
      while (_paginated.hasNext.value = _initialPaginated!.hasNext.value) {
        await _paginated.next();
      }
      _paginated.hasPrevious.value = _initialPaginated!.hasPrevious.value;
      _buildItemsFromPaginated();

      /// TODO: Remove when attachments are downloaded from
      /// the server by type - media/files.
      ///
      /// The logic for searching for the first attachment is the same, as we
      /// can view files, and attachments can begin with media.
      /// The first selection will return 5 images, but no files,
      /// resulting in no files. Or vice versa.
      while (items.isEmpty && _canDownloadMore()) {
        await _fetchItems();
      }

      itemsStatus.value = RxStatus.success();
      SchedulerBinding.instance.addPostFrameCallback((_) => _scrollListener());
    }
  }

  /// Builds next page of attachments [items] for current [chat]
  /// with specified [viewMode].
  void _buildItemsFromPaginated() {
    final List<Attachment> attachments = [];
    _itemsToChatMap.clear();

    // Generate ordered chat items by [ChatItem.at].
    final List<ChatItem> orderedItems = [];
    for (var k in _initialPaginated!.items.keys) {
      if (_initialPaginated!.items[k] == null) continue;
      orderedItems.add(_initialPaginated!.items[k]!.value);
    }
    orderedItems.sort((a, b) => a.at.compareTo(b.at));

    // Filter chat items and attachmentes for current [viewMode].
    // Support only [ChatMessage] and [ChatForward].
    for (var k = 0; k < orderedItems.length; ++k) {
      final ChatItem chatItem = orderedItems[k];
      final List<Attachment> fetchedAttachment = [];
      if (chatItem is ChatMessage) {
        fetchedAttachment.addAll(chatItem.attachments);
      } else if (chatItem is ChatForward) {
        final ChatItemQuote quote = chatItem.quote;
        if (quote is ChatMessageQuote) {
          fetchedAttachment.addAll(quote.attachments);
        } else {
          // `chatItem` is not supported, ignore it.
          continue;
        }
      } else {
        // `chatItem` is not supported, ignore it.
        continue;
      }

      // Builds list of attachments for provided [viewMode].
      final List<Attachment> itemAttachments = [];
      for (var i = 0; i < fetchedAttachment.length; ++i) {
        final Attachment a = fetchedAttachment[i];
        final bool shouldBeAdded = switch (viewMode) {
          GalleryViewMode.files =>
            a is FileAttachment && !a.filename.isVideoFileName,
          GalleryViewMode.media =>
            a is ImageAttachment || a.filename.isVideoFileName,
        };

        if (shouldBeAdded) {
          itemAttachments.add(a);
          _itemsToChatMap[a.id.val] = chatItem;
        }
      }

      attachments.insertAll(0, itemAttachments);
    }
    items.value = attachments;
  }

  /// Requests the previos page of [Attachments]s based on the
  /// [ScrollController.position] value.
  void _scrollListener() {
    if (_canFetchMore()) {
      _fetchItems();
    }
  }

  /// Fetches previos page of [paginated].
  Future<void> _fetchItems() async {
    await _paginated.previous();
    _buildItemsFromPaginated();
    SchedulerBinding.instance.addPostFrameCallback((_) => _scrollListener());
  }

  /// Specifies whether the [scrollController] can show more items.
  bool _canShowMore() {
    final screenSpaceToEnd = scrollController.hasClients
        ? scrollController.position.maxScrollExtent -
              scrollController.position.pixels
        : 1000000000000;
    final bool canShowMore = screenSpaceToEnd < 500;
    return canShowMore;
  }

  /// Specifies whether the [_paginated] can load more items.
  bool _canDownloadMore() =>
      _paginated.hasPrevious.value &&
      !_paginated.previousLoading.value &&
      !_paginated.nextLoading.value;

  /// Specifies whether more items can be loaded and displayed.
  bool _canFetchMore() => _canShowMore() && _canDownloadMore();
}
