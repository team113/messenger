import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget that trying to load image and display it.
class RetryImage extends StatefulWidget {
  const RetryImage(
    this.url, {
    this.error403,
    this.fit,
    this.height,
    Key? key,
  }) : super(key: key);

  /// Url address of image.
  final String url;

  /// Callback called when url loading was failed with error code 403.
  final VoidCallback? error403;

  /// BoxFit of image.
  final BoxFit? fit;

  /// Height of image.
  final double? height;

  @override
  State<RetryImage> createState() => _RetryImageState();
}

/// [State] of [RetryImage].
class _RetryImageState extends State<RetryImage> {
  /// [Timer] of backOff loading image.
  Timer? _timer;

  /// Indicator whether image was loaded or not.
  bool _loaded = false;

  /// [Uint8List] image bytes.
  late Uint8List _image;

  /// Image download progress.
  double _progress = 0;

  /// Duration of backOff loading image.
  int _reconnectPeriodMillis = 500 ~/ 2;

  @override
  void initState() {
    _loadImage();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _loaded
      ? Image.memory(
          _image,
          height: widget.height,
          fit: widget.fit,
          key: const Key('RetryImageLoaded'),
        )
      : Container(
          height: widget.height,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 40,
              maxWidth: 40,
              minWidth: 10,
              minHeight: 10,
            ),
            child: AspectRatio(
              aspectRatio: 1 / 1,
              child: CircularProgressIndicator(
                key: const Key('RetryImageLoading'),
                value: _progress,
              ),
            ),
          ),
        );

  /// Trying to load image.
  Future<void> _loadImage() async {
    Response? data;

    try {
      data = await Dio().get(
        widget.url,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _progress = received / total;
            setState(() {});
          }
        },
        options: Options(responseType: ResponseType.bytes),
      );
    } catch (e) {
      // No-op.
    }

    if (data?.statusCode == 403) {
      widget.error403?.call();
    }

    if (data?.data != null && data!.statusCode == 200) {
      _loaded = true;
      _image = data.data;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _timer = Timer(Duration(milliseconds: _reconnectPeriodMillis), () {
      if (_reconnectPeriodMillis < 32000) {
        _reconnectPeriodMillis *= 2;
      }
      _loadImage();
    });
  }
}
