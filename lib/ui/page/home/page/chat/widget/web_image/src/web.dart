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

// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/util/backoff.dart';
import '/util/platform_utils.dart';

/// Web [html.ImageElement] showing images natively.
///
/// Uses exponential backoff algorithm to re-fetch the [src] in case of errors.
///
/// Invokes the provided [onForbidden] callback on the `403 Forbidden` HTTP
/// errors.
///
/// Uses [Image.network] on non-web platforms.
class WebImage extends StatefulWidget {
  const WebImage(
    this.src, {
    super.key,
    this.onForbidden,
  });

  /// URL of the image to display.
  final String src;

  /// Callback, called when loading an image from the provided [src] fails with
  /// a forbidden network error.
  final FutureOr<void> Function()? onForbidden;

  @override
  State<WebImage> createState() => _WebImageState();
}

/// State of a [WebImage] used to run the [_backoff] operation.
class _WebImageState extends State<WebImage> {
  /// [CancelToken] canceling the [_backoff].
  CancelToken _cancelToken = CancelToken();

  /// Indicator whether [_backoff] is running.
  bool _backoffRunning = false;

  /// Indicator whether image is loading.
  bool _loading = true;

  @override
  void didUpdateWidget(WebImage oldWidget) {
    if (oldWidget.src != widget.src) {
      _cancelToken.cancel();
      _cancelToken = CancelToken();
      _backoffRunning = false;
      _loading = true;
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
    return Stack(
      children: [
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (!_backoffRunning)
          IgnorePointer(
            child: _HtmlImage(
              src: widget.src,
              onLoaded: () => _loading = false,
              onError: _backoff,
            ),
          ),
      ],
    );
  }

  /// Loads the image header from the [WebImage.src] to ensure that image can be
  /// loaded.
  ///
  /// Retries itself using exponential backoff algorithm on a failure.
  Future<void> _backoff() async {
    if (_backoffRunning) {
      return;
    }

    if (mounted) {
      setState(() => _backoffRunning = true);
    }

    try {
      await Backoff.run(
        () async {
          Response? data;

          try {
            data = await PlatformUtils.dio.head(widget.src);
          } on DioError catch (e) {
            if (e.response?.statusCode == 403) {
              await widget.onForbidden?.call();
              _cancelToken.cancel();
            }
          }

          if (data?.data != null && data!.statusCode == 200) {
            if (mounted) {
              setState(() => _backoffRunning = false);
            }
          } else {
            throw Exception('Image `HEAD` request failed');
          }
        },
        _cancelToken,
      );
    } on OperationCanceledException {
      // No-op.
    }
  }
}

/// Web [html.ImageElement] used to show images natively.
class _HtmlImage extends StatefulWidget {
  const _HtmlImage({
    required this.src,
    this.onError,
    this.onLoaded,
  });

  /// URL of the image to display.
  final String src;

  /// Callback, called when image loaded.
  final VoidCallback? onLoaded;

  /// Callback, called when image loading failed.
  final VoidCallback? onError;

  @override
  State<_HtmlImage> createState() => _HtmlImageState();
}

/// State of a [_HtmlImage] used to register and remove the actual HTML element
/// representing an image.
class _HtmlImageState extends State<_HtmlImage> {
  /// Native [html.ImageElement] itself.
  html.ImageElement? _element;

  /// Unique identifier for a platform view.
  late int _elementId;

  /// Subscription for [html.ImageElement.onLoad] stream.
  StreamSubscription? _loadSubscription;

  /// Subscription for [html.ImageElement.onError] stream.
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    _initImageElement();
    super.initState();
  }

  @override
  void didUpdateWidget(_HtmlImage oldWidget) {
    if (oldWidget.src != widget.src) {
      _element?.removeAttribute('src');
      _element?.remove();
      _initImageElement();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _loadSubscription?.cancel();
    _errorSubscription?.cancel();
    _element?.removeAttribute('src');
    _element?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: '${_elementId}__webImageViewType__${widget.src}__',
    );
  }

  /// Registers the actual HTML element representing an image.
  void _initImageElement() {
    _elementId = platformViewsRegistry.getNextPlatformViewId();

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      '${_elementId}__webImageViewType__${widget.src}__',
      (int viewId) {
        _element = html.ImageElement(src: widget.src)
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'scale-down';

        if (_element?.complete == true) {
          widget.onLoaded?.call();
        }

        _loadSubscription?.cancel();
        _loadSubscription = _element?.onLoad.listen((_) {
          widget.onLoaded?.call();
        });

        _errorSubscription?.cancel();
        _errorSubscription = _element?.onError.listen((_) {
          widget.onError?.call();
        });

        return _element!;
      },
    );
  }
}
