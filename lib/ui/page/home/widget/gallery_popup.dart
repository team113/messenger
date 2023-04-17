// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable
// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';

import '/l10n/l10n.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/call/widget/round_button.dart';
import '/ui/page/home/page/chat/widget/video.dart';
import '/ui/page/home/page/chat/widget/web_image/web_image.dart';
import '/ui/page/home/widget/init_callback.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// Item in a [GalleryPopup].
///
/// [GalleryItem] is treated as a video if [isVideo] is `true`, or as an image
/// otherwise.
class GalleryItem {
  GalleryItem({
    required this.link,
    required this.name,
    required this.size,
    this.checksum,
    this.isVideo = false,
    this.onError,
  });

  /// Constructs a [GalleryItem] treated as an image.
  factory GalleryItem.image(
    String link,
    String name, {
    int? size,
    String? checksum,
    Future<void> Function()? onError,
  }) =>
      GalleryItem(
        link: link,
        name: name,
        size: size,
        checksum: checksum,
        isVideo: false,
        onError: onError,
      );

  /// Constructs a [GalleryItem] treated as a video.
  factory GalleryItem.video(
    String link,
    String name, {
    int? size,
    String? checksum,
    Future<void> Function()? onError,
  }) =>
      GalleryItem(
        link: link,
        name: name,
        size: size,
        checksum: checksum,
        isVideo: true,
        onError: onError,
      );

  /// Indicator whether this [GalleryItem] is treated as a video.
  final bool isVideo;

  /// Original URL to the file this [GalleryItem] represents.
  String link;

  /// SHA-256 checksum of the file this [GalleryItem] represents.
  final String? checksum;

  /// Name of the file this [GalleryItem] represents.
  final String name;

  /// Size in bytes of the file this [GalleryItem] represents.
  final int? size;

  /// Callback, called on the fetch errors of this [GalleryItem].
  final Future<void> Function()? onError;
}

/// Animated gallery of [GalleryItem]s.
class GalleryPopup extends StatefulWidget {
  const GalleryPopup({
    Key? key,
    this.children = const [],
    this.initial = 0,
    this.initialKey,
    this.onPageChanged,
    this.onTrashPressed,
  }) : super(key: key);

  /// [List] of [GalleryItem]s to display in a gallery.
  final List<GalleryItem> children;

  /// Optional [GlobalKey] of the [Object] to animate gallery from/to.
  final GlobalKey? initialKey;

  /// Initial gallery index of the [GalleryItem]s in [children].
  final int initial;

  /// Callback, called when the displayed [GalleryItem] is changed.
  final void Function(int)? onPageChanged;

  /// Callback, called when a remove action of a [GalleryItem] at the provided
  /// index is triggered.
  final void Function(int index)? onTrashPressed;

  /// Displays a dialog with the provided [gallery] above the current contents.
  static Future<T?> show<T extends Object?>({
    required BuildContext context,
    required GalleryPopup gallery,
  }) {
    return showGeneralDialog(
      context: context,
      pageBuilder: (
        BuildContext buildContext,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        final CapturedThemes themes = InheritedTheme.capture(
          from: context,
          to: Navigator.of(context, rootNavigator: true).context,
        );
        return themes.wrap(gallery);
      },
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      useRootNavigator: PlatformUtils.isMobile ? false : true,
    );
  }

  @override
  State<GalleryPopup> createState() => _GalleryPopupState();
}

/// State of a [GalleryPopup], used to implement its logic.
class _GalleryPopupState extends State<GalleryPopup>
    with TickerProviderStateMixin {
  /// [AnimationController] controlling the opening and closing gallery
  /// animation.
  late final AnimationController _fading;

  /// [AnimationController] controlling the sliding upward or downward
  /// animation.
  AnimationController? _sliding;

  /// Index of the selected [GalleryItem].
  int _page = 0;

  /// [PageController] controlling the [PageView].
  late final PageController _pageController;

  /// [Map] of [VideoPlayerController] controlling the video playback used to
  /// play/pause the active videos on keyboard presses.
  final Map<int, VideoPlayerController> _videoControllers = {};

  /// [CurvedAnimation] of the [_sliding] animation.
  late CurvedAnimation _curve;

  /// [Curve] of [_fading] out animation.
  Curve _curveOut = Curves.easeOutQuint;

  /// Indicator whether this [GalleryPopup] is in fullscreen mode.
  final RxBool _isFullscreen = RxBool(false);

  /// [StreamSubscription] to the fullscreen changes.
  StreamSubscription? _onFullscreen;

  /// [Rect] of an [Object] to animate this [GalleryPopup] from/to.
  late Rect _bounds;

  /// Discard the first [LayoutBuilder] frame since no widget is drawn yet.
  bool _firstLayout = true;

  /// Indicator whether vertical drag of this [GalleryPopup] is allowed or not.
  bool _allowDrag = false;

  /// Animated [RelativeRect] of this [GalleryPopup].
  RelativeRect _rect = RelativeRect.fill;

  /// Pops this [GalleryPopup] route off the [Navigator].
  void Function()? _pop;

  /// Indicator whether the right arrow button should be visible.
  bool _displayRight = false;

  /// Indicator whether the left arrow button should be visible.
  bool _displayLeft = false;

  /// Indicator whether the close gallery button should be visible.
  bool _displayClose = false;

  /// Indicator whether the fullscreen gallery button should be visible.
  bool _displayFullscreen = false;

  /// [FocusNode] of the keyboard input.
  FocusNode node = FocusNode();

  /// Indicator whether the [PageView.pageSnapping] should be `false`.
  bool _ignorePageSnapping = false;

  /// [Timer] resetting [_ignorePageSnapping].
  Timer? _ignoreSnappingTimer;

  /// [Timer] hiding the control buttons.
  Timer? _resetControlsTimer;

  /// Indicator whether all the control buttons should be visible.
  bool _showControls = true;

  /// Indicator whether this [GalleryPopup] hasn't been scrolled since it was
  /// initially opened.
  final bool _isInitialPage = true;

  /// Indicator whether the currently visible [GalleryItem] is zoomed.
  final bool _isZoomed = false;

  @override
  void initState() {
    _fading = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      debugLabel: '$runtimeType',
    )..addStatusListener(
        (status) {
          switch (status) {
            case AnimationStatus.dismissed:
              _curveOut = Curves.easeOutQuint;
              _pageController.dispose();
              _ignoreSnappingTimer?.cancel();
              _sliding?.dispose();
              _pop?.call();
              break;

            case AnimationStatus.reverse:
            case AnimationStatus.forward:
              // No-op.
              break;

            case AnimationStatus.completed:
              _curveOut = Curves.easeInQuint;
              break;
          }
        },
      );

    _bounds = _calculatePosition() ?? Rect.largest;

    _page = widget.initial;
    _pageController = PageController(initialPage: _page);

    _sliding = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      debugLabel: '$runtimeType',
    );

    _rect = RelativeRect.fill;
    _curve = CurvedAnimation(parent: _sliding!, curve: Curves.linear);
    _fading.forward();

    _onFullscreen ??= WebUtils.onFullscreenChange.listen((b) {
      if (b) {
        _enterFullscreen();
      } else {
        _exitFullscreen();
      }
    });

    node.requestFocus();

    Future.delayed(Duration.zero, _displayControls);

    super.initState();
  }

  @override
  void dispose() {
    _onFullscreen?.cancel();
    if (_isFullscreen.isTrue) {
      _exitFullscreen();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_firstLayout) {
          _bounds = _calculatePosition() ?? _bounds;
        } else {
          _pop = Navigator.of(context).pop;
          _firstLayout = false;
        }

        var fade = Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _fading,
            curve: const Interval(0, 0.5, curve: Curves.ease),
          ),
        );

        RelativeRectTween tween() => RelativeRectTween(
              begin: RelativeRect.fromSize(_bounds, constraints.biggest),
              end: RelativeRect.fromLTRB(
                Tween<double>(begin: 0, end: _rect.left).evaluate(_curve),
                Tween<double>(begin: 0, end: _rect.top).evaluate(_curve),
                Tween<double>(begin: 0, end: _rect.right).evaluate(_curve),
                Tween<double>(begin: 0, end: _rect.bottom).evaluate(_curve),
              ),
            );

        return Stack(
          children: [
            AnimatedBuilder(
              animation: _fading,
              builder: (context, child) => Container(
                color: Colors.black.withOpacity(0.9 * _fading.value),
              ),
            ),
            AnimatedBuilder(
              animation: _fading,
              builder: (context, child) {
                return AnimatedBuilder(
                    animation: _sliding!,
                    builder: (context, child) {
                      return PositionedTransition(
                        rect: tween().animate(
                          CurvedAnimation(
                            parent: _fading,
                            curve: Curves.easeOutQuint,
                            reverseCurve: _curveOut,
                          ),
                        ),
                        child: FadeTransition(
                          opacity: fade,
                          child: GestureDetector(
                            behavior: HitTestBehavior.deferToChild,
                            onTap: PlatformUtils.isMobile
                                ? null
                                : () {
                                    if (_pageController.page == _page) {
                                      _dismiss();
                                    }
                                  },
                            onVerticalDragStart:
                                _isZoomed ? null : _onVerticalDragStart,
                            onVerticalDragUpdate:
                                _isZoomed ? null : _onVerticalDragUpdate,
                            onVerticalDragEnd:
                                _isZoomed ? null : _onVerticalDragEnd,
                            child: KeyboardListener(
                              autofocus: true,
                              focusNode: node,
                              onKeyEvent: _onKeyEvent,
                              child: Listener(
                                onPointerSignal: _onPointerSignal,
                                child: _PageView(
                                  saveToGallery: _saveToGallery,
                                  share: _share,
                                  children: widget.children,
                                  page: _page,
                                  isZoomed: _isZoomed,
                                  isInitialPage: _isInitialPage,
                                  dismiss: _dismiss,
                                  isFullscreen: _isFullscreen,
                                  node: node,
                                  toggleFullscreen: _toggleFullscreen,
                                  videoControllers: _videoControllers,
                                  pageController: _pageController,
                                  bounds: _bounds,
                                  calculatePosition: _calculatePosition,
                                  onPageChanged: widget.onPageChanged,
                                  ignorePageSnapping: _ignorePageSnapping,
                                  download: _download,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    });
              },
            ),
            _BuildInterface(
              page: _page,
              children: widget.children,
              fading: _fading,
              displayLeft: _displayLeft,
              showControls: _showControls,
              node: node,
              pageController: _pageController,
              displayRight: _displayRight,
              displayClose: _displayClose,
              dismiss: _dismiss,
              onTrashPressed: widget.onTrashPressed,
              displayFullscreen: _displayFullscreen,
              toggleFullscreen: _toggleFullscreen,
              isFullscreen: _isFullscreen,
            ),
          ],
        );
      },
    );
  }

  /// Starts a dismiss animation.
  void _dismiss() {
    _fading.reverse();
    _exitFullscreen();
    _onFullscreen?.cancel();
  }

  /// Handles the [GestureDetector.onVerticalDragStart] callback by animating
  /// vertical dragging of the currently displayed [GalleryItem].
  void _onVerticalDragStart(DragStartDetails d) {
    _allowDrag = d.kind == PointerDeviceKind.touch;
    if (_allowDrag) {
      _curve = CurvedAnimation(
        parent: _sliding!,
        curve: Curves.elasticIn,
      );
      _rect = RelativeRect.fill;
      _sliding?.value = 1.0;
    }
  }

  /// Handles the [GestureDetector.onVerticalDragUpdate] callback by continuing
  /// animation of vertical dragging of the currently displayed [GalleryItem].
  void _onVerticalDragUpdate(DragUpdateDetails d) {
    if (_allowDrag) {
      setState(() {
        _rect = _rect.shift(d.delta);
      });
    }
  }

  /// Handles the [GestureDetector.onVerticalDragEnd] callback by closing the
  /// gallery if the currently displayed [GalleryItem] dragged vertically too
  /// far.
  void _onVerticalDragEnd(DragEndDetails d) {
    if (_allowDrag) {
      if (_rect.top.abs() > 50) {
        _curve = CurvedAnimation(
          parent: _sliding!,
          curve: Curves.linear,
        );

        _dismiss();
      } else {
        _sliding?.reverse();
      }
    }
  }

  /// Handles the [KeyboardListener.onKeyEvent] callback by switching the
  /// currently displayed [GalleryItem] on arrow keys, closing the gallery on
  /// an escape key, and pausing/playing video on a space key.
  void _onKeyEvent(KeyEvent k) {
    if (k is KeyUpEvent) {
      if (k.physicalKey == PhysicalKeyboardKey.arrowRight) {
        if (_page < widget.children.length - 1) {
          _pageController.animateToPage(
            _page + 1,
            curve: Curves.linear,
            duration: const Duration(milliseconds: 200),
          );
        }
      } else if (k.physicalKey == PhysicalKeyboardKey.arrowLeft) {
        if (_page > 0) {
          _pageController.animateToPage(
            _page - 1,
            curve: Curves.linear,
            duration: const Duration(milliseconds: 200),
          );
        }
      } else if (k.physicalKey == PhysicalKeyboardKey.escape) {
        _dismiss();
      } else if (k.physicalKey == PhysicalKeyboardKey.space) {
        _videoControllers.forEach((_, v) {
          if (v.value.isPlaying == true) {
            v.pause();
          } else {
            v.play();
          }
        });
      }
    }
  }

  /// Handles the [Listener.onPointerSignal] callback by switching the
  /// currently displayed [GalleryItem] on scrolling.
  void _onPointerSignal(PointerSignalEvent s) {
    if (widget.children.length > 1 && s is PointerScrollEvent) {
      bool horizontalPriority = false;

      // Handles horizontal scroll movement.
      if (!PlatformUtils.isMobile && s.scrollDelta.dx != 0) {
        if (s.scrollDelta.dx > 0) {
          if (_pageController.position.pixels <
              _pageController.position.maxScrollExtent) {
            _resetSnappingTimer();
            _pageController.jumpTo(
              _pageController.position.pixels + (s.scrollDelta.dx * 1.25),
            );
            horizontalPriority = true;
          } else {
            _pageController.jumpTo(_pageController.position.maxScrollExtent);
          }
        } else if (s.scrollDelta.dx < 0) {
          if (_pageController.position.pixels >
              _pageController.position.minScrollExtent) {
            _resetSnappingTimer();
            _pageController.jumpTo(
              _pageController.position.pixels + (s.scrollDelta.dx * 1.25),
            );
            horizontalPriority = true;
          } else {
            _pageController.jumpTo(_pageController.position.minScrollExtent);
          }
        }
      }

      // Handles vertical scroll movement.
      if (!_ignorePageSnapping && !horizontalPriority) {
        if (s.scrollDelta.dy > 0 && _page > 0) {
          _resetSnappingTimer();
          _pageController.animateToPage(
            _page - 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.linear,
          );
        } else if (s.scrollDelta.dy < 0 && _page < widget.children.length - 1) {
          _resetSnappingTimer();
          _pageController.animateToPage(
            _page + 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.linear,
          );
        }
      }
    }
  }

  /// Enters fullscreen mode if not [_isFullscreen] already.
  void _enterFullscreen() {
    if (_isFullscreen.isFalse) {
      _isFullscreen.value = true;
      PlatformUtils.enterFullscreen();
    }
  }

  /// Exits fullscreen mode if [_isFullscreen].
  void _exitFullscreen() {
    if (_isFullscreen.isTrue) {
      _isFullscreen.value = false;
      PlatformUtils.exitFullscreen();
    }
  }

  /// Toggles fullscreen mode.
  void _toggleFullscreen() {
    if (_isFullscreen.isTrue) {
      _exitFullscreen();
    } else {
      _enterFullscreen();
    }
  }

  /// Returns a [Rect] of an [Object] identified by the provided initial
  /// [GlobalKey].
  Rect? _calculatePosition() => widget.initialKey?.globalPaintBounds;

  /// Sets the [_ignorePageSnapping] to `true` and restarts the
  /// [_ignoreSnappingTimer].
  void _resetSnappingTimer() {
    setState(() => _ignorePageSnapping = true);
    _ignoreSnappingTimer?.cancel();
    _ignoreSnappingTimer = Timer(250.milliseconds, () {
      setState(() => _ignorePageSnapping = false);
    });
  }

  /// Downloads the provided [GalleryItem].
  Future<void> _download(GalleryItem item) async {
    try {
      try {
        await PlatformUtils.download(item.link, item.name, item.size);
      } catch (_) {
        if (item.onError != null) {
          await item.onError?.call();
          await PlatformUtils.download(item.link, item.name, item.size);
        } else {
          rethrow;
        }
      }

      if (mounted) {
        MessagePopup.success(item.isVideo
            ? 'label_video_downloaded'.l10n
            : 'label_image_downloaded'.l10n);
      }
    } catch (_) {
      MessagePopup.error('err_could_not_download'.l10n);
    }
  }

  /// Downloads the provided [GalleryItem] and saves it to the gallery.
  Future<void> _saveToGallery(GalleryItem item) async {
    try {
      try {
        await PlatformUtils.saveToGallery(item.link, item.name);
      } catch (_) {
        if (item.onError != null) {
          await item.onError?.call();
          await PlatformUtils.saveToGallery(item.link, item.name);
        } else {
          rethrow;
        }
      }

      if (mounted) {
        MessagePopup.success(item.isVideo
            ? 'label_video_saved_to_gallery'.l10n
            : 'label_image_saved_to_gallery'.l10n);
      }
    } catch (_) {
      MessagePopup.error('err_could_not_download'.l10n);
    }
  }

  /// Downloads the provided [GalleryItem] and opens a share dialog with it.
  Future<void> _share(GalleryItem item) async {
    try {
      try {
        await PlatformUtils.share(item.link, item.name);
      } catch (_) {
        if (item.onError != null) {
          await item.onError?.call();
          await PlatformUtils.share(item.link, item.name);
        } else {
          rethrow;
        }
      }
    } catch (_) {
      MessagePopup.error('err_could_not_download'.l10n);
    }
  }

  /// Toggles the [_showControls] indicator and starts the [_resetControlsTimer]
  /// resetting it.
  void _displayControls() {
    setState(() => _showControls = true);
    _resetControlsTimer?.cancel();
    _resetControlsTimer = Timer(3.seconds, () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }
}

/// Extension of a [GlobalKey] allowing getting global
/// [RenderObject.paintBounds].
extension GlobalKeyExtension on GlobalKey {
  /// Returns a [Rect] representing the [RenderObject.paintBounds] of the
  /// [Object] this [GlobalKey] represents.
  Rect? get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    final matrix = renderObject?.getTransformTo(null);

    if (matrix != null && renderObject?.paintBounds != null) {
      final rect = MatrixUtils.transformRect(matrix, renderObject!.paintBounds);
      return rect;
    } else {
      return null;
    }
  }
}

/// Returns the gallery view of its items itself.
class _PageView extends StatefulWidget {
  final Future<void> Function(GalleryItem item) saveToGallery;
  final Future<void> Function(GalleryItem item) share;
  final List<GalleryItem> children;
  int page;
  bool isZoomed;
  bool isInitialPage;
  final void Function() dismiss;
  final RxBool isFullscreen;
  final FocusNode node;
  final void Function() toggleFullscreen;
  final Map<int, VideoPlayerController> videoControllers;
  final PageController pageController;
  Rect bounds;
  final Rect? Function() calculatePosition;
  void Function(int)? onPageChanged;
  final bool ignorePageSnapping;
  final Future<void> Function(GalleryItem item) download;
  _PageView({
    Key? key,
    required this.saveToGallery,
    required this.share,
    required this.children,
    required this.page,
    required this.isZoomed,
    required this.isInitialPage,
    required this.dismiss,
    required this.isFullscreen,
    required this.node,
    required this.toggleFullscreen,
    required this.videoControllers,
    required this.pageController,
    required this.bounds,
    required this.calculatePosition,
    required this.onPageChanged,
    required this.ignorePageSnapping,
    required this.download,
  }) : super(key: key);

  @override
  State<_PageView> createState() => _PageViewState();
}

class _PageViewState extends State<_PageView> {
  @override
  Widget build(BuildContext context) {
    // Use more advanced [PhotoViewGallery] on native mobile platforms.
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      return ContextMenuRegion(
        actions: [
          ContextMenuButton(
            label: 'btn_save_to_gallery'.l10n,
            onPressed: () => widget.saveToGallery(widget.children[widget.page]),
          ),
          ContextMenuButton(
            label: 'btn_share'.l10n,
            onPressed: () => widget.share(widget.children[widget.page]),
          ),
          ContextMenuButton(
            label: 'btn_info'.l10n,
            onPressed: () {},
          ),
        ],
        moveDownwards: false,
        child: PhotoViewGallery.builder(
          scrollPhysics: const BouncingScrollPhysics(),
          scaleStateChangedCallback: (s) {
            setState(() => widget.isZoomed = s.isScaleStateZooming);
          },
          wantKeepAlive: false,
          builder: (BuildContext context, int index) {
            GalleryItem e = widget.children[index];

            if (!e.isVideo) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(e.link),
                initialScale: PhotoViewComputedScale.contained * 0.99,
                minScale: PhotoViewComputedScale.contained * 0.99,
                maxScale: PhotoViewComputedScale.contained * 3,
                errorBuilder: (_, __, ___) {
                  return InitCallback(
                    callback: () async {
                      await e.onError?.call();
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: const SizedBox(
                      height: 300,
                      child: Center(child: CustomProgressIndicator()),
                    ),
                  );
                },
              );
            }

            return PhotoViewGalleryPageOptions.customChild(
              disableGestures: e.isVideo,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: e.isVideo
                    ? Video(
                        e.link,
                        showInterfaceFor:
                            widget.isInitialPage ? 3.seconds : null,
                        onClose: widget.dismiss,
                        isFullscreen: widget.isFullscreen,
                        toggleFullscreen: () {
                          widget.node.requestFocus();
                          widget.toggleFullscreen();
                        },
                        onController: (c) {
                          if (c == null) {
                            widget.videoControllers.remove(index);
                          } else {
                            widget.videoControllers[index] = c;
                          }
                        },
                        onError: () async {
                          await e.onError?.call();
                          if (mounted) {
                            setState(() {});
                          }
                        },
                      )
                    : RetryImage(
                        e.link,
                        checksum: e.checksum,
                        onForbidden: () async {
                          await e.onError?.call();
                          if (mounted) {
                            setState(() {});
                          }
                        },
                      ),
              ),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.contained * 3,
            );
          },
          itemCount: widget.children.length,
          loadingBuilder: (context, event) => Center(
            child: SizedBox(
              width: 20.0,
              height: 20.0,
              child: CustomProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              ),
            ),
          ),
          backgroundDecoration: const BoxDecoration(color: Colors.transparent),
          pageController: widget.pageController,
          onPageChanged: (i) {
            widget.isInitialPage = false;
            widget.isZoomed = false;
            setState(() => widget.page = i);
            widget.bounds = widget.calculatePosition() ?? widget.bounds;
            widget.onPageChanged?.call(i);
          },
        ),
      );
    }

    // Otherwise use the default [PageView].
    return PageView(
      controller: widget.pageController,
      physics:
          PlatformUtils.isMobile ? null : const NeverScrollableScrollPhysics(),
      onPageChanged: (i) {
        widget.isInitialPage = false;
        setState(() => widget.page = i);
        widget.bounds = widget.calculatePosition() ?? widget.bounds;
        widget.onPageChanged?.call(i);
      },
      pageSnapping: !widget.ignorePageSnapping,
      children: widget.children.mapIndexed((index, e) {
        return ContextMenuRegion(
          enabled: !PlatformUtils.isWeb,
          actions: [
            ContextMenuButton(
              label: 'btn_download'.l10n,
              onPressed: () => widget.download(widget.children[widget.page]),
            ),
            ContextMenuButton(
              label: 'btn_info'.l10n,
              onPressed: () {},
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: e.isVideo
                ? Video(
                    e.link,
                    showInterfaceFor: widget.isInitialPage ? 3.seconds : null,
                    onClose: widget.dismiss,
                    isFullscreen: widget.isFullscreen,
                    toggleFullscreen: () {
                      widget.node.requestFocus();
                      widget.toggleFullscreen();
                    },
                    onController: (c) {
                      if (c == null) {
                        widget.videoControllers.remove(index);
                      } else {
                        widget.videoControllers[index] = c;
                      }
                    },
                    onError: () async {
                      await e.onError?.call();
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  )
                : GestureDetector(
                    onTap: () {
                      if (widget.pageController.page == widget.page) {
                        widget.dismiss();
                      }
                    },
                    onDoubleTap: () {
                      widget.node.requestFocus();
                      widget.toggleFullscreen();
                    },
                    child: PlatformUtils.isWeb
                        ? IgnorePointer(child: WebImage(e.link))
                        : RetryImage(
                            e.link,
                            checksum: e.checksum,
                            onForbidden: () async {
                              await e.onError?.call();
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          ),
                  ),
          ),
        );
      }).toList(),
    );
  }
}

/// Returns the [List] of [GalleryPopup] interface [Widget]s.
class _BuildInterface extends StatefulWidget {
  final int page;
  final List<GalleryItem> children;
  final AnimationController fading;
  bool displayLeft;
  final bool showControls;
  final FocusNode node;
  final PageController pageController;
  bool displayRight;
  bool displayClose;
  final void Function() dismiss;
  final void Function(int)? onTrashPressed;
  bool displayFullscreen;
  final void Function() toggleFullscreen;
  final RxBool isFullscreen;
  _BuildInterface({
    Key? key,
    required this.page,
    required this.children,
    required this.fading,
    required this.displayLeft,
    required this.showControls,
    required this.node,
    required this.pageController,
    required this.displayRight,
    required this.displayClose,
    required this.dismiss,
    required this.onTrashPressed,
    required this.displayFullscreen,
    required this.toggleFullscreen,
    required this.isFullscreen,
  }) : super(key: key);

  @override
  State<_BuildInterface> createState() => _BuildInterfaceState();
}

class _BuildInterfaceState extends State<_BuildInterface> {
  @override
  Widget build(BuildContext context) {
    bool left = widget.page > 0;
    bool right = widget.page < widget.children.length - 1;

    final fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.fading,
        curve: const Interval(0, 0.5, curve: Curves.ease),
      ),
    );

    final List<Widget> widgets = [];

    if (!PlatformUtils.isMobile) {
      widgets.addAll([
        if (widget.children.length > 1) ...[
          FadeTransition(
            opacity: fade,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity:
                    (widget.displayLeft && left) || widget.showControls ? 1 : 0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 32),
                  child: WidgetButton(
                    onPressed: left
                        ? () {
                            widget.node.requestFocus();
                            widget.pageController.animateToPage(
                              widget.page - 1,
                              curve: Curves.linear,
                              duration: const Duration(milliseconds: 200),
                            );
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      width: 60 + 16,
                      height: double.infinity,
                      child: Center(
                        child: ConditionalBackdropFilter(
                          borderRadius: BorderRadius.circular(60),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0x794E5A78),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 1),
                              child: Icon(
                                Icons.keyboard_arrow_left_rounded,
                                color: left ? Colors.white : Colors.grey,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: fade,
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: (widget.displayRight && right) || widget.showControls
                    ? 1
                    : 0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 32),
                  child: WidgetButton(
                    onPressed: right
                        ? () {
                            widget.node.requestFocus();
                            widget.pageController.animateToPage(
                              widget.page + 1,
                              curve: Curves.linear,
                              duration: const Duration(milliseconds: 200),
                            );
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      width: 60 + 16,
                      height: double.infinity,
                      child: Center(
                        child: ConditionalBackdropFilter(
                          borderRadius: BorderRadius.circular(60),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0x794E5A78),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 1),
                              child: Icon(
                                Icons.keyboard_arrow_right_rounded,
                                color: right ? Colors.white : Colors.grey,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        FadeTransition(
          opacity: fade,
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, top: 8),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: (widget.displayClose || widget.showControls) ? 1 : 0,
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: RoundFloatingButton(
                    color: const Color(0x794E5A78),
                    onPressed: widget.dismiss,
                    withBlur: true,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.onTrashPressed == null)
          FadeTransition(
            opacity: fade,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity:
                      (widget.displayFullscreen || widget.showControls) ? 1 : 0,
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: RoundFloatingButton(
                      color: const Color(0x794E5A78),
                      onPressed: widget.toggleFullscreen,
                      withBlur: true,
                      assetWidth: 22,
                      asset: widget.isFullscreen.value
                          ? 'fullscreen_exit_white'
                          : 'fullscreen_enter_white',
                    ),
                  ),
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            children: [
              MouseRegion(
                opaque: false,
                onEnter: (d) => setState(() => widget.displayFullscreen = true),
                onExit: (d) => setState(() => widget.displayFullscreen = false),
                child: const SizedBox(width: 100, height: 100),
              ),
              Expanded(
                child: MouseRegion(
                  opaque: false,
                  onEnter: (d) => setState(() => widget.displayLeft = true),
                  onExit: (d) => setState(() => widget.displayLeft = false),
                  child: const SizedBox(width: 100),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            children: [
              MouseRegion(
                opaque: false,
                onEnter: (d) => setState(() => widget.displayClose = true),
                onExit: (d) => setState(() => widget.displayClose = false),
                child: const SizedBox(width: 100, height: 100),
              ),
              Expanded(
                child: MouseRegion(
                  opaque: false,
                  onEnter: (d) => setState(() => widget.displayRight = true),
                  onExit: (d) => setState(() => widget.displayRight = false),
                  child: const SizedBox(width: 100),
                ),
              ),
            ],
          ),
        ),
      ]);
    }

    widgets.addAll([
      if (widget.onTrashPressed != null)
        SafeArea(
          child: FadeTransition(
            opacity: fade,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: RoundFloatingButton(
                    color: const Color(0x794E5A78),
                    onPressed: () {
                      widget.onTrashPressed?.call(widget.page);
                      widget.dismiss();
                    },
                    withBlur: true,
                    assetWidth: 27.21,
                    asset: 'delete',
                  ),
                ),
              ),
            ),
          ),
        ),
    ]);

    return Stack(children: widgets);
  }
}
