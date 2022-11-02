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

import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// [Image.memory] displaying an image fetched from the provided [url].
///
/// Uses exponential backoff algorithm to re-fetch the [url] in case an error
/// occurs.
///
/// Invokes the provided [onForbidden] callback on the `403 Forbidden` HTTP
/// errors.
class RetryImage extends StatefulWidget {
  const RetryImage(
    this.url, {
    Key? key,
    this.fit,
    this.height,
    this.width,
    this.loaderPadding,
    this.loaderStrokeWidth,
    this.onForbidden,
    this.imageFilter,
  }) : super(key: key);

  /// URL of an image to display.
  final String url;

  /// Callback, called when loading an image from the provided [url] failed with
  /// a forbidden network error.
  final Future<void> Function()? onForbidden;

  /// [BoxFit] to apply to the fetched image.
  final BoxFit? fit;

  /// Height of the fetched image.
  final double? height;

  /// Width of the fetched image.
  final double? width;

  /// [Padding] of loader.
  final EdgeInsetsGeometry? loaderPadding;

  /// Loader stroke width.
  final double? loaderStrokeWidth;

  /// [ImageFilter] of image.
  final ImageFilter? imageFilter;

  @override
  State<RetryImage> createState() => _RetryImageState();
}

/// [State] of [RetryImage] maintaining image data loading with the exponential
/// backoff algorithm.
class _RetryImageState extends State<RetryImage> {
  /// [Timer] retrying the image fetching.
  Timer? _timer;

  /// Byte data of the fetched image.
  Uint8List? _image;

  /// Image fetching progress.
  double _progress = 0;

  /// [Duration] of the [_timer].
  Duration _backoffTimeout = const Duration(microseconds: 250);

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
  Widget build(BuildContext context) {
    if (_image != null) {
      return (widget.imageFilter == null)
          ? Image.memory(
              _image!,
              key: const Key('RetryImageLoaded'),
              height: widget.height,
              width: widget.width,
              fit: widget.fit,
            )
          : ImageFiltered(
              imageFilter: widget.imageFilter!,
              child: Image.memory(
                _image!,
                key: const Key('RetryImageLoaded'),
                height: widget.height,
                width: widget.width,
                fit: widget.fit,
              ),
            );
    }

    return Container(
      height: widget.height,
      width: 200,
      alignment: Alignment.center,
      child: Container(
        padding: widget.loaderPadding,
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
            strokeWidth: widget.loaderStrokeWidth ?? 4,
            value: _progress == 0 ? null : _progress,
          ),
        ),
      ),
    );
  }

  /// Loads image using the exponential backoff algorithm.
  Future<void> _loadImage() async {
    Response? data;

    try {
      data = await Dio().get(
        widget.url,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _progress = received / total;
            if (mounted) {
              setState(() {});
            }
          }
        },
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioError catch (e) {
      if (e.response?.statusCode == 403) {
        await widget.onForbidden?.call();
      }
    }

    if (data?.data != null && data?.statusCode == 200) {
      _image = data?.data;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _timer = Timer(
      _backoffTimeout,
      () {
        if (_backoffTimeout < const Duration(seconds: 32)) {
          _backoffTimeout *= 2;
        }

        _loadImage();
      },
    );
  }
}
