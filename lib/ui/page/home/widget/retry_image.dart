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
import 'dart:io';
import 'dart:ui' as ui;

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
  final ui.ImageFilter? filter;

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
  List<int>? _image;

  /// Image fetching progress.
  double _progress = 0;

  ImageProvider? imageProvider;

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
        Uint8List.fromList(_image!),
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

    NetworkImage networkImage = NetworkImage(widget.url);
    var networkImageStatus = await networkImage.obtainCacheStatus(
        configuration: ImageConfiguration.empty);
    if (networkImageStatus?.keepAlive == true) {
      ImageStream stream = networkImage.resolve(ImageConfiguration.empty);
      stream.addListener(ImageStreamListener((image, bool2) async {
        var byte = await image.image.toByteData(format: ui.ImageByteFormat.png);

        if (byte != null) {
          if (_image == null) {
            _image = byte.buffer.asUint8List().toList();
          } else {
            _image!.addAll(byte.buffer.asUint8List().toList());
          }
        }
        if (mounted) setState(() {});
      }));
    } else {
      try {
        StreamController<ImageChunkEvent> chunkEvents = StreamController();
        print(await networkImage.obtainCacheStatus(
            configuration: ImageConfiguration.empty));
        await networkImage.loadAsync(networkImage, chunkEvents, null, (_,
            {int? cacheWidth,
            int? cacheHeight,
            bool allowUpscaling = false}) async {
          return ui.instantiateImageCodec(_);
        });
        if (mounted) precacheImage(networkImage, context);
        print(await networkImage.obtainCacheStatus(
            configuration: ImageConfiguration.empty));
        // data = await PlatformUtils.dio.get(
        //   widget.url,
        //   onReceiveProgress: (received, total) {
        //     if (total != -1) {
        //       _progress = received / total;
        //       if (mounted) {
        //         setState(() {});
        //       }
        //     }
        //   },
        //   options: Options(responseType: ResponseType.bytes),
        // );
      } on DioError catch (e) {
        if (e.response?.statusCode == 403) {
          await widget.onForbidden?.call();
        }
      } on NetworkImageLoadException catch (e) {
        await widget.onForbidden?.call();
      }

      if (data?.data != null && data?.statusCode == 200) {
        var ll = NetworkImage(widget.url);
        ImageStream stream = ll.resolve(ImageConfiguration.empty);
        stream.addListener(ImageStreamListener((image, bool2) async {
          var byte =
              await image.image.toByteData(format: ui.ImageByteFormat.png);

          if (byte != null) {
            _image = byte.buffer.asUint8List();
          }
          if (mounted) setState(() {});
        }));

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

class MyClass2 extends ImageProvider<MyClass2> {
  MyClass2(this.url, {this.scale = 1.0, this.headers});

  final String url;

  final double scale;

  final Map<String, String>? headers;

  ui.Codec? codec;

  @override
  Future<MyClass2> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter load(MyClass2 key, DecoderCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, null, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<MyClass2>('Image key', key),
      ],
    );
  }

  @override
  ImageStreamCompleter loadBuffer(MyClass2 key, DecoderBufferCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode, null),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<MyClass2>('Image key', key),
      ],
    );
  }

  // Do not access this field directly; use [_httpClient] instead.
  // We set `autoUncompress` to false to ensure that we can trust the value of
  // the `Content-Length` HTTP header. We automatically uncompress the content
  // in our call to [consolidateHttpClientResponseBytes].
  static final HttpClient _sharedHttpClient = HttpClient()
    ..autoUncompress = false;

  static HttpClient get _httpClient {
    HttpClient client = _sharedHttpClient;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null) {
        client = debugNetworkImageHttpClientProvider!();
      }
      return true;
    }());
    return client;
  }

  Future<ui.Codec> _loadAsync(
    MyClass2 key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderBufferCallback? decode,
    DecoderCallback? decodeDepreacted,
  ) async {
    try {
      assert(key == this);

      final Uri resolved = Uri.base.resolve(key.url);

      final HttpClientRequest request = await _httpClient.getUrl(resolved);

      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        // The network may be only temporarily unavailable, or the file will be
        // added on the server later. Avoid having future calls to resolve
        // fail to check the network again.
        await response.drain<List<int>>(<int>[]);
        throw NetworkImageLoadException(
            statusCode: response.statusCode, uri: resolved);
      }

      final Uint8List bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: (int cumulative, int? total) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: cumulative,
            expectedTotalBytes: total,
          ));
        },
      );
      if (bytes.lengthInBytes == 0) {
        throw Exception('NetworkImage is an empty file: $resolved');
      }

      codec = await ui.instantiateImageCodec(bytes);
      if (decode != null) {
        final ui.ImmutableBuffer buffer =
            await ui.ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      } else {
        assert(decodeDepreacted != null);
        return decodeDepreacted!(bytes);
      }
    } catch (e) {
      // Depending on where the exception was thrown, the image cache may not
      // have had a chance to track the key in the cache at all.
      // Schedule a microtask to give the cache a chance to add the key.
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      chunkEvents.close();
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MyClass2 && other.url == url && other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'MyClass2')}("$url", scale: $scale)';
}

extension Test on NetworkImage {
  // Do not access this field directly; use [_httpClient] instead.
  // We set `autoUncompress` to false to ensure that we can trust the value of
  // the `Content-Length` HTTP header. We automatically uncompress the content
  // in our call to [consolidateHttpClientResponseBytes].
  static final HttpClient _sharedHttpClient = HttpClient()
    ..autoUncompress = false;

  static HttpClient get _httpClient {
    HttpClient client = _sharedHttpClient;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null) {
        client = debugNetworkImageHttpClientProvider!();
      }
      return true;
    }());
    return client;
  }

  Future<ui.Codec> loadAsync(
    NetworkImage key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderBufferCallback? decode,
    DecoderCallback? decodeDepreacted,
  ) async {
    try {
      assert(key == this);

      final Uri resolved = Uri.base.resolve(key.url);

      final HttpClientRequest request = await _httpClient.getUrl(resolved);

      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        // The network may be only temporarily unavailable, or the file will be
        // added on the server later. Avoid having future calls to resolve
        // fail to check the network again.
        await response.drain<List<int>>(<int>[]);
        throw NetworkImageLoadException(
            statusCode: response.statusCode, uri: resolved);
      }

      final Uint8List bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: (int cumulative, int? total) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: cumulative,
            expectedTotalBytes: total,
          ));
        },
      );
      if (bytes.lengthInBytes == 0) {
        throw Exception('NetworkImage is an empty file: $resolved');
      }

      if (decode != null) {
        final ui.ImmutableBuffer buffer =
            await ui.ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      } else {
        assert(decodeDepreacted != null);
        return decodeDepreacted!(bytes);
      }
    } catch (e) {
      // Depending on where the exception was thrown, the image cache may not
      // have had a chance to track the key in the cache at all.
      // Schedule a microtask to give the cache a chance to add the key.
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      chunkEvents.close();
    }
  }
}
