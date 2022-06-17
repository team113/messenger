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

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'src/interface.dart'
    if (dart.library.io) 'src/io.dart'
    if (dart.library.html) 'src/web.dart';

/// SVG images renderer.
///
/// Actual renderer is determined based on the current platform:
/// - [SvgPicture] is used on all non-web platforms and on web with `CanvasKit`
///   renderer;
/// - [Image.network] is used on web with html-renderer.
class SvgLoader {
  /// Instantiates a widget rendering an SVG picture from an [AssetBundle].
  ///
  /// The key will be derived from the `assetName`, `package`, and `bundle`
  /// arguments. The `package` argument must be non-`null` when displaying an
  /// SVG from a package and `null` otherwise.
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context that sets tight layout constraints.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  static Widget asset(
    String asset, {
    Key? key,
    Alignment alignment = Alignment.center,
    Color? color,
    BoxFit fit = BoxFit.contain,
    double? height,
    String? package,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    double? width,
    bool excludeFromSemantics = false,
  }) =>
      svgFromAsset(
        asset,
        key: key,
        alignment: alignment,
        color: color,
        fit: fit,
        height: height,
        package: package,
        placeholderBuilder: placeholderBuilder,
        semanticsLabel: semanticsLabel,
        width: width,
        excludeFromSemantics: excludeFromSemantics,
      );

  /// Instantiates a widget rendering an SVG picture from an [Uint8List].
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context setting layout constraints tightly.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  static Widget bytes(
    Uint8List bytes, {
    Key? key,
    Alignment alignment = Alignment.center,
    Color? color,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
  }) =>
      svgFromBytes(
        bytes,
        key: key,
        alignment: Alignment.center,
        color: color,
        fit: fit,
        width: width,
        height: height,
        semanticsLabel: semanticsLabel,
        excludeFromSemantics: excludeFromSemantics,
      );

  /// Instantiates a widget rendering an SVG picture from a [File].
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context setting layout constraints tightly.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  static Widget file(
    File file, {
    Key? key,
    Alignment alignment = Alignment.center,
    Color? color,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
  }) =>
      svgFromFile(
        file,
        key: key,
        alignment: Alignment.center,
        color: color,
        excludeFromSemantics: excludeFromSemantics,
        fit: fit,
        height: height,
        semanticsLabel: semanticsLabel,
        width: width,
      );
}
