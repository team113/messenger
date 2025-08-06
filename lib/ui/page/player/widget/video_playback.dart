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
import '/ui/widget/progress_indicator.dart';
import '/ui/worker/cache.dart';
import '/util/backoff.dart';
import '/util/platform_utils.dart';

/// Video player with controls.
class VideoPlayback extends StatefulWidget {
  const VideoPlayback(
    this.url, {
    super.key,
    this.checksum,
    this.onController,
    this.onError,
    this.volume,
    this.onVolumeChanged,
    this.loop = false,
  });

  /// URL of the video to display.
  final String url;

  /// SHA-256 checksum of the video to display.
  final String? checksum;

  /// Callback, called when a [VideoController] is assigned or disposed.
  final void Function(VideoController?)? onController;

  /// Callback, called on the [VideoController] initialization errors.
  final FutureOr<void> Function()? onError;

  final double? volume;
  final void Function(double)? onVolumeChanged;
  final bool loop;

  @override
  State<VideoPlayback> createState() => _VideoPlaybackState();
}

/// State of a [VideoPlayback] used to initialize and dispose video controller.
class _VideoPlaybackState extends State<VideoPlayback> {
  /// [Timer] for displaying the loading animation when non-`null`.
  Timer? _loading;

  /// [CancelToken] for cancelling the [VideoView.url] header fetching.
  CancelToken? _cancelToken;

  /// [VideoController] to display the first frame of the video.
  final VideoController _controller = VideoController(Player());

  StreamSubscription? _volumeSubscription;

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
    _volumeSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoPlayback oldWidget) {
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

    return StreamBuilder(
      stream: _controller.player.stream.width,
      builder: (_, __) {
        if (_controller.player.state.width != null) {
          return LayoutBuilder(
            builder: (_, constraints) {
              Size? size = _controller.rect.value?.size;

              final double maxHeight = constraints.maxHeight;
              final double maxWidth = constraints.maxWidth;

              if (size != null) {
                final double ratio = min(
                  maxHeight / size.height,
                  maxWidth / size.width,
                );

                size *= ratio;
              }

              return SizedBox.fromSize(
                size: size?.isFinite == true ? size : null,
                child: Video(
                  controller: _controller,
                  controls: (_) => const SizedBox(),
                  fill: style.colors.transparent,
                ),
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
                child: _loading != null
                    ? const SizedBox()
                    : const Center(child: CustomProgressIndicator()),
              ),
            ),
          );
        }
      },
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

    _volumeSubscription?.cancel();
    _volumeSubscription = _controller.player.stream.volume.listen((e) {
      widget.onVolumeChanged?.call(e);
    });

    try {
      if (file != null) {
        await _controller.player.open(Media(file.path));
      } else if (bytes != null) {
        await _controller.player.open(await Media.memory(bytes));
      } else {
        await _controller.player.open(Media(widget.url));
      }

      if (widget.volume != null) {
        await _controller.player.setVolume(widget.volume!);
      }

      if (widget.loop) {
        await _controller.player.setPlaylistMode(PlaylistMode.loop);
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
      }, cancel: _cancelToken);
    } on OperationCanceledException {
      // No-op.
    }
  }
}
