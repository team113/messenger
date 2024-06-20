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
import 'dart:ui';

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '/domain/model/file.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/video/video.dart';
import '/ui/page/home/page/chat/widget/web_image/web_image.dart';
import '/ui/page/home/widget/retry_image.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/ui/worker/cache.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'gallery_button.dart';

/// Item in a [GalleryPopup].
///
/// [GalleryItem] is treated as a video if [isVideo] is `true`, or as an image
/// otherwise.
class GalleryItem {
  GalleryItem({
    this.id,
    required this.link,
    required this.name,
    required this.size,
    this.width,
    this.height,
    this.checksum,
    this.thumbhash,
    this.isVideo = false,
    this.onError,
  });

  /// Constructs a [GalleryItem] treated as an image.
  factory GalleryItem.image(
    String link,
    String name, {
    String? id,
    int? size,
    int? width,
    int? height,
    String? checksum,
    ThumbHash? thumbhash,
    FutureOr<void> Function()? onError,
  }) =>
      GalleryItem(
        id: id,
        link: link,
        name: name,
        size: size,
        width: width,
        height: height,
        checksum: checksum,
        thumbhash: thumbhash,
        isVideo: false,
        onError: onError,
      );

  /// Constructs a [GalleryItem] treated as a video.
  factory GalleryItem.video(
    String link,
    String name, {
    String? id,
    int? size,
    String? checksum,
    FutureOr<void> Function()? onError,
  }) =>
      GalleryItem(
        id: id,
        link: link,
        name: name,
        size: size,
        checksum: checksum,
        isVideo: true,
        onError: onError,
      );

  /// Unique identifier of this [GalleryItem], if any.
  final String? id;

  /// Indicator whether this [GalleryItem] is treated as a video.
  final bool isVideo;

  /// Original URL to the file this [GalleryItem] represents.
  String link;

  /// SHA-256 checksum of the file this [GalleryItem] represents.
  final String? checksum;

  /// [ThumbHash] of the image this [GalleryItem] represents.
  final ThumbHash? thumbhash;

  /// Name of the file this [GalleryItem] represents.
  final String name;

  /// Size in bytes of the file this [GalleryItem] represents.
  final int? size;

  /// Width of the image this [GalleryItem] represents.
  final int? width;

  /// Height of the image this [GalleryItem] represents.
  final int? height;

  /// Callback, called on the fetch errors of this [GalleryItem].
  final FutureOr<void> Function()? onError;

  /// Returns aspect ratio of the image this [GalleryItem] represents.
  double? get _aspectRatio {
    if (width != null && height != null) {
      return width! / height!;
    }

    return null;
  }
}

/// Animated gallery of [GalleryItem]s.
class GalleryPopup extends StatefulWidget {
  const GalleryPopup({
    super.key,
    this.children = const [],
    this.initial = 0,
    this.initialKey,
    this.onPageChanged,
    this.onTrashPressed,
    this.nextLoading = false,
    this.previousLoading = false,
  });

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

  /// Indicator whether the next item button should display a
  /// [CustomProgressIndicator] over it.
  final bool nextLoading;

  /// Indicator whether the previous item button should display a
  /// [CustomProgressIndicator] over it.
  final bool previousLoading;

  /// Displays a dialog with the provided [gallery] above the current contents.
  static Future<T?> show<T extends Object?>({
    required BuildContext context,
    required Widget gallery,
  }) {
    final style = Theme.of(context).style;

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
      barrierColor: style.colors.transparent,
      transitionDuration: Duration.zero,
      useRootNavigator: context.isMobile ? false : true,
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
  late final AnimationController _fading = AnimationController(
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

  /// [AnimationController] controlling the sliding upward or downward
  /// animation.
  AnimationController? _sliding;

  /// Index of the selected [GalleryItem].
  int _page = 0;

  /// [PageController] controlling the [PageView].
  late final PageController _pageController;

  /// [Map] of [VideoController] controlling the video playback used to
  /// play/pause the active videos on keyboard presses.
  final Map<int, VideoController> _videoControllers = {};

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

  /// [Timer] setting [_displayLeft] or [_displayRight] to `false`.
  Timer? _displayTimer;

  /// [FocusNode] of the keyboard input.
  final FocusNode _node = FocusNode();

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
  bool _isInitialPage = true;

  /// Indicator whether the currently visible [GalleryItem] is zoomed.
  bool _isZoomed = false;

  /// [PhotoViewController] for zooming [PhotoViewGallery] in and out.
  final PhotoViewController _photoController = PhotoViewController();

  // TODO: This is a hack for a feature that should be implemented in
  //       `photo_view` directly:
  //       https://github.com/bluefireteam/photo_view/issues/425
  /// [AnimationController] animating the [_photoController] scaling in.
  late final AnimationController _photo = AnimationController(
    vsync: this,
    debugLabel: '$runtimeType',
    duration: const Duration(milliseconds: 200),
  )..addListener(() {
      _photoController.scale = 1 +
          CurveTween(curve: Curves.ease).evaluate(_photo) * (_photoScale - 1);
    });

  /// Scale to apply the [_photoController] to during its [_photo] animation.
  double _photoScale = 1;

  @override
  void initState() {
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

    _node.requestFocus();

    Future.delayed(Duration.zero, _displayControls);

    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.add(_onBack);
    }

    super.initState();
  }

  @override
  void dispose() {
    _photo.dispose();
    _fading.dispose();
    _onFullscreen?.cancel();
    _displayTimer?.cancel();
    if (_isFullscreen.isTrue) {
      _exitFullscreen();
    }

    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.remove(_onBack);
    }

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GalleryPopup oldWidget) {
    if (widget.initial != oldWidget.initial) {
      final int offset = widget.children.length - oldWidget.children.length;

      if (widget.initial != oldWidget.initial) {
        if (oldWidget.children.length == 1) {
          _page = widget.initial;
          _pageController.jumpToPage(_page);
          return;
        }
      }

      if (offset != 0) {
        _pageController.jumpToPage(offset);
        _page = offset;
      }

      if (widget.initial != oldWidget.initial + offset ||
          oldWidget.children.length == 1) {
        _page = widget.initial;
        _pageController.jumpToPage(_page);
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return LayoutBuilder(
      key: const Key('GalleryPopup'),
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
                color:
                    style.colors.onBackground.withOpacity(0.9 * _fading.value),
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
                              focusNode: _node,
                              onKeyEvent: _onKeyEvent,
                              child: Listener(
                                onPointerSignal: _onPointerSignal,
                                child: _pageView(),
                              ),
                            ),
                          ),
                        ),
                      );
                    });
              },
            ),
            ..._buildInterface(),
          ],
        );
      },
    );
  }

  /// Returns the gallery view of its items itself.
  Widget _pageView() {
    final style = Theme.of(context).style;

    // Use more advanced [PhotoViewGallery] on native mobile platforms.
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      return ContextMenuRegion(
        actions: [
          ContextMenuButton(
            label: 'btn_save_to_gallery'.l10n,
            onPressed: () => _saveToGallery(widget.children[_page]),
          ),
          ContextMenuButton(
            label: 'btn_share'.l10n,
            onPressed: () => _share(widget.children[_page]),
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
            setState(() => _isZoomed = s.isScaleStateZooming);
          },
          wantKeepAlive: false,
          builder: (BuildContext context, int index) {
            final GalleryItem e = widget.children[index];

            return PhotoViewGalleryPageOptions.customChild(
              controller: _photoController,
              disableGestures: e.isVideo,
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.contained * 3,
              scaleStateCycle: (s) {
                switch (s) {
                  case PhotoViewScaleState.initial:
                    _animatePhotoScaleTo(
                      (PhotoViewComputedScale.contained * 2).multiplier,
                    );
                    return PhotoViewScaleState.zoomedIn;

                  case PhotoViewScaleState.covering:
                    return PhotoViewScaleState.covering;

                  case PhotoViewScaleState.originalSize:
                    return PhotoViewScaleState.initial;

                  case PhotoViewScaleState.zoomedIn:
                  case PhotoViewScaleState.zoomedOut:
                    return PhotoViewScaleState.initial;

                  default:
                    return PhotoViewScaleState.initial;
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: e.isVideo
                    ? VideoView(
                        e.link,
                        checksum: e.checksum,
                        showInterfaceFor: _isInitialPage ? 3.seconds : null,
                        onClose: _dismiss,
                        isFullscreen: _isFullscreen,
                        toggleFullscreen: () {
                          _node.requestFocus();
                          _toggleFullscreen();
                        },
                        onController: (c) {
                          if (c == null) {
                            _videoControllers.remove(index);
                          } else {
                            _videoControllers[index] = c;
                          }
                        },
                        onError: e.onError,
                      )
                    : RetryImage(
                        e.link,
                        width: e.width?.toDouble(),
                        height: e.height?.toDouble(),
                        aspectRatio: e._aspectRatio,
                        checksum: e.checksum,
                        thumbhash: e.thumbhash,
                        onForbidden: e.onError,
                        fit: BoxFit.contain,
                      ),
              ),
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
          backgroundDecoration: BoxDecoration(color: style.colors.transparent),
          pageController: _pageController,
          onPageChanged: (i) {
            _isInitialPage = false;
            _isZoomed = false;
            setState(() => _page = i);
            _bounds = _calculatePosition() ?? _bounds;
            widget.onPageChanged?.call(i);
          },
        ),
      );
    }

    // Otherwise use the default [PageView].
    return PageView(
      controller: _pageController,
      physics: PlatformUtils.isMobile
          ? null
          : PlatformUtils.isWeb
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
      onPageChanged: (i) {
        _isInitialPage = false;
        setState(() => _page = i);
        _bounds = _calculatePosition() ?? _bounds;
        widget.onPageChanged?.call(i);
      },
      pageSnapping: !_ignorePageSnapping,
      children: widget.children.mapIndexed((index, e) {
        final Widget child;

        if (e.isVideo) {
          child = VideoView(
            e.link,
            checksum: e.checksum,
            showInterfaceFor: _isInitialPage ? 3.seconds : null,
            onClose: _dismiss,
            isFullscreen: _isFullscreen,
            toggleFullscreen: () {
              _node.requestFocus();
              _toggleFullscreen();
            },
            onController: (c) {
              if (c == null) {
                _videoControllers.remove(index);
              } else {
                _videoControllers[index] = c;
              }
            },
            onError: e.onError,
          );
        } else {
          final Widget image;

          if (PlatformUtils.isWeb) {
            image = WebImage(
              e.link,
              width: e.width?.toDouble(),
              height: e.height?.toDouble(),
              thumbhash: e.thumbhash,
              onForbidden: e.onError,

              // TODO: Wait for HTML to support specifying
              //       download name:
              //       https://github.com/whatwg/html/issues/2722
              // name: e.name,
            );
          } else {
            image = RetryImage(
              e.link,
              width:
                  _isFullscreen.isTrue ? double.infinity : e.width?.toDouble(),
              height:
                  _isFullscreen.isTrue ? double.infinity : e.height?.toDouble(),
              aspectRatio: e._aspectRatio,
              checksum: e.checksum,
              thumbhash: e.thumbhash,
              onForbidden: e.onError,
              fit: BoxFit.contain,
            );
          }

          child = GestureDetector(
            onTap: () {
              if (_pageController.page == _page) {
                _dismiss();
              }
            },
            onDoubleTap: () {
              _node.requestFocus();
              _toggleFullscreen();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1, minHeight: 1),
              child: image,
            ),
          );
        }

        return ContextMenuRegion(
          enabled: !PlatformUtils.isWeb,
          actions: [
            ContextMenuButton(
              label: 'btn_download'.l10n,
              onPressed: () => _download(widget.children[_page]),
            ),
            ContextMenuButton(
              label: 'btn_download_as'.l10n,
              onPressed: () => _downloadAs(widget.children[_page]),
            ),
            ContextMenuButton(
              label: 'btn_save_to_gallery'.l10n,
              onPressed: () => _saveToGallery(widget.children[_page]),
            ),
            ContextMenuButton(
              label: 'btn_info'.l10n,
              onPressed: () {},
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: child,
          ),
        );
      }).toList(),
    );
  }

  /// Returns the [List] of [GalleryPopup] interface [Widget]s.
  List<Widget> _buildInterface() {
    bool left = _page > 0;
    bool right = _page < widget.children.length - 1;

    final fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fading,
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
                opacity: _displayLeft || _showControls ? 1 : 0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 32),
                  child: WidgetButton(
                    onPressed: left ? () => _animateToPage(_page - 1) : null,
                    child: Container(
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      width: 60 + 16,
                      height: double.infinity,
                      child: Center(
                        child: GalleryButton(
                          key: Key(left ? 'LeftButton' : 'NoLeftButton'),
                          onPressed: left
                              ? () {
                                  _animateToPage(_page - 1);
                                  _displayForTime(
                                    (v) => _displayLeft = _displayLeft || v,
                                  );
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 1),
                            child: Center(
                              child: widget.previousLoading
                                  ? const CustomProgressIndicator()
                                  : Transform.translate(
                                      offset: const Offset(-1, 0),
                                      child: SvgIcon(
                                        left
                                            ? SvgIcons.arrowLeft
                                            : SvgIcons.arrowLeftDisabled,
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
          ),
          FadeTransition(
            opacity: fade,
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _displayRight || _showControls ? 1 : 0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 32),
                  child: WidgetButton(
                    onPressed: right ? () => _animateToPage(_page + 1) : null,
                    child: Container(
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      width: 60 + 16,
                      height: double.infinity,
                      child: Center(
                        child: GalleryButton(
                          key: Key(right ? 'RightButton' : 'NoRightButton'),
                          onPressed: right
                              ? () {
                                  _animateToPage(_page + 1);
                                  _displayForTime(
                                    (v) => _displayRight = _displayRight || v,
                                  );
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 1),
                            child: Center(
                              child: widget.nextLoading
                                  ? const CustomProgressIndicator()
                                  : Transform.translate(
                                      offset: const Offset(1, 0),
                                      child: SvgIcon(
                                        right
                                            ? SvgIcons.arrowRight
                                            : SvgIcons.arrowRightDisabled,
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
                opacity: (_displayClose || _showControls) ? 1 : 0,
                child: GalleryButton(
                  onPressed: _dismiss,
                  icon: SvgIcons.close,
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
                  opacity: (_displayFullscreen || _showControls) ? 1 : 0,
                  child: GalleryButton(
                    onPressed: _toggleFullscreen,
                    icon: _isFullscreen.value
                        ? SvgIcons.fullscreenExit
                        : SvgIcons.fullscreenEnter,
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
                onEnter: (d) => setState(() => _displayFullscreen = true),
                onExit: (d) => setState(() => _displayFullscreen = false),
                child: const SizedBox(width: 100, height: 100),
              ),
              Expanded(
                child: MouseRegion(
                  opaque: false,
                  onEnter: (d) => setState(() => _displayLeft = true),
                  onExit: (d) => setState(() => _displayLeft = false),
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
                onEnter: (d) => setState(() => _displayClose = true),
                onExit: (d) => setState(() => _displayClose = false),
                child: const SizedBox(width: 100, height: 100),
              ),
              Expanded(
                child: MouseRegion(
                  opaque: false,
                  onEnter: (d) => setState(() => _displayRight = true),
                  onExit: (d) => setState(() => _displayRight = false),
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
                child: GalleryButton(
                  onPressed: () {
                    widget.onTrashPressed?.call(_page);
                    _dismiss();
                  },
                  icon: SvgIcons.deleteBig,
                ),
              ),
            ),
          ),
        ),
    ]);

    return widgets;
  }

  /// Animates the [_pageController] to the provided [page].
  void _animateToPage(int page) {
    _node.requestFocus();
    _pageController.animateToPage(
      page,
      curve: Curves.linear,
      duration: const Duration(milliseconds: 200),
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
          _animateToPage(_page + 1);
        }
      } else if (k.physicalKey == PhysicalKeyboardKey.arrowLeft) {
        if (_page > 0) {
          _animateToPage(_page - 1);
        }
      } else if (k.physicalKey == PhysicalKeyboardKey.escape) {
        _dismiss();
      } else if (k.physicalKey == PhysicalKeyboardKey.space) {
        _videoControllers.forEach((_, v) => v.player.playOrPause());
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
          _animateToPage(_page - 1);
        } else if (s.scrollDelta.dy < 0 && _page < widget.children.length - 1) {
          _resetSnappingTimer();
          _animateToPage(_page + 1);
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
  Future<void> _download(GalleryItem item, {String? to}) async {
    try {
      try {
        await CacheWorker.instance
            .download(
              item.link,
              item.name,
              item.size,
              checksum: item.checksum,
              to: to,
            )
            .future;
      } catch (_) {
        if (item.onError != null) {
          await item.onError?.call();
          return SchedulerBinding.instance.addPostFrameCallback((_) {
            item = widget.children[_page];
            _download(item, to: to);
          });
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
      rethrow;
    }
  }

  /// Downloads the provided [GalleryItem] using `save as` dialog.
  Future<void> _downloadAs(GalleryItem item) async {
    try {
      String? to = await FilePicker.platform.saveFile(
        fileName: item.name,
        type: item.isVideo ? FileType.video : FileType.image,
        lockParentWindow: true,
      );

      if (to != null) {
        _download(item, to: to);
      }
    } catch (_) {
      MessagePopup.error('err_could_not_download'.l10n);
      rethrow;
    }
  }

  /// Downloads the provided [GalleryItem] and saves it to the gallery.
  Future<void> _saveToGallery(GalleryItem item) async {
    // Tries downloading the [item].
    Future<void> download() async {
      await PlatformUtils.saveToGallery(
        item.link,
        item.name,
        checksum: item.checksum,
        size: item.size,
        isImage: !item.isVideo,
      );

      if (mounted) {
        MessagePopup.success(item.isVideo
            ? 'label_video_saved_to_gallery'.l10n
            : 'label_image_saved_to_gallery'.l10n);
      }
    }

    try {
      try {
        await download();
      } on DioException catch (e) {
        if (item.onError != null && e.response?.statusCode == 403) {
          await item.onError?.call();
          await Future.delayed(Duration.zero);
          await download();
        } else {
          rethrow;
        }
      }
    } on UnsupportedError catch (_) {
      MessagePopup.error('err_unsupported_format'.l10n);
    } catch (_) {
      MessagePopup.error('err_could_not_download'.l10n);
      rethrow;
    }
  }

  /// Downloads the provided [GalleryItem] and opens a share dialog with it.
  Future<void> _share(GalleryItem item) async {
    try {
      try {
        await PlatformUtils.share(
          item.link,
          item.name,
          checksum: item.checksum,
        );
      } catch (_) {
        if (item.onError != null) {
          await item.onError?.call();
          await PlatformUtils.share(
            item.link,
            item.name,
            checksum: item.checksum,
          );
        } else {
          rethrow;
        }
      }
    } catch (_) {
      MessagePopup.error('err_could_not_download'.l10n);
      rethrow;
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

  /// Animates the [_photoController] to the provided [scale] by starting the
  /// [_photo] animation.
  void _animatePhotoScaleTo(double scale) {
    _photoScale = scale;
    _photo
      ..reset()
      ..forward();
  }

  /// Invokes [_dismiss].
  ///
  /// Intended to be used as a [BackButtonInterceptor] callback, thus returns
  /// `true`, if back button should be intercepted, or otherwise returns
  /// `false`.
  bool _onBack(bool _, RouteInfo __) {
    _dismiss();
    return true;
  }

  /// Sets the [_displayTimer] to [toggle] the provided boolean.
  void _displayForTime(void Function(bool) toggle) {
    toggle(true);

    _displayTimer?.cancel();
    _displayTimer = Timer(1.seconds, () {
      if (mounted) {
        setState(() => toggle(false));
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
