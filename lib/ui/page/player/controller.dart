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

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mutex/mutex.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:video_player/video_player.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/settings.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/ui/worker/cache.dart';
import '/util/log.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';

class MediaItem implements Comparable<MediaItem> {
  MediaItem(this.attachments, this.item);

  final List<Attachment> attachments;
  final ChatItem? item;

  String get id =>
      item?.key.toString() ?? 'a_${attachments.map((e) => e.id.val).join('_')}';

  @override
  bool operator ==(Object other) {
    return other is MediaItem && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MediaItem($id)';
  }

  @override
  int compareTo(MediaItem other) {
    return id.compareTo(other.id);
  }
}

/// Controller of a [PlayerView].
class PlayerController extends GetxController {
  PlayerController(
    this._settingsRepository,
    this._chatService, {
    this.shouldClose,
    required this.source,
    this.initialKey = '',
    this.initialIndex = 0,
  }) : key = RxString(initialKey);

  final void Function()? shouldClose;

  final Paginated<String, MediaItem> source;
  final RxList<Post> posts = RxList();
  final RxString key;
  late final RxInt index;

  final RxBool side = RxBool(false);
  final RxBool displaySide = RxBool(false);
  final RxBool expanded = RxBool(false);
  final RxBool interface = RxBool(true);

  final RxBool hasNextPage = RxBool(false);
  final RxBool hasPreviousPage = RxBool(false);

  final GlobalKey scrollableKey = GlobalKey();

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [ItemScrollController] of the [ScrollablePositionedList].
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  /// Latest volume value for [VideoPlayerController] being displayed.
  double? latestVolume;

  late final PageController vertical;
  final TransformationController transformationController =
      TransformationController();
  final RxBool viewportIsTransformed = RxBool(false);

  final String initialKey;
  final int initialIndex;

  final AbstractSettingsRepository _settingsRepository;
  final ChatService? _chatService;

  Worker? _volumeDebounce;
  final RxDouble _volume = RxDouble(-1);

  bool _isFullscreen = false;
  final Mutex _fullscreenMutex = Mutex();

  bool _ignorePageListener = false;

  StreamSubscription? _sourceSubscription;

  double? _lastPageValue;
  int? _currentPageIndex;
  bool? _scrollingForward;

  /// Returns the current [ApplicationSettings].
  Rx<ApplicationSettings?> get settings =>
      _settingsRepository.applicationSettings;

  /// Returns the currently displayed [post],
  Post? get post {
    return posts.elementAtOrNull(index.value);
  }

  /// Returns the currently displayed [item],
  PostItem? get item {
    final Post? current = post;
    if (current == null) {
      return null;
    }

    return current.items.elementAtOrNull(current.index.value);
  }

  /// Returns an index of the [key] within the [source].
  int get _index {
    final int index = source.values.toList().indexWhere(
      (e) => e.id == key.value,
    );

    if (index == -1) {
      return 0;
    }

    return index;
  }

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

    for (var e in source.values) {
      final bool initial = e.id == key.value;
      posts.add(
        Post.fromMediaItem(e, initial: initial ? initialIndex : 0)..init(),
      );
    }
    posts.sort();

    index = RxInt(max(0, posts.indexWhere((e) => e.id == key.value)));
    vertical = PageController(initialPage: _index, keepPage: false);
    _currentPageIndex = _index;

    _sourceSubscription?.cancel();
    _sourceSubscription = source.items.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
        case OperationKind.updated:
          final MediaItem? item = e.value;

          if (item != null) {
            final Post? existing = posts.firstWhereOrNull((p) => p.id == e.key);
            if (existing == null) {
              final bool initial = item.id == key.value;
              final Post post = Post.fromMediaItem(
                item,
                initial: initial ? initialIndex : 0,
              );

              posts.add(post..init());
              posts.sort();
            } else {
              // TODO: Update the item.
              // existing.description = item.d;
            }
          }
          break;

        case OperationKind.removed:
          posts.removeWhere((p) {
            final bool test = p.id == e.key;
            if (test) {
              p.dispose();
            }

            return test;
          });
          break;
      }

      index.value = max(0, posts.indexWhere((e) => e.id == key.value));
      if (vertical.hasClients && (vertical.page ?? 0) != index.value) {
        _ignorePageListener = true;
        vertical.jumpToPage(index.value);
        _ignorePageListener = false;
      }

      hasPreviousPage.value = index.value > 0;
      hasNextPage.value = index.value < posts.length - 1;
    });

    _volumeDebounce = debounce(_volume, (value) async {
      await _settingsRepository.setVideoVolume(value);
    }, time: Duration(milliseconds: 200));

    HardwareKeyboard.instance.addHandler(_keyboardHandler);
    BackButtonInterceptor.add(_backHandler);
    vertical.addListener(_pageListener);
    super.onInit();
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    _volumeDebounce?.dispose();

    HardwareKeyboard.instance.removeHandler(_keyboardHandler);
    BackButtonInterceptor.remove(_backHandler);
    vertical.removeListener(_pageListener);
    _sourceSubscription?.cancel();

    for (var e in posts) {
      e.dispose();
    }

    if (_isFullscreen) {
      PlatformUtils.exitFullscreen();
    }

    super.onClose();
  }

  /// Stores the provided [volume] as the default one for all video players.
  Future<void> setVideoVolume(double volume) async {
    _volume.value = volume;
  }

  /// Plays or pauses the currently displayed video, if any.
  void playPause() {
    Log.debug('playPause()', '$runtimeType');

    interface.value = true;

    final ReactivePlayerController? video = item?.video.value;
    if (video != null) {
      final bool isFinished = video.isCompleted.value;

      if (video.isPlaying.value) {
        video.pause();
      } else {
        if (isFinished) {
          video.seekTo(const Duration());
        }

        video.play();
      }
    }
  }

  /// Toggles fullscreen of the application on and off.
  Future<void> toggleFullscreen() async {
    Log.debug('toggleFullscreen()', '$runtimeType');

    if (_fullscreenMutex.isLocked) {
      return;
    }

    await _fullscreenMutex.protect(() async {
      if (_isFullscreen) {
        await PlatformUtils.exitFullscreen();
      } else {
        await PlatformUtils.enterFullscreen();
      }

      _isFullscreen = !_isFullscreen;
    });
  }

  /// Moves the [vertical] to a next [Post].
  Future<void> next() async {
    Log.debug('next()', '$runtimeType');

    if (!hasNextPage.value) {
      return;
    }

    await vertical.nextPage(
      duration: Duration(milliseconds: 150),
      curve: Curves.ease,
    );
  }

  /// Moves the [vertical] to a previous [Post].
  Future<void> previous() async {
    if (!hasPreviousPage.value) {
      return;
    }

    await vertical.previousPage(
      duration: Duration(milliseconds: 150),
      curve: Curves.ease,
    );
  }

  /// Opens this [PlayerView] as a separate window.
  ///
  /// Only meaningful for the Web platform currently.
  Future<void> openPopup() async {
    // TODO: Implement.
  }

  /// Downloads the provided [PostItem].
  Future<void> download(PostItem item, {String? to}) async {
    Log.debug('download($item)', '$runtimeType');

    try {
      try {
        await CacheWorker.instance
            .download(
              item.attachment.original.url,
              item.attachment.original.name,
              item.attachment.original.size,
              checksum: item.attachment.original.checksum,
              to: to,
            )
            .future;
      } catch (_) {
        // TODO: Implement.
        // if (item.onError != null) {
        //   await item.onError?.call();
        //   return SchedulerBinding.instance.addPostFrameCallback((_) {
        //     item = widget.children[_page];
        //     _download(item, to: to);
        //   });
        // } else {
        rethrow;
        // }
      }

      MessagePopup.success(
        item.attachment is ImageAttachment
            ? 'label_image_downloaded'.l10n
            : 'label_video_downloaded'.l10n,
      );
    } catch (_) {
      MessagePopup.error('${'err_could_not_download'.l10n}\n\n$e');
      rethrow;
    }
  }

  /// Downloads the provided [PostItem] using `save as` dialog.
  Future<void> downloadAs(PostItem item) async {
    Log.debug('downloadAs($item)', '$runtimeType');

    try {
      final String? to = await FilePicker.platform.saveFile(
        fileName: item.attachment.original.name,
        type: item.attachment is ImageAttachment
            ? FileType.image
            : FileType.video,
        lockParentWindow: true,
      );

      if (to != null) {
        await download(item, to: to);
      }
    } catch (_) {
      MessagePopup.error('err_could_not_download'.l10n);
      rethrow;
    }
  }

  /// Puts the provided [PostItem] to the copy buffer.
  Future<void> copy(Post post, PostItem item) async {
    Log.debug('copy($item)', '$runtimeType');

    final String extension = item.attachment.original.name
        .split('.')
        .last
        .toLowerCase();

    final SimpleFileFormat? format = switch (extension) {
      'jpg' || 'jpeg' => Formats.jpeg,
      'png' => Formats.png,
      'svg' => Formats.svg,
      'gif' => Formats.gif,
      'tiff' => Formats.tiff,
      'bmp' => Formats.bmp,
      'webp' => Formats.webp,
      (_) => null,
    };

    if (format != null) {
      try {
        final response = await (await PlatformUtils.dio).get(
          item.attachment.original.url,
          options: Options(responseType: ResponseType.bytes),
        );

        final bytes = response.data;
        if (bytes is Uint8List) {
          await PlatformUtils.copy(format: format, data: bytes);
          MessagePopup.success('label_copied'.l10n);
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 403) {
          reload(post);
        } else {
          Log.error('copy() -> $e', '$runtimeType');
        }

        MessagePopup.error('err_data_transfer'.l10n);
      } catch (e) {
        Log.error('copy() -> $e', '$runtimeType');
        MessagePopup.error('err_data_transfer'.l10n);
      }
    } else {
      MessagePopup.error('Unsupported format: $extension');
    }
  }

  /// Downloads the provided [PostItem] and saves it to the gallery.
  Future<void> saveToGallery(PostItem item) async {
    Log.debug('saveToGallery($item)', '$runtimeType');

    // Tries downloading the [item].
    Future<void> download() async {
      await PlatformUtils.saveToGallery(
        item.attachment.original.url,
        item.attachment.original.name,
        checksum: item.attachment.original.checksum,
        size: item.attachment.original.size,
        isImage: item.attachment is ImageAttachment,
      );

      MessagePopup.success(
        item.attachment is ImageAttachment
            ? 'label_image_saved_to_gallery'.l10n
            : 'label_video_saved_to_gallery'.l10n,
      );
    }

    try {
      try {
        await download();
      } on DioException catch (_) {
        // TODO: Implement.
        // if (item.onError != null && e.response?.statusCode == 403) {
        //   await item.onError?.call();
        //   await Future.delayed(Duration.zero);
        //   await download();
        // } else {
        rethrow;
        // }
      }
    } on UnsupportedError catch (_) {
      MessagePopup.error('err_unsupported_format'.l10n);
    } catch (_) {
      MessagePopup.error('err_could_not_download'.l10n);
      rethrow;
    }
  }

  /// Invokes [PlatformUtilsImpl.share] for the provided [item].
  Future<void> share(PostItem item) async {
    Log.debug('share($item)', '$runtimeType');

    try {
      try {
        await PlatformUtils.share(
          item.attachment.original.url,
          item.attachment.original.name,
          checksum: item.attachment.original.checksum,
        );
      } catch (_) {
        // TODO: Implement.
        // if (item.onError != null) {
        //   await item.onError?.call();
        //   await PlatformUtils.share(
        //     item.link,
        //     item.name,
        //     checksum: item.checksum,
        //   );
        // } else {
        rethrow;
        // }
      }
    } catch (_) {
      MessagePopup.error('err_could_not_download'.l10n);
      rethrow;
    }
  }

  /// Fetches the [ChatItem] of the provided [post] to update its [Attachment]s.
  ///
  /// Should be invoked in case some of those [Attachment]s are expired.
  Future<void> reload(Post post) async {
    Log.debug('reload($post)', '$runtimeType');

    final ChatItem? item = post.item;

    if (item != null) {
      final RxChat? chat = await _chatService?.get(item.chatId);
      final Paginated<ChatItemId, Rx<ChatItem>>? single = await chat?.single(
        item.id,
      );

      await single?.around();

      final Rx<ChatItem>? node = single?.values.firstOrNull;

      if (chat != null && single != null && node != null) {
        await chat.updateAttachments(node.value);

        final ChatItem message = node.value;

        if (message is ChatMessage) {
          post.items.value = message.attachments
              .map((e) => PostItem(e))
              .toList();
        } else if (message is ChatForward) {
          final quote = message.quote;
          if (quote is ChatMessageQuote) {
            post.items.value = quote.attachments
                .map((e) => PostItem(e))
                .toList();
          }
        }
      }
    }
  }

  /// Parses the provided [event] to invoke [playPause], [previous], etc.
  ///
  /// Intended to be a handler of [HardwareKeyboard].
  bool _keyboardHandler(KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.space:
          playPause();
          return true;

        case LogicalKeyboardKey.arrowUp:
          previous();
          return true;

        case LogicalKeyboardKey.arrowDown:
          next();
          return true;

        case LogicalKeyboardKey.arrowLeft:
          final Post? current = post;

          if (current != null && current.items.length >= 2) {
            if ((current.horizontal.value.page ?? 0).round() > 0) {
              current.horizontal.value.previousPage(
                duration: Duration(milliseconds: 200),
                curve: Curves.ease,
              );
            }
            return true;
          }

          final ReactivePlayerController? video = item?.video.value;
          if (video != null) {
            final int seconds = video.position.value.inSeconds;
            video.seekTo(Duration(seconds: max(seconds - 5, 0)));
            return true;
          }

          return false;

        case LogicalKeyboardKey.arrowRight:
          final Post? current = post;

          if (current != null && current.items.length >= 2) {
            if ((current.horizontal.value.page ?? 0).round() <
                current.items.length - 1) {
              current.horizontal.value.nextPage(
                duration: Duration(milliseconds: 200),
                curve: Curves.ease,
              );
            }
            return true;
          }

          final ReactivePlayerController? video = item?.video.value;
          if (video != null) {
            final int seconds = video.position.value.inSeconds;
            video.seekTo(
              Duration(
                seconds: min(seconds + 5, video.duration.value.inSeconds),
              ),
            );
            return true;
          }

          return false;

        case LogicalKeyboardKey.escape:
          if (_isFullscreen) {
            toggleFullscreen();
          } else {
            shouldClose?.call();
          }

          return true;

        default:
          break;
      }
    }

    return false;
  }

  /// Invokes [shouldClose] and returns `true`.
  ///
  /// Intended to be used as a [BackButtonInterceptor] handler.
  bool _backHandler(bool _, RouteInfo __) {
    shouldClose?.call();
    return true;
  }

  /// Sets the values and variables according to the current [vertical] page.
  ///
  /// Intended to be a listener that is invoked on any [vertical] position
  /// changing.
  void _pageListener() {
    final double pageOrZero = vertical.page ?? 0;

    if (vertical.hasClients && !_ignorePageListener) {
      final int rounded = pageOrZero.round();

      hasPreviousPage.value = pageOrZero.round() > 0;
      hasNextPage.value = pageOrZero.round() < posts.length - 1;

      if (_lastPageValue != null) {
        if (pageOrZero > _lastPageValue!) {
          _scrollingForward = true;
        } else if (pageOrZero < _lastPageValue!) {
          _scrollingForward = false;
        }
      }

      _lastPageValue = pageOrZero;

      if (_currentPageIndex != null) {
        if (_scrollingForward == true && pageOrZero >= _currentPageIndex! + 1) {
          _currentPageIndex = pageOrZero.floor();

          if (_currentPageIndex! > 0) {
            final Post? page = posts.elementAtOrNull(_currentPageIndex! - 1);
            page?.reattach();
          }

          Log.debug(
            'Previous page fully gone (forward) → now at $_currentPageIndex',
            '$runtimeType',
          );
        }

        if (_scrollingForward == false &&
            pageOrZero <= _currentPageIndex! - 1) {
          _currentPageIndex = pageOrZero.ceil();

          final Post? page = posts.elementAtOrNull(_currentPageIndex!);
          page?.reattach();

          Log.debug(
            'Previous page fully gone (backward) → now at $_currentPageIndex',
            '$runtimeType',
          );
        }
      }

      if (rounded != index.value) {
        final int previous = index.value;

        index.value = rounded;
        key.value = source.values.elementAtOrNull(rounded)?.id ?? key.value;

        for (var i = 0; i < posts.length; ++i) {
          if (i == index.value) {
            posts[i].items
                .where((e) => e.video.value != null)
                .firstOrNull
                ?.video
                .value
                ?.play();
          } else {
            for (var e in posts[i].items) {
              e.video.value?.pause();
            }
          }
        }

        final Post? items = posts.elementAtOrNull(index.value);
        for (var e in items?.items ?? <PostItem>[]) {
          e.video.value?.play();
        }

        final ItemPosition? firstOrNull =
            itemPositionsListener.itemPositions.value.firstOrNull;

        final ItemPosition? lastOrNull =
            itemPositionsListener.itemPositions.value.lastOrNull;

        // If it's the scroll up.
        if (previous > index.value) {
          if (firstOrNull != null) {
            final bool firstAndPartial =
                firstOrNull.index == index.value &&
                firstOrNull.itemLeadingEdge < 0;

            if (firstAndPartial || index.value < firstOrNull.index) {
              itemScrollController.scrollTo(
                index: index.value,
                duration: Duration(milliseconds: 200),
              );
            }
          }
        }
        // If it's the scroll down.
        else if (previous < index.value) {
          if (lastOrNull != null) {
            final bool lastAndPartial =
                lastOrNull.index == index.value &&
                lastOrNull.itemTrailingEdge > 0;

            if (lastAndPartial || index.value > lastOrNull.index) {
              itemScrollController.scrollTo(
                index: index.value,
                duration: Duration(milliseconds: 200),
                alignment: 0.5,
              );
            }
          }
        }

        if (index.value <= 1) {
          if (!source.previousLoading.value) {
            Log.debug(
              '`index.value` has reached top, thus trying to load previous page, hasPrevious: ${source.hasPrevious.value}',
              '$runtimeType',
            );

            if (source.hasPrevious.value) {
              source.previous();
            }
          }
        } else if (index.value >= posts.length - 2) {
          if (!source.nextLoading.value) {
            Log.debug(
              '`index.value` has reached bottom, thus trying to load next page, hasNext: ${source.hasNext.value}',
              '$runtimeType',
            );

            if (source.hasNext.value) {
              source.next();
            }
          }
        }

        Log.debug(
          '_pageListener() -> index: ${index.value}, key: ${key.value}',
          '$runtimeType',
        );
      }
    }
  }
}

/// Single entity to display in a [PlayerView].
class Post implements Comparable<Post> {
  Post({
    required this.id,
    this.item,
    List<PostItem> items = const [],
    int initial = 0,
    this.author,
    this.description,
    this.postedAt,
  }) : items = RxList(items),
       horizontal = Rx(PageController(initialPage: initial, keepPage: false)),
       index = RxInt(initial);

  /// Constructs a [Post] from the provided [MediaItem].
  factory Post.fromMediaItem(MediaItem item, {int initial = 0}) {
    ChatMessage? message;

    if (item.item is ChatMessage) {
      message = item.item as ChatMessage;
    }

    return Post(
      id: item.id,
      item: item.item,
      items: item.attachments.map(PostItem.new).toList(),
      initial: initial,
      author: item.item?.author,
      description: message?.text,
      postedAt: item.item?.at,
    );
  }

  /// ID of this [Post].
  final String id;

  /// [ChatItem] representing this [Post].
  final ChatItem? item;

  /// [User] who is an author of this [Post], if any.
  final User? author;

  /// Description of this [Post], if any.
  ChatMessageText? description;

  /// [PreciseDateTime] this [Post] was posted at.
  final PreciseDateTime? postedAt;

  /// [PageController] for controlling the horizontal switching of [items],
  final Rx<PageController> horizontal;

  /// Current index of [items] in [horizontal].
  final RxInt index;

  /// [PostItem]s of this [Post].
  final RxList<PostItem> items;

  @override
  int get hashCode =>
      Object.hashAll([id, author, description, postedAt, index.value, items]);

  /// Initializes this [Post].
  void init() {
    horizontal.value.addListener(_pageListener);
  }

  /// Disposes this [Post].
  void dispose() {
    horizontal.value.removeListener(_pageListener);
    for (var e in items) {
      e.dispose();
    }
  }

  /// Resets the current [horizontal].
  void reattach() {
    horizontal.value.removeListener(_pageListener);
    horizontal.value = PageController(initialPage: 0);
    index.value = 0;
    horizontal.value.addListener(_pageListener);
  }

  @override
  bool operator ==(Object other) {
    return other is Post &&
        other.id == id &&
        other.author == author &&
        other.description == description &&
        other.postedAt == postedAt &&
        index.value == other.index.value &&
        const ListEquality().equals(items, other.items);
  }

  @override
  String toString() {
    return 'Post($id)';
  }

  @override
  int compareTo(Post other) {
    int? posted;

    if (other.postedAt != null) {
      posted = postedAt?.compareTo(other.postedAt!);
    }

    if (posted != null && posted != 0) {
      return posted;
    }

    return id.compareTo(other.id);
  }

  /// Sets the [index] according to the [horizontal].
  void _pageListener() {
    if (horizontal.value.hasClients) {
      final rounded = horizontal.value.page?.round() ?? 0;
      index.value = rounded;
    }
  }
}

/// Single item of [Post] represented with an [Attachment].
class PostItem {
  PostItem(this.attachment);

  /// [Attachment] itself.
  final Attachment attachment;

  /// [ReactivePlayerController] of the video, if this [attachment] is one.
  final Rx<ReactivePlayerController?> video = Rx(null);

  @override
  int get hashCode => attachment.hashCode;

  @override
  bool operator ==(Object other) {
    return other is PostItem && other.attachment == attachment;
  }

  /// Disposes this [PostItem].
  void dispose() {
    video.value?.dispose();
  }

  @override
  String toString() {
    return 'PostItem($attachment, video: $video)';
  }
}

/// Reactive [VideoPlayerController].
class ReactivePlayerController {
  ReactivePlayerController(this.controller) {
    controller.addListener(_listener);
  }

  /// [VideoPlayerController] itself.
  final VideoPlayerController controller;

  /// Currently buffered ranges.
  final RxList<DurationRange> buffered = RxList();

  /// Indicator whether the video is buffering.
  final RxBool isBuffering = RxBool(true);

  /// Indicator whether the video is looped.
  final RxBool isLooping = RxBool(false);

  /// Indicator whether the video is playing.
  final RxBool isPlaying = RxBool(false);

  /// Indicator whether the video is completed.
  final RxBool isCompleted = RxBool(false);

  /// [Size] of the currently loaded video.
  final Rx<Size> size = Rx(Size.zero);

  /// Current playback position.
  final Rx<Duration> position = Rx(Duration.zero);

  /// Total duration of the video.
  final Rx<Duration> duration = Rx(Duration.zero);

  /// Current volume of the playback.
  final RxDouble volume = RxDouble(0);

  /// Disposes this [ReactivePlayerController].
  void dispose() {
    controller.removeListener(_listener);
  }

  /// Starts playing the video.
  ///
  /// If the video is at the end, this method starts playing from the beginning.
  Future<void> play() async {
    await controller.play();
  }

  /// Pauses the video.
  Future<void> pause() async {
    await controller.pause();
  }

  /// Sets the video's current timestamp to be at [moment].
  Future<void> seekTo(Duration moment) async {
    await controller.seekTo(moment);
  }

  /// Sets the playback speed of video.
  Future<void> setRate(double speed) async {
    controller.setPlaybackSpeed(speed);
  }

  /// Sets the audio volume of video.
  Future<void> setVolume(double volume) async {
    controller.setVolume(volume);
  }

  /// Updates the parameters according to the state of [controller].
  void _listener() {
    buffered.value = controller.value.buffered;
    isBuffering.value = controller.value.isInitialized
        ? controller.value.isBuffering
        : true;
    isLooping.value = controller.value.isLooping;
    isPlaying.value = controller.value.isPlaying;
    isCompleted.value = controller.value.isCompleted;
    size.value = controller.value.size;
    position.value = controller.value.position;
    duration.value = controller.value.duration;
    volume.value = controller.value.volume;
  }
}
