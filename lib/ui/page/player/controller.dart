import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mutex/mutex.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/domain/repository/paginated.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/application_settings.dart';
import '/domain/model/attachment.dart';
import '/domain/repository/settings.dart';
import '/util/platform_utils.dart';

class MediaItem implements Comparable<MediaItem> {
  MediaItem(this.attachments, this.item, {this.video});

  final List<Attachment> attachments;
  final ChatItem? item;

  String get id =>
      item?.key.toString() ?? 'a_${attachments.map((e) => e.id.val).join('_')}';

  VideoController? video;
  PageController? slides;

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

  final RxMap<String, VideoController> videos = RxMap();
  final Map<String, ReactivePageController> slides = {};

  /// Latest volume value for [VideoController] being displayed.
  double? latestVolume;

  late final PageController pages;
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
    final double? page = pages.page;
    return page != null && page.round() < source.length - 1;
  }

  bool get hasPreviousPage {
    final double? page = pages.page;
    return page != null && page.round() > 0;
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
    pages = PageController(initialPage: _index);
    index = RxInt(pages.initialPage);

    slides[key.value] ??= ReactivePageController(initialPage: initialIndex)
      ..init();

    print('onInit() -> index: ${index.value}, key: ${key.value}');
    print('onInit() -> IDs: ${source.values.map((e) => e.id)}');

    _sourceSubscription?.cancel();
    _sourceSubscription = source.items.changes.listen((_) {
      final int previous = index.value;

      index.value = _index;

      if (previous != index.value) {
        key.value = source.values.elementAtOrNull(index.value)?.id ?? key.value;

        _ignorePageListener = true;
        pages.jumpToPage(index.value);
        _ignorePageListener = false;

        // if (scrollController.hasClients) {
        //   itemScrollController.jumpTo(index: index.value);
        // }

        print(
          '_sourceSubscription -> index: ${index.value}, key: ${key.value}',
        );
      }
    });

    HardwareKeyboard.instance.addHandler(_keyboardHandler);
    pages.addListener(_pageListener);
    super.onInit();
  }

  @override
  void onClose() {
    HardwareKeyboard.instance.removeHandler(_keyboardHandler);
    pages.removeListener(_pageListener);
    _sourceSubscription?.cancel();

    for (var e in slides.values) {
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

    // final MediaItem? item = source.items[key.value];
    final VideoController? video = videos[key.value];

    if (video != null) {
      final isFinished = video.player.state.completed;
      if (video.player.state.playing) {
        video.player.pause();
      } else {
        if (isFinished) {
          video.player.seek(const Duration());
        }
        video.player.play();
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

    await pages.nextPage(
      duration: Duration(milliseconds: 150),
      curve: Curves.ease,
    );
  }

  Future<void> previous() async {
    if (!hasPreviousPage) {
      return;
    }

    await pages.previousPage(
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
          final VideoController? video = videos[key.value];
          if (video != null) {
            final int seconds = video.player.state.position.inSeconds;
            video.player.seek(Duration(seconds: max(seconds - 5, 0)));
            return true;
          }

          final MediaItem? item = source.items[key.value];
          final ReactivePageController? controller = slides[key.value];

          if (item != null &&
              controller != null &&
              item.attachments.length >= 2) {
            if ((controller.controller.page ?? 0).round() > 0) {
              controller.controller.previousPage(
                duration: Duration(milliseconds: 200),
                curve: Curves.ease,
              );
            }
            return true;
          }

          return false;

        case LogicalKeyboardKey.arrowRight:
          final VideoController? video = videos[key.value];
          if (video != null) {
            final int seconds = video.player.state.position.inSeconds;
            video.player.seek(
              Duration(
                seconds: min(
                  seconds + 5,
                  video.player.state.duration.inSeconds,
                ),
              ),
            );
            return true;
          }

          final MediaItem? item = source.items[key.value];
          final ReactivePageController? controller = slides[key.value];

          if (item != null &&
              controller != null &&
              item.attachments.length >= 2) {
            if ((controller.controller.page ?? 0).round() <
                item.attachments.length - 1) {
              controller.controller.nextPage(
                duration: Duration(milliseconds: 200),
                curve: Curves.ease,
              );
            }
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
    if (pages.hasClients && !_ignorePageListener) {
      final rounded = pages.page?.round() ?? 0;

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

class ReactivePageController {
  ReactivePageController({int initialPage = 0})
    : controller = PageController(initialPage: initialPage, keepPage: false),
      index = RxInt(initialPage);

  final PageController controller;
  final RxInt index;

  void init() {
    controller.addListener(_pageListener);
  }

  void dispose() {
    controller.removeListener(_pageListener);
  }

  void _pageListener() {
    if (controller.hasClients) {
      final rounded = controller.page?.round() ?? 0;
      index.value = rounded;
    }
  }
}
