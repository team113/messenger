// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'src/interface.dart'
    if (dart.library.io) 'src/io.dart'
    if (dart.library.js_interop) 'src/web.dart';
import 'svgs.dart';

export 'svgs.dart';

/// SVG images renderer.
///
/// Actual renderer is determined based on the current platform:
/// - [SvgPicture] is used on all non-web platforms and on web with `CanvasKit`
///   renderer;
/// - [Image.network] is used on web with html-renderer.
class SvgImage extends StatelessWidget {
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
  const SvgImage.asset(
    this.asset, {
    super.key,
    this.alignment = Alignment.center,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  }) : file = null,
       bytes = null;

  /// Instantiates a widget rendering an SVG picture from an [Uint8List].
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context setting layout constraints tightly.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  const SvgImage.bytes(
    this.bytes, {
    super.key,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  }) : file = null,
       asset = null;

  /// Instantiates a widget rendering an SVG picture from a [File].
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context setting layout constraints tightly.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  const SvgImage.file(
    this.file, {
    super.key,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  }) : bytes = null,
       asset = null;

  /// Instantiates a widget rendering an SVG picture from a [SvgData].
  SvgImage.icon(
    SvgData data, {
    super.key,
    this.alignment = Alignment.center,
    this.fit = BoxFit.contain,
    double? width,
    double? height,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  }) : asset = data.asset,
       file = null,
       bytes = null,
       width = width ?? data.width,
       height = height ?? data.height;

  /// Path to an asset containing an SVG image to display.
  final String? asset;

  /// [File] representing an SVG image to display.
  final File? file;

  /// [Uint8List] bytes containing an SVG image to display.
  final Uint8List? bytes;

  /// [Alignment] to display this image with.
  final Alignment? alignment;

  /// [BoxFit] to apply to this image.
  final BoxFit? fit;

  /// Width to constrain this image with.
  final double? width;

  /// Height to constrain this image with.
  final double? height;

  /// Builder, building a [Widget] to display when this SVG image is being
  /// loaded, fetched or initialized.
  final WidgetBuilder? placeholderBuilder;

  /// Label to put on the [Semantics] of this [Widget].
  ///
  /// Only meaningful, if [excludeFromSemantics] is not `true`.
  final String? semanticsLabel;

  /// Indicator whether this [Widget] should be excluded from the [Semantics].
  final bool? excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    if (asset != null) {
      return svgFromAsset(
        asset!,
        alignment: alignment!,
        fit: fit!,
        width: width,
        height: height,
        placeholderBuilder: placeholderBuilder,
        semanticsLabel: semanticsLabel,
        excludeFromSemantics: excludeFromSemantics!,
      );
    } else if (bytes != null) {
      return svgFromBytes(
        bytes!,
        alignment: alignment!,
        fit: fit!,
        width: width,
        height: height,
        placeholderBuilder: placeholderBuilder,
        semanticsLabel: semanticsLabel,
        excludeFromSemantics: excludeFromSemantics!,
      );
    } else {
      return svgFromFile(
        file!,
        alignment: alignment!,
        fit: fit!,
        width: width,
        height: height,
        placeholderBuilder: placeholderBuilder,
        semanticsLabel: semanticsLabel,
        excludeFromSemantics: excludeFromSemantics!,
      );
    }
  }
}
