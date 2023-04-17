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
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/util/platform_utils.dart';

/// Web [html.ImageElement] used to show images natively.
///
/// Uses [Image.network] on non-web platforms.
class WebImage extends StatefulWidget {
  const WebImage(
    this.src, {
    this.onForbidden,
    Key? key,
  }) : super(key: key);

  /// URL of the image to display.
  final String src;

  /// Callback, called when loading an image from the provided [src] fails with
  /// a forbidden network error.
  final Future<void> Function()? onForbidden;

  @override
  State<WebImage> createState() => _WebImageState();
}

/// State of a [WebImage] used to register and remove the actual HTML element
/// representing an image.
class _WebImageState extends State<WebImage> {
  /// Native [html.ImageElement] itself.
  html.ImageElement? _element;

  /// Indicator whether the image to display is fully loaded.
  bool _isLoaded = false;

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
  void didUpdateWidget(WebImage oldWidget) {
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

        _loadSubscription?.cancel();
        _loadSubscription = _element?.onLoad.listen((_) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        });

        _errorSubscription?.cancel();
        _errorSubscription = _element?.onError.listen((_) async {
          try {
            await PlatformUtils.dio.head(widget.src);
          } catch (e) {
            if (e is DioError) {
              if (e.response?.statusCode == 403) {
                await widget.onForbidden?.call();
              }
            }
          }
        });

        return _element!;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: _isLoaded ? 1 : 0,
          child: HtmlElementView(
              viewType: '${_elementId}__webImageViewType__${widget.src}__'),
        ),
        if (!_isLoaded) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
