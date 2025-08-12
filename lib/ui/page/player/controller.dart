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
import 'package:video_player/video_player.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/settings.dart';
import '/l10n/l10n.dart';
import '/ui/worker/cache.dart';
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

class PlayerController extends GetxController {
  PlayerController(
    this._settingsRepository, {
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

  final GlobalKey scrollableKey = GlobalKey();

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [ItemScrollController] of the page's [ScrollablePositionedList].
  final ItemScrollController itemScrollController = ItemScrollController();

  /// Latest volume value for [VideoController] being displayed.
  double? latestVolume;

  late final PageController vertical;
  final TransformationController transformationController =
      TransformationController();
  final RxBool viewportIsTransformed = RxBool(false);

  final String initialKey;
  final int initialIndex;

  final AbstractSettingsRepository _settingsRepository;

  bool _isFullscreen = false;
  final Mutex _fullscreenMutex = Mutex();

  bool _ignorePageListener = false;

  StreamSubscription? _sourceSubscription;

  Rx<ApplicationSettings?> get settings =>
      _settingsRepository.applicationSettings;

  bool get hasNextPage {
    final double? page = vertical.page;
    return page != null && page.round() < source.length - 1;
  }

  bool get hasPreviousPage {
    final double? page = vertical.page;
    return page != null && page.round() > 0;
  }

  Post? get post {
    return posts.elementAtOrNull(index.value);
  }

  PostItem? get item {
    final Post? current = post;
    if (current == null) {
      return null;
    }

    return current.items.elementAtOrNull(current.index.value);
  }

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
    for (var e in source.items.values) {
      posts.add(Post.fromMediaItem(e)..init());
    }
    posts.sort();

    index = RxInt(max(0, posts.indexWhere((e) => e.id == key.value)));

    vertical = PageController(initialPage: _index);

    _sourceSubscription?.cancel();
    _sourceSubscription = source.items.changes.listen((e) {
      // final int previous = index.value;

      // index.value = _index;

      // if (previous != index.value) {
      //   key.value = source.values.elementAtOrNull(index.value)?.id ?? key.value;

      //   _ignorePageListener = true;
      //   vertical.jumpToPage(index.value);
      //   _ignorePageListener = false;
      // }

      switch (e.op) {
        case OperationKind.added:
        case OperationKind.updated:
          final MediaItem? item = e.value;
          if (item != null) {
            final Post? existing = posts.firstWhereOrNull((p) => p.id == e.key);
            if (existing == null) {
              posts.add(Post.fromMediaItem(item)..init());
              posts.sort();
            } else {
              // TODO: Update the item.
              // existing.description =item.d
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
    });

    HardwareKeyboard.instance.addHandler(_keyboardHandler);
    BackButtonInterceptor.add(_backHandler);
    vertical.addListener(_pageListener);
    super.onInit();
  }

  @override
  void onClose() {
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

  Future<void> setVideoVolume(double volume) async {
    await _settingsRepository.setVideoVolume(volume);
  }

  void playPause() {
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

  Future<void> toggleFullscreen() async {
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

  Future<void> next() async {
    if (!hasNextPage) {
      return;
    }

    await vertical.nextPage(
      duration: Duration(milliseconds: 150),
      curve: Curves.ease,
    );
  }

  Future<void> previous() async {
    if (!hasPreviousPage) {
      return;
    }

    await vertical.previousPage(
      duration: Duration(milliseconds: 150),
      curve: Curves.ease,
    );
  }

  Future<void> openPopup() async {
    //
  }

  /// Downloads the provided [PostItem].
  Future<void> download(PostItem item, {String? to}) async {
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
      MessagePopup.error('err_could_not_download'.l10n);
      rethrow;
    }
  }

  /// Downloads the provided [GalleryItem] using `save as` dialog.
  Future<void> downloadAs(PostItem item) async {
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

  /// Downloads the provided [GalleryItem] and saves it to the gallery.
  Future<void> saveToGallery(PostItem item) async {
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

  Future<void> share(PostItem item) async {
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
            if ((current.horizontal.page ?? 0).round() > 0) {
              current.horizontal.previousPage(
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
            if ((current.horizontal.page ?? 0).round() <
                current.items.length - 1) {
              current.horizontal.nextPage(
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

  bool _backHandler(bool _, RouteInfo __) {
    shouldClose?.call();
    return true;
  }

  void _pageListener() {
    if (vertical.hasClients && !_ignorePageListener) {
      final rounded = vertical.page?.round() ?? 0;

      if (rounded != index.value) {
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

        print('_pageListener() -> index: ${index.value}, key: ${key.value}');
      }
    }
  }
}

class Post implements Comparable<Post> {
  Post({
    required this.id,
    this.itemId,
    List<PostItem> items = const [],
    int initial = 0,
    this.author,
    this.description,
    this.postedAt,
  }) : items = RxList(items),
       horizontal = PageController(initialPage: initial, keepPage: false),
       index = RxInt(initial);

  factory Post.fromMediaItem(MediaItem item) {
    ChatMessage? message;

    if (item.item is ChatMessage) {
      message = item.item as ChatMessage;
    }

    return Post(
      id: item.id,
      itemId: item.item?.id,
      items: item.attachments.map((e) => PostItem(e)).toList(),
      initial: 0,
      author: item.item?.author,
      description: message?.text,
      postedAt: item.item?.at,
    );
  }

  final String id;
  final ChatItemId? itemId;

  final User? author;
  ChatMessageText? description;
  final PreciseDateTime? postedAt;

  final PageController horizontal;
  final RxInt index;

  final RxList<PostItem> items;

  @override
  int get hashCode =>
      Object.hashAll([id, author, description, postedAt, index.value, items]);

  void init() {
    horizontal.addListener(_pageListener);
  }

  void dispose() {
    horizontal.removeListener(_pageListener);
    for (var e in items) {
      e.dispose();
    }
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

  void _pageListener() {
    if (horizontal.hasClients) {
      final rounded = horizontal.page?.round() ?? 0;
      index.value = rounded;
    }
  }
}

class PostItem {
  PostItem(this.attachment);

  final Attachment attachment;

  final Rx<ReactivePlayerController?> video = Rx(null);

  @override
  int get hashCode => attachment.hashCode;

  @override
  bool operator ==(Object other) {
    return other is PostItem && other.attachment == attachment;
  }

  void dispose() {
    video.value?.dispose();
  }

  @override
  String toString() {
    return 'PostItem($attachment, video: $video)';
  }
}

class ReactivePlayerController {
  ReactivePlayerController(this.controller) {
    controller.addListener(_listener);
  }

  final VideoPlayerController controller;

  final RxList<DurationRange> buffered = RxList();
  final RxBool isBuffering = RxBool(true);
  final RxBool isLooping = RxBool(false);
  final RxBool isPlaying = RxBool(false);
  final RxBool isCompleted = RxBool(false);
  final Rx<Size> size = Rx(Size.zero);
  final Rx<Duration> position = Rx(Duration.zero);
  final Rx<Duration> duration = Rx(Duration.zero);
  final RxDouble volume = RxDouble(0);

  void dispose() {
    controller.removeListener(_listener);
  }

  Future<void> play() async {
    await controller.play();
  }

  Future<void> pause() async {
    await controller.pause();
  }

  Future<void> seekTo(Duration to) async {
    await controller.seekTo(to);
  }

  Future<void> setRate(double speed) async {
    controller.setPlaybackSpeed(speed);
  }

  Future<void> setVolume(double volume) async {
    controller.setVolume(volume);
  }

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
