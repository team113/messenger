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

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';
import 'package:get/get.dart';
import 'package:messenger/util/backoff.dart';

import 'desktop_controls.dart';
import 'mobile_controls.dart';
import '/themes.dart';
import '/ui/widget/progress_indicator.dart';
import '/util/platform_utils.dart';

/// Video player with controls.
class Video extends StatefulWidget {
  const Video(
    this.url, {
    Key? key,
    this.onClose,
    this.toggleFullscreen,
    this.onController,
    this.isFullscreen,
    this.onError,
    this.showInterfaceFor,
  }) : super(key: key);

  /// URL of the video to display.
  final String url;

  /// Callback, called when a close video action is fired.
  final VoidCallback? onClose;

  /// Callback, called when a toggle fullscreen action is fired.
  final VoidCallback? toggleFullscreen;

  /// Callback, called when a [VideoPlayerController] is assigned or disposed.
  final void Function(MeeduPlayerController?)? onController;

  /// Reactive indicator of whether this video is in fullscreen mode.
  final RxBool? isFullscreen;

  /// Callback, called on the [VideoPlayerController] initialization errors.
  final Future<void> Function()? onError;

  /// [Duration] to initially show an user interface for.
  final Duration? showInterfaceFor;

  @override
  State<Video> createState() => _VideoState();
}

/// State of a [Video] used to initialize and dispose video controller.
class _VideoState extends State<Video> {
  /// [Timer] for displaying the loading animation when non-`null`.
  Timer? _loading;

  final MeeduPlayerController _controller = MeeduPlayerController(
    controlsStyle: ControlsStyle.custom,
    fits: [BoxFit.contain],
    enabledOverlays: const EnabledOverlays(volume: false, brightness: false),
    loadingWidget: const SizedBox(),
    showLogs: kDebugMode,
  );

  @override
  void initState() {
    _controller.videoFit.value = BoxFit.contain;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initVideo();
    });
    _loading = Timer(1.seconds, () => setState(() => _loading = null));

    bool shouldReload = false;
    Backoff.run(() async {
      try {
        await PlatformUtils.dio.head(widget.url);
        if (shouldReload) {
          _initVideo();
        }
      } catch (e) {
        if (e is DioError && e.response?.statusCode == 403) {
          widget.onError?.call();
        } else {
          shouldReload = true;
          rethrow;
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    widget.onController?.call(null);
    _loading?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Video oldWidget) {
    if (oldWidget.url != widget.url) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initVideo();
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<Style>()!;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: RxBuilder((_) {
        return _controller.dataStatus.loaded
            ? Stack(
                children: [
                  MeeduVideoPlayer(
                    controller: _controller,
                    customControls: (_, __, ___) => const SizedBox(),
                  ),
                  PlatformUtils.isMobile
                      ? MobileControls(controller: _controller)
                      : DesktopControls(
                          controller: _controller,
                          onClose: widget.onClose,
                          toggleFullscreen: widget.toggleFullscreen,
                          isFullscreen: widget.isFullscreen,
                          showInterfaceFor: widget.showInterfaceFor,
                        ),
                ],
              )
            : _controller.dataStatus.error
                ? Center(
                    key: const Key('Error'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error,
                          size: 48,
                          color: style.colors.dangerColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'An error occurred',
                          style: TextStyle(color: style.colors.onPrimary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    key: Key(_loading == null ? 'Loading' : 'Box'),
                    onTap: () {},
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.99,
                        height: MediaQuery.of(context).size.height * 0.6,
                        decoration: BoxDecoration(
                          color: style.colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _loading != null
                            ? const SizedBox()
                            : const Center(child: CustomProgressIndicator()),
                      ),
                    ),
                  );
      }),
    );
  }

  /// Initializes the [_controller].
  Future<void> _initVideo() async {
    _controller.setDataSource(
      DataSource(type: DataSourceType.network, source: widget.url),
      autoplay: true,
      looping: false,
    );
    widget.onController?.call(_controller);
  }
}
