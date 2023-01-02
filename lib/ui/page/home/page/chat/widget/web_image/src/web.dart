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

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Web [html.ImageElement] used to show images natively.
///
/// Uses [Image.network] on non-web platforms.
class WebImage extends StatefulWidget {
  const WebImage(
    this.src, {
    Key? key,
  }) : super(key: key);

  /// URL of the image to display.
  final String src;

  @override
  State<WebImage> createState() => _WebImageState();
}

/// State of a [WebImage] used to register and remove the actual HTML element
/// representing an image.
class _WebImageState extends State<WebImage> {
  /// Native [html.ImageElement] itself.
  html.ImageElement? _element;

  @override
  void initState() {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      '__webImageViewType__${widget.src}__',
      (int viewId) {
        _element = html.ImageElement(src: widget.src)
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'scale-down';
        return _element!;
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    _element?.removeAttribute('src');
    _element?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: '__webImageViewType__${widget.src}__');
  }
}
