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
import '/domain/model/chat.dart';
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
import '/util/web/web_utils.dart';
import 'view.dart' show Resource, ResourceId;

/// Controller of a [PlayerView].
class PlayerController extends GetxController {
  PlayerController(
    this._settingsRepository,
    this._chatService, {
    this.shouldClose,
    required this.source,
    this.initialKey = '',
    this.initialIndex = 0,
    this.resourceId,
  }) : key = RxString(initialKey);

  /// Callback, called when a [PlayerView] this controller attached to should
  /// close.
  final void Function()? shouldClose;

  /// [Paginated] of [MediaItem]s being the source of [posts].
  final Paginated<String, MediaItem> source;

  /// [ResourceId] from where the [source] is coming from.
  final ResourceId? resourceId;

  /// [Resource] from where the [source] is coming from.
  final Resource resource = Resource();

  /// [Post]s to display.
  final RxList<Post> posts = RxList();

  /// [Map] of [GlobalKey]s used to prevent [VideoThumbnail]s from rebuilding.
  final Map<String, GlobalKey> thumbnails = {};

  /// [Post.id] of the currently displayed [Post] from [posts].
  final RxString key;

  /// Index of the currently displayed [Post] from [posts].
  late final RxInt index;

  /// Indicator whether side gallery should be displayed.
  final RxBool side = RxBool(false);

  /// Indicator whether [Post.description] and meta information should be
  /// expanded.
  final RxBool expanded = RxBool(false);

  /// Indicator whether interface should be visible.
  final RxBool interface = RxBool(true);

  /// Indicator whether [vertical] has next page.
  final RxBool hasNextPage = RxBool(false);

  /// Indicator whether [vertical] has previous page.
  final RxBool hasPreviousPage = RxBool(false);

  /// Indicator whether [posts] displayed should include videos.
  final RxBool includeVideos = RxBool(true);

  /// Indicator whether [posts] displayed should include photos.
  final RxBool includePhotos = RxBool(true);

  /// [GlobalKey] of a [ScrollablePositionedList] for side gallery used to keep
  /// rebuilds from rebuilding the list.
  final GlobalKey scrollableKey = GlobalKey();

  /// [ScrollController] to pass to a [ScrollablePositionedList] for side
  /// gallery.
  final ScrollController scrollController = ScrollController();

  /// [ItemScrollController] of a [ScrollablePositionedList] of side gallery.
  final ItemScrollController itemScrollController = ItemScrollController();

  /// [ItemPositionsListener] of a [ScrollablePositionedList] listening for side
  /// gallery changes.
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  /// Latest volume value for [VideoPlayerController] being displayed.
  double? latestVolume;

  /// [PageController] controlling the [PageView] of [posts].
  late final PageController vertical;

  /// [TransformationController] of a [InteractiveViewer].
  final TransformationController transformationController =
      TransformationController();

  /// Indicator whether [InteractiveViewer] has any transformations.
  final RxBool viewportIsTransformed = RxBool(false);

  /// Initial [Post.id] of the [vertical] controller.
  final String initialKey;

  /// Initial index of a [Post.horizontal] controller.
  final int initialIndex;

  /// [List] of the currently active [PlayerNotification]s.
  final RxList<PlayerNotification> notifications = RxList();

  /// [AbstractSettingsRepository] for storing the
  /// [ApplicationSettings.videoVolume].
  final AbstractSettingsRepository _settingsRepository;

  /// [ChatService] used to refresh [Attachment]s in [Post]s.
  final ChatService? _chatService;

  /// [Worker] listening for [_volume] changes to invoke
  /// [AbstractSettingsRepository.setVideoVolume].
  Worker? _volumeDebounce;

  /// Volume set during [setVideoVolume].
  final RxDouble _volume = RxDouble(-1);

  /// Indicator whether [toggleFullscreen] is toggled.
  bool _isFullscreen = false;

  /// [Mutex] guarding [toggleFullscreen].
  final Mutex _fullscreenMutex = Mutex();

  /// Indicator whether [_pageListener] should ignore the changes.
  bool _ignorePageListener = false;

  /// [StreamSubscription] listening for [source] changes to add or remove new
  /// [posts].
  StreamSubscription? _sourceSubscription;

  /// Last [PageController.page] of [vertical] used to determine its changes.
  double? _lastPageValue;

  /// Last [PageController.page] rounded used to determine its changes.
  int? _currentPageIndex;

  /// Indicator whether [PageController.page] is changing forward or backward.
  bool? _scrollingForward;

  /// [Timer]s removing items from the [notifications] after the
  /// [_notificationDuration].
  final List<Timer> _notificationTimers = [];

  /// [Duration] to display a single [PlayerNotification].
  static const Duration _notificationDuration = Duration(seconds: 6);

  /// [Timer] firing in [keepActive] intended to set [interface] to `false`.
  Timer? _activityTimer;

  /// [Duration] to consider activity as stale to set [interface] to `false`.
  static const Duration _activityTimeout = Duration(seconds: 3);

  /// Indicator whether latest [interface] toggling to `false` was caused by
  /// [_activityTimer].
  bool _dueToActivity = false;

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

    vertical = PageController(
      initialPage: _index,
      keepPage: false,
      viewportFraction: 1.05,
    );

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

    _initResource();

    HardwareKeyboard.instance.addHandler(_keyboardHandler);
    BackButtonInterceptor.add(_backHandler);
    vertical.addListener(_pageListener);

    keepActive();

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
    _activityTimer?.cancel();

    for (var e in posts) {
      e.dispose();
    }

    if (_isFullscreen) {
      PlatformUtils.exitFullscreen();
    }

    for (final Timer e in _notificationTimers) {
      e.cancel();
    }
    _notificationTimers.clear();

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
    final ChatId? chatId = resourceId?.chatId;

    if (chatId != null) {
      final bool hasWindow = WebUtils.openPopupGallery(
        chatId,
        id: post?.id,
        index: post?.index.value,
      );

      if (!hasWindow) {
        notify(ErrorNotification(message: 'err_media_popup_was_blocked'.l10n));
      } else {
        shouldClose?.call();
      }
    }
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

  /// Adds the provided [PlayerNotification] to the [notifications].
  void notify(PlayerNotification e) {
    notifications.add(e);
    _notificationTimers.add(
      Timer(_notificationDuration, () => notifications.remove(e)),
    );
  }

  /// Starts [_activityTimer] that would set [interface] to `false` after
  /// [_activityTimeout].
  void keepActive() {
    if (PlatformUtils.isMobile) {
      return;
    }

    if (_dueToActivity) {
      interface.value = true;
      _dueToActivity = false;
    }

    _activityTimer?.cancel();
    _activityTimer = Timer(_activityTimeout, () {
      if (interface.value) {
        _dueToActivity = true;
        interface.value = false;
      }
    });
  }

  /// Initializes the [resource] from the [resourceId].
  Future<void> _initResource() async {
    final ChatId? chatId = resourceId?.chatId;
    if (chatId != null) {
      resource.chat.value = await _chatService?.get(chatId);
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
  bool _backHandler(bool _, RouteInfo _) {
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

/// [ChatItem] with its [Attachment]s.
class MediaItem implements Comparable<MediaItem> {
  MediaItem(this.attachments, this.item);

  /// [Attachment] themselves.
  final List<Attachment> attachments;

  /// [ChatItem] itself.
  final ChatItem? item;

  /// Returns the ID of this [MediaItem].
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

/// Possible [PlayerNotification] kind.
enum PlayerNotificationKind { error }

/// Notification of an event happened in [PlayerView].
abstract class PlayerNotification {
  /// Returns the [PlayerNotificationKind] of this [PlayerNotification].
  PlayerNotificationKind get kind;
}

/// [PlayerNotification] of an error.
class ErrorNotification extends PlayerNotification {
  ErrorNotification({required this.message});

  /// Message of this [ErrorNotification] describing the error happened.
  final String message;

  @override
  PlayerNotificationKind get kind => PlayerNotificationKind.error;
}
