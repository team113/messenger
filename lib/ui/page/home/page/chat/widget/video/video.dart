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
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '/themes.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/worker/cache.dart';
import '/util/backoff.dart';
import '/util/platform_utils.dart';
import 'widget/desktop_controls.dart';
import 'widget/mobile_controls.dart';

/// Video player with controls.
class VideoView extends StatefulWidget {
  const VideoView(
    this.url, {
    super.key,
    this.checksum,
    this.onClose,
    this.toggleFullscreen,
    this.onController,
    this.isFullscreen,
    this.onError,
    this.showInterfaceFor,
  });

  /// URL of the video to display.
  final String url;

  /// SHA-256 checksum of the video to display.
  final String? checksum;

  /// Callback, called when a close video action is fired.
  final VoidCallback? onClose;

  /// Callback, called when a toggle fullscreen action is fired.
  final VoidCallback? toggleFullscreen;

  /// Callback, called when a [VideoController] is assigned or disposed.
  final void Function(VideoController?)? onController;

  /// Reactive indicator whether this video is in fullscreen mode.
  final RxBool? isFullscreen;

  /// Callback, called on the [VideoController] initialization errors.
  final FutureOr<void> Function()? onError;

  /// [Duration] to initially show an user interface for.
  final Duration? showInterfaceFor;

  @override
  State<VideoView> createState() => _VideoViewState();
}

/// State of a [VideoView] used to initialize and dispose video controller.
class _VideoViewState extends State<VideoView> {
  /// Height of the bottom controls bar.
  final _barHeight = 48.0 * 1.5;

  /// [Timer] for displaying the loading animation when non-`null`.
  Timer? _loading;

  /// [CancelToken] for cancelling the [VideoView.url] header fetching.
  CancelToken? _cancelToken;

  /// [VideoController] to display the first frame of the video.
  final VideoController _controller = VideoController(Player());

  @override
  void initState() {
    widget.onController?.call(_controller);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initVideo();
    });

    _loading = Timer(1.seconds, () => setState(() => _loading = null));

    super.initState();
  }

  @override
  void dispose() {
    widget.onController?.call(null);
    _loading?.cancel();
    _controller.player.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoView oldWidget) {
    if (oldWidget.url != widget.url) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _initVideo();
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return SafeAnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: StreamBuilder(
        stream: _controller.player.stream.width,
        builder: (_, __) {
          if (_controller.player.state.width != null) {
            return LayoutBuilder(
              builder: (_, constraints) {
                Size? size = _controller.rect.value?.size;

                final double maxHeight = constraints.maxHeight;
                final double maxWidth = constraints.maxWidth;

                if (size != null &&
                    (maxHeight < size.height ||
                        maxWidth < size.width ||
                        widget.isFullscreen?.value == true)) {
                  final double ratio = min(
                    maxHeight / size.height,
                    maxWidth / size.width,
                  );
                  size *= ratio;
                }

                return Stack(
                  children: [
                    Center(
                      child: SizedBox.fromSize(
                        size: size,
                        child: Video(
                          controller: _controller,
                          controls: (_) => const SizedBox(),
                          fill: style.colors.transparent,
                        ),
                      ),
                    ),
                    PlatformUtils.isMobile
                        ? MobileControls(_controller, barHeight: _barHeight)
                        : DesktopControls(
                          _controller,
                          barHeight: _barHeight,
                          onClose: widget.onClose,
                          toggleFullscreen: widget.toggleFullscreen,
                          isFullscreen: widget.isFullscreen,
                          showInterfaceFor: widget.showInterfaceFor,
                          size: size,
                        ),
                  ],
                );
              },
            );
          } else {
            return GestureDetector(
              key: Key(_loading != null ? 'Box' : 'Loading'),
              onTap: () {
                // Intercept `onTap` event to prevent [GalleryPopup]
                // closing.
              },
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.99,
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    color: style.colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      _loading != null
                          ? const SizedBox()
                          : const Center(child: CustomProgressIndicator()),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  /// Initializes the [_controller].
  Future<void> _initVideo() async {
    Uint8List? bytes;
    File? file;

    if (widget.checksum != null &&
        CacheWorker.instance.exists(widget.checksum!)) {
      CacheEntry cache = await CacheWorker.instance.get(
        checksum: widget.checksum!,
        responseType: CacheResponseType.file,
      );

      bytes = cache.bytes;
      file = cache.file;
    }

    try {
      if (file != null) {
        await _controller.player.open(Media(file.path));
      } else if (bytes != null) {
        await _controller.player.open(await Media.memory(bytes));
      } else {
        await _controller.player.open(Media(widget.url));
      }
    } catch (_) {
      // No-op.
    }

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    bool shouldReload = false;

    try {
      await Backoff.run(() async {
        try {
          await (await PlatformUtils.dio).head(widget.url);
          if (shouldReload) {
            // Reinitialize the [_controller] if an unexpected error was thrown.
            await _controller.player.open(Media(widget.url));
          }
        } catch (e) {
          if (e is DioException && e.response?.statusCode == 403) {
            widget.onError?.call();
          } else {
            shouldReload = true;
            rethrow;
          }
        }
      }, _cancelToken);
    } on OperationCanceledException {
      // No-op.
    }
  }
}
