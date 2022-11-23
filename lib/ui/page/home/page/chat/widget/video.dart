// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'desktop_controls.dart';
import 'mobile_controls.dart';
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
  final void Function(VideoPlayerController?)? onController;

  /// Reactive indicator of whether this video is in fullscreen mode.
  final RxBool? isFullscreen;

  /// Callback, called on the [VideoPlayerController] initialization errors.
  final Future<void> Function()? onError;

  /// [Duration] to initially show an user interface for.
  final Duration? showInterfaceFor;

  @override
  State<Video> createState() => _VideoState();
}

/// State of a [Video] used to initialize and dispose video controllers.
class _VideoState extends State<Video> {
  /// [VideoPlayerController] controlling the actual video stream.
  late VideoPlayerController _controller;

  /// [ChewieController] adding extra functionality over the
  /// [VideoPlayerController], used to display a [Chewie] player.
  ChewieController? _chewie;

  /// Indicator whether the [_initVideo] has failed.
  bool _hasError = false;

  @override
  void initState() {
    _initVideo();
    super.initState();
  }

  @override
  void dispose() {
    widget.onController?.call(null);
    _controller.dispose();
    _chewie?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Video oldWidget) {
    if (oldWidget.url != widget.url) {
      _initVideo();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _controller.value.isInitialized
          ? Theme(
              data: ThemeData(platform: TargetPlatform.iOS),
              child: Chewie(controller: _chewie!),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.error, size: 48, color: Colors.red),
                      SizedBox(height: 10),
                      Text(
                        'Video playback is not yet supported\non your operating system',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () {},
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.99,
                      height: MediaQuery.of(context).size.height * 0.6,
                      decoration: BoxDecoration(
                        color: const Color(0x00000000),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
    );
  }

  /// Initializes the [_controller] and [_chewie].
  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.network(widget.url);
      widget.onController?.call(_controller);
      await _controller.initialize();

      _chewie = ChewieController(
        videoPlayerController: _controller,
        autoPlay: true,
        looping: false,
        showOptions: false,
        autoInitialize: true,
        showControlsOnInitialize: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blue,
          bufferedColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(.5),
        ),
        customControls: PlatformUtils.isMobile
            ? const MobileControls()
            : DesktopControls(
                onClose: widget.onClose,
                toggleFullscreen: widget.toggleFullscreen,
                isFullscreen: widget.isFullscreen,
                showInterfaceFor: widget.showInterfaceFor,
              ),
        routePageBuilder: (context, animation, _, provider) {
          return Theme(
            data: ThemeData(platform: TargetPlatform.iOS),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: Container(
                    alignment: Alignment.center,
                    color: Colors.black,
                    child: provider,
                  ),
                );
              },
            ),
          );
        },
      );
    } on PlatformException catch (e) {
      if (e.code == 'MEDIA_ERR_SRC_NOT_SUPPORTED') {
        if (widget.onError != null) {
          await widget.onError?.call();
        } else {
          _hasError = true;
        }
      } else {
        // Plugin is not supported on the current platform.
        _hasError = true;
      }
    }

    setState(() {});
  }
}
