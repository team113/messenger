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

import '/util/platform_utils.dart';

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
    this.borderRadius,
    this.onForbidden,
    this.filter,
  }) : super(key: key);

  /// URL of an image to display.
  final String url;

  /// Callback, called when loading an image from the provided [url] fails with
  /// a forbidden network error.
  final Future<void> Function()? onForbidden;

  /// [BoxFit] to apply to this [RetryImage].
  final BoxFit? fit;

  /// Height of this [RetryImage].
  final double? height;

  /// Width of this [RetryImage].
  final double? width;

  /// [ImageFilter] to apply to this [RetryImage].
  final ImageFilter? filter;

  /// [BorderRadius] to apply to this [RetryImage].
  final BorderRadius? borderRadius;

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

  /// Starting period of exponential backoff image fetching.
  static const Duration _minBackoffPeriod = Duration(microseconds: 250);

  /// Maximum possible period of exponential backoff image fetching.
  static const Duration _maxBackoffPeriod = Duration(seconds: 32);

  /// Current period of exponential backoff image fetching.
  Duration _backoffPeriod = _minBackoffPeriod;

  @override
  void initState() {
    _loadImage();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant RetryImage oldWidget) {
    if (oldWidget.url != widget.url) {
      _loadImage();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;

    if (_image != null) {
      Widget image = Image.memory(
        _image!,
        key: const Key('Loaded'),
        height: widget.height,
        width: widget.width,
        fit: widget.fit,
      );

      if (widget.filter != null) {
        image = ImageFiltered(
          imageFilter: widget.filter!,
          child: image,
        );
      }

      if (widget.borderRadius != null) {
        image = ClipRRect(
          borderRadius: widget.borderRadius!,
          child: image,
        );
      }

      child = image;
    } else {
      child = Container(
        key: const Key('Loading'),
        height: widget.height,
        width: 200,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(5),
          constraints: const BoxConstraints(
            maxHeight: 40,
            maxWidth: 40,
            minWidth: 10,
            minHeight: 10,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: CircularProgressIndicator(
              value: _progress == 0 ? null : _progress,
            ),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      key: Key('Image_${widget.url}'),
      duration: const Duration(milliseconds: 150),
      child: child,
    );
  }

  /// Loads the [_image] from the provided URL.
  ///
  /// Retries itself using exponential backoff algorithm on a failure.
  Future<void> _loadImage() async {
    _timer?.cancel();
    Response? data;

    try {
      data = await PlatformUtils.dio.get(
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
      _image = data!.data;
      _backoffPeriod = _minBackoffPeriod;
      if (mounted) {
        setState(() {});
      }
    } else {
      _timer = Timer(
        _backoffPeriod,
        () {
          if (_backoffPeriod < _maxBackoffPeriod) {
            _backoffPeriod *= 2;
          }

          _loadImage();
        },
      );
    }
  }
}
