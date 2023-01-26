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
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';

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
    super.key,
    this.fallback,
    this.fit,
    this.height,
    this.width,
    this.borderRadius,
    this.onForbidden,
    this.filter,
    this.cancelable = false,
    this.load = true,
  });

  /// URL of an image to display.
  final String url;

  final String? fallback;

  /// Callback, called when loading an image from the provided [url] fails with
  /// a forbidden network error.
  final Future<void> Function()? onForbidden;

  /// [BoxFit] to apply to this [RetryImage].
  final BoxFit? fit;

  /// Width of this [RetryImage].
  final double? width;

  /// Height of this [RetryImage].
  final double? height;

  /// [ImageFilter] to apply to this [RetryImage].
  final ImageFilter? filter;

  /// [BorderRadius] to apply to this [RetryImage].
  final BorderRadius? borderRadius;

  final bool cancelable;
  final bool load;

  @override
  State<RetryImage> createState() => _RetryImageState();
}

/// [State] of [RetryImage] maintaining image data loading with the exponential
/// backoff algorithm.
class _RetryImageState extends State<RetryImage> {
  /// Naive [_FIFOCache] caching the images.
  static final _FIFOCache _cache = _FIFOCache();

  /// [Timer] retrying the image fetching.
  Timer? _timer;
  Timer? _fallbackTimer;

  /// Byte data of the fetched image.
  Uint8List? _image;
  Uint8List? _fallback;

  /// Image fetching progress.
  double _progress = 0;

  /// Starting period of exponential backoff image fetching.
  static const Duration _minBackoffPeriod = Duration(microseconds: 500);

  /// Maximum possible period of exponential backoff image fetching.
  static const Duration _maxBackoffPeriod = Duration(seconds: 32);

  /// Current period of exponential backoff image fetching.
  Duration _backoffPeriod = _minBackoffPeriod;
  Duration _fallbackPeriod = _minBackoffPeriod;

  bool _canceled = false;
  CancelToken? _token;

  @override
  void initState() {
    _loadFallback();

    if (widget.load) {
      _loadImage();
    } else {
      _canceled = true;
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant RetryImage oldWidget) {
    if (oldWidget.url != widget.url) {
      _loadFallback();
    }

    if (oldWidget.url != widget.url || (!oldWidget.load && widget.load)) {
      _loadImage();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fallbackTimer?.cancel();
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
      child = WidgetButton(
        onPressed: widget.cancelable
            ? () {
                if (_canceled) {
                  _canceled = false;
                  _token = CancelToken();
                  _loadImage();
                } else {
                  _canceled = true;
                  _token?.cancel();
                }

                setState(() {});
              }
            : null,
        child: Container(
          key: const Key('Loading'),
          height: widget.height,
          // width: 200,
          constraints: const BoxConstraints(minWidth: 200),
          alignment: Alignment.center,
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 40,
              maxWidth: 40,
              minWidth: 10,
              minHeight: 10,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!_canceled)
                  CustomProgressIndicator(
                    padding: const EdgeInsets.all(4),
                    strokeWidth: 2,
                    value: _progress == 0 ? null : _progress.clamp(0, 1),
                  ),
                if (widget.cancelable)
                  Center(
                    child: _canceled
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  blurStyle: BlurStyle.outer,
                                ),
                              ],
                            ),
                            child: SvgLoader.asset(
                              'assets/icons/download.svg',
                              height: 40,
                            ),
                          )
                        : SvgLoader.asset(
                            'assets/icons/close_primary.svg',
                            height: 13,
                          ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.fallback != null && _image == null) {
      return Stack(
        children: [
          if (widget.fallback != null && _image == null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _fallback == null
                  ? SizedBox(
                      width: 200,
                      height: widget.height,
                    )
                  : ClipRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 15,
                          sigmaY: 15,
                          tileMode: TileMode.clamp,
                        ),
                        child: Transform.scale(
                          scale: 1.2,
                          child: Image.memory(
                            _fallback!,
                            key: const Key('Fallback'),
                            height: widget.height,
                            width: widget.width,
                            fit: widget.fit,
                          ),
                        ),
                      ),
                    ),
            ),
          Positioned.fill(
            child: Center(
              child: AnimatedSwitcher(
                key: Key('Image_${widget.url}'),
                duration: const Duration(milliseconds: 150),
                child: child,
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedSwitcher(
      key: Key('Image_${widget.url}'),
      duration: const Duration(milliseconds: 150),
      child: child,
    );
  }

  Future<void> _loadFallback() async {
    if (widget.fallback == null) return;

    _fallbackTimer?.cancel();

    Uint8List? cached = _cache[widget.fallback!];
    if (cached != null) {
      _fallback = cached;
      _fallbackPeriod = _minBackoffPeriod;
      if (mounted) {
        setState(() {});
      }
    } else {
      Response? data;

      try {
        data = await PlatformUtils.dio.get(
          widget.fallback!,
          options: Options(responseType: ResponseType.bytes),
        );
      } on DioError catch (e) {
        if (e.response?.statusCode == 403) {
          await widget.onForbidden?.call();
        }
      }

      if (data?.data != null && data!.statusCode == 200) {
        _cache[widget.fallback!] = data.data;
        _fallback = data.data;
        _fallbackPeriod = _minBackoffPeriod;
        if (mounted) {
          setState(() {});
        }
      } else {
        _fallbackTimer = Timer(
          _fallbackPeriod,
          () {
            if (_fallbackPeriod < _maxBackoffPeriod) {
              _fallbackPeriod *= 2;
            }

            _loadImage();
          },
        );
      }
    }
  }

  /// Loads the [_image] from the provided URL.
  ///
  /// Retries itself using exponential backoff algorithm on a failure.
  Future<void> _loadImage() async {
    _timer?.cancel();

    _token = CancelToken();

    Uint8List? cached = _cache[widget.url];
    if (cached != null) {
      _image = cached;
      _backoffPeriod = _minBackoffPeriod;
      if (mounted) {
        setState(() {});
      }
    } else {
      Response? data;

      try {
        for (int i = 0; i < 100; ++i) {
          await Future.delayed(const Duration(milliseconds: 25));
          _progress = i / 100;
          if (mounted) {
            setState(() {});
          }

          if (_token?.isCancelled == true) {
            return;
          }
        }

        if (_token?.isCancelled == true) {
          return;
        }

        data = await PlatformUtils.dio.get(
          widget.url,
          onReceiveProgress: (received, total) {
            // if (total > 0) {
            //   _progress = received / total;
            //   if (mounted) {
            //     setState(() {});
            //   }
            // }
          },
          cancelToken: _token,
          options: Options(responseType: ResponseType.bytes),
        );
      } on DioError catch (e) {
        if (e.response?.statusCode == 403) {
          await widget.onForbidden?.call();
        }
      }

      if (_token?.isCancelled == true) {
        return;
      }

      if (data?.data != null && data!.statusCode == 200) {
        _cache[widget.url] = data.data;
        _image = data.data;
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
}

/// Naive [LinkedHashMap]-based cache of [Uint8List]s.
///
/// FIFO policy is used, meaning if [_cache] exceeds its [_maxSize] or
/// [_maxLength], then the first inserted element is removed.
class _FIFOCache {
  /// Maximum allowed length of [_cache].
  static const int _maxLength = 1000;

  /// Maximum allowed size in bytes of [_cache].
  static const int _maxSize = 100 << 20; // 100 MiB

  /// [LinkedHashMap] maintaining [Uint8List]s itself.
  final LinkedHashMap<String, Uint8List> _cache =
      LinkedHashMap<String, Uint8List>();

  /// Returns the total size [_cache] occupies.
  int get size =>
      _cache.values.map((e) => e.lengthInBytes).fold<int>(0, (p, e) => p + e);

  /// Puts the provided [bytes] to the cache.
  void operator []=(String key, Uint8List bytes) {
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
  Uint8List? operator [](String key) => _cache[key];
}
