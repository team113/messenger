import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class RetryImage extends StatefulWidget {
  const RetryImage(
    this.url, {
    this.error403,
    this.fit,
    this.width,
    this.height,
    Key? key,
  }) : super(key: key);

  /// Url address of image.
  final String url;

  /// Callback called when url loading was failed with error code 403.
  final VoidCallback? error403;

  /// BoxFit of image.
  final BoxFit? fit;

  /// Width of image.
  final double? width;

  /// Height of image.
  final double? height;

  @override
  State<RetryImage> createState() => _RetryImageState();
}

class _RetryImageState extends State<RetryImage> {
  ///
  Timer? _timer;

  bool _loaded = false;
  late Uint8List _image;
  bool error403WasCalled = false;

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
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        )
      : Center(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 50, maxWidth: 50),
            child: const AspectRatio(
              aspectRatio: 1 / 1,
              child: CircularProgressIndicator(),
            ),
          ),
        );

  Future<void> _loadImage() async {
    http.Response? data;
    try {
      data = await http.get(Uri.parse(widget.url));
    } catch (e) {
      print(e);
    }
    if (data?.statusCode == 403 && error403WasCalled == false) {
      error403WasCalled = true;
      widget.error403?.call();
      if (mounted) {
        setState(() {});
      }
    }
    if (data?.bodyBytes != null && data!.statusCode == 200) {
      _loaded = true;
      _image = data.bodyBytes;
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
