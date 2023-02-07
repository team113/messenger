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
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/util/backoff.dart';
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
    this.checksum,
    this.fit,
    this.height,
    this.width,
    this.borderRadius,
    this.onForbidden,
    this.filter,
  }) : super(key: key);

  /// URL of an image to display.
  final String url;

  /// SHA-256 checksum of the image to display.
  final String? checksum;

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
  /// Byte data of the fetched image.
  Uint8List? _image;

  /// Image fetching progress.
  double _progress = 0;

  /// [CancelToken] canceling the [_loadImage] operation.
  final CancelToken _cancelToken = CancelToken();

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
    _cancelToken.cancel();
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
        image = ImageFiltered(imageFilter: widget.filter!, child: image);
      }

      if (widget.borderRadius != null) {
        image = ClipRRect(borderRadius: widget.borderRadius!, child: image);
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
              value: _progress == 0 ? null : _progress.clamp(0, 1),
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
    return Backoff.run(
      () async {
        Uint8List? cached;
        if (widget.checksum != null) {
          cached = FIFOCache.get(widget.checksum!);
        }

        if (cached != null) {
          _image = cached;
          if (mounted) {
            setState(() {});
          }
        } else {
          Response? data;

          try {
            data = await PlatformUtils.dio.get(
              widget.url,
              onReceiveProgress: (received, total) {
                if (total > 0) {
                  _progress = received / total;
                  if (mounted) {
                    setState(() {});
                  }
                }
              },
              options: Options(responseType: ResponseType.bytes),
              cancelToken: _cancelToken,
            );
          } on DioError catch (e) {
            if (e.response?.statusCode == 403) {
              await widget.onForbidden?.call();
            }
          }

          if (data?.data != null && data!.statusCode == 200) {
            if (widget.checksum != null) {
              FIFOCache.set(widget.checksum!, data.data);
            }

            _image = data.data;
            if (mounted) {
              setState(() {});
            }
          } else {
            throw Exception('Image is not loaded');
          }
        }
      },
      _cancelToken,
    );
  }
}

/// Naive [LinkedHashMap]-based cache of [Uint8List]s.
///
/// FIFO policy is used, meaning if [_cache] exceeds its [_maxSize] or
/// [_maxLength], then the first inserted element is removed.
class FIFOCache {
  /// Maximum allowed length of [_cache].
  static const int _maxLength = 1000;

  /// Maximum allowed size in bytes of [_cache].
  static const int _maxSize = 100 << 20; // 100 MiB

  /// [LinkedHashMap] maintaining [Uint8List]s itself.
  static final LinkedHashMap<String, Uint8List> _cache =
      LinkedHashMap<String, Uint8List>();

  /// Returns the total size [_cache] occupies.
  static int get size =>
      _cache.values.map((e) => e.lengthInBytes).fold<int>(0, (p, e) => p + e);

  /// Puts the provided [bytes] to the cache.
  static void set(String key, Uint8List bytes) {
    if (!_cache.containsKey(key)) {
      while (size >= _maxSize) {
        _cache.remove(_cache.keys.first);
      }

      if (_cache.length >= _maxLength) {
        _cache.remove(_cache.keys.first);
      }

      _cache[key] = bytes;
    }
  }

  /// Returns the [Uint8List] of the provided [key], if any is cached.
  static Uint8List? get(String key) => _cache[key];

  /// Indicates whether an item with the provided [key] exists.
  static bool exists(String key) => _cache.containsKey(key);
}
