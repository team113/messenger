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

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
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
    String? initialKey,
    this.initialIndex = 0,
  }) : key = RxString(initialKey ?? '');

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
    vertical = PageController(initialPage: _index);
    index = RxInt(vertical.initialPage);

    for (var e in source.items.values) {
      posts.add(Post.fromMediaItem(e)..init());
    }
    posts.sort();

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
    });

    HardwareKeyboard.instance.addHandler(_keyboardHandler);
    vertical.addListener(_pageListener);
    super.onInit();
  }

  @override
  void onClose() {
    HardwareKeyboard.instance.removeHandler(_keyboardHandler);
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

    final VideoPlayerController? video = item?.video.value;
    if (video != null) {
      final bool isFinished = video.value.isCompleted;

      if (video.value.isPlaying) {
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

          final VideoPlayerController? video = item?.video.value;
          if (video != null) {
            final int seconds = video.value.position.inSeconds;
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

          final VideoPlayerController? video = item?.video.value;
          if (video != null) {
            final int seconds = video.value.position.inSeconds;
            video.seekTo(
              Duration(
                seconds: min(seconds + 5, video.value.duration.inSeconds),
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

  void _pageListener() {
    if (vertical.hasClients && !_ignorePageListener) {
      final rounded = vertical.page?.round() ?? 0;

      if (rounded != index.value) {
        index.value = rounded;

        // for (var e in slides.values) {
        //   e.controller.
        // }

        // if (scrollController.hasClients) {
        //   itemScrollController.scrollTo(
        //     index: index.value,
        //     duration: Duration(milliseconds: 100),
        //     curve: Curves.ease,
        //     alignment: 0,
        //   );
        // }

        key.value = source.values.elementAtOrNull(rounded)?.id ?? key.value;
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

  final Rx<VideoPlayerController?> video = Rx(null);

  @override
  int get hashCode => attachment.hashCode;

  @override
  bool operator ==(Object other) {
    return other is PostItem && other.attachment == attachment;
  }

  @override
  String toString() {
    return 'PostItem($attachment, video: $video)';
  }
}
