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

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'src/interface.dart'
    if (dart.library.io) 'src/io.dart'
    if (dart.library.html) 'src/web.dart';

/// SVG images renderer.
/// SVG images renderer.
///
/// Actual renderer is determined based on the current platform:
/// - [SvgPicture] is used on all non-web platforms and on web with `CanvasKit`
///   renderer;
/// - [Image.network] is used on web with html-renderer.
class SvgImage extends StatelessWidget {
  const SvgImage._({
    super.key,
    this.asset,
    this.file,
    this.bytes,
    required this.alignment,
    required this.fit,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  });

  /// Relative path to the file of the resource containing the image.
  final String? asset;

  /// Reference to a file on the file system.
  final File? file;

  /// Array of bytes containing image data.
  final Uint8List? bytes;

  /// Image alignment.
/// Actual renderer is determined based on the current platform:
/// - [SvgPicture] is used on all non-web platforms and on web with `CanvasKit`
///   renderer;
/// - [Image.network] is used on web with html-renderer.
class SvgImage extends StatelessWidget {
  const SvgImage._({
    super.key,
    this.asset,
    this.file,
    this.bytes,
    required this.alignment,
    required this.fit,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  });

  /// Relative path to the file of the resource containing the image.
  final String? asset;

  /// Reference to a file on the file system.
  final File? file;

  /// Array of bytes containing image data.
  final Uint8List? bytes;

  /// Image alignment.
  final Alignment alignment;

  /// Image scaling.

  /// Image scaling.
  final BoxFit fit;

  /// Image width.
  final double? width;

  /// Image height.

  /// Image width.
  final double? width;

  /// Image height.
  final double? height;

  /// Сreates a temporary image when loading.

  /// Сreates a temporary image when loading.
  final WidgetBuilder? placeholderBuilder;

  /// A text description of the image.

  /// A text description of the image.
  final String? semanticsLabel;

  /// Indicating whether to exclude the image from the screen reader.

  /// Indicating whether to exclude the image from the screen reader.
  final bool excludeFromSemantics;

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
  factory SvgImage.asset(
    String asset, {

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
  factory SvgImage.asset(
    String asset, {
    Key? key,
    Alignment alignment = Alignment.center,
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
  }) {
    return SvgImage._(
      asset: asset,
      key: key,
      alignment: Alignment.center,
      fit: BoxFit.contain,
      width: width,
      height: height,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: false,
    );
  }
    Alignment alignment = Alignment.center,
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
  }) {
    return SvgImage._(
      asset: asset,
      key: key,
      alignment: Alignment.center,
      fit: BoxFit.contain,
      width: width,
      height: height,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: false,
    );
  }

  /// Instantiates a widget rendering an SVG picture from a [File].
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context setting layout constraints tightly.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  factory SvgImage.file(
    File file, {
    Key? key,
    Alignment alignment = Alignment.center,
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
  }) {
    return SvgImage._(
      key: key,
      file: file,
      alignment: alignment,
      fit: fit,
      width: width,
      width: width,
      height: height,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
  }

  /// Instantiates a widget rendering an SVG picture from an [Uint8List].
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context setting layout constraints tightly.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  factory SvgImage.bytes(
    Uint8List bytes, {
  /// Instantiates a widget rendering an SVG picture from an [Uint8List].
  ///
  /// Either the [width] and [height] arguments should be specified, or the
  /// widget should be placed in a context setting layout constraints tightly.
  /// Otherwise, the image dimensions will change as the image is loaded, which
  /// will result in ugly layout changes.
  factory SvgImage.bytes(
    Uint8List bytes, {
    Key? key,
    Alignment alignment = Alignment.center,
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
  }) {
    return SvgImage._(
      key: key,
      bytes: bytes,
      alignment: alignment,
      fit: fit,
      width: width,
      height: height,
      placeholderBuilder: placeholderBuilder,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (asset != null) {
      return svgFromAsset(
        asset!,
        alignment: alignment,
        fit: fit,
        width: width,
        height: height,
        placeholderBuilder: placeholderBuilder,
        semanticsLabel: semanticsLabel,
        excludeFromSemantics: excludeFromSemantics,
      );
    } else if (file != null) {
      return svgFromFile(
        file!,
        alignment: alignment,
        fit: fit,
        width: width,
        height: height,
        placeholderBuilder: placeholderBuilder,
        semanticsLabel: semanticsLabel,
        excludeFromSemantics: excludeFromSemantics,
      );
    } else if (bytes != null) {
      return svgFromBytes(
        bytes!,
        alignment: alignment,
        fit: fit,
        width: width,
        height: height,
        placeholderBuilder: placeholderBuilder,
        semanticsLabel: semanticsLabel,
        excludeFromSemantics: excludeFromSemantics,
      );
    } else {
      return Container();
    }
    if (asset != null) {
      return svgFromAsset(
        asset!,
        alignment: alignment,
        fit: fit,
        width: width,
        height: height,
        placeholderBuilder: placeholderBuilder,
        semanticsLabel: semanticsLabel,
        excludeFromSemantics: excludeFromSemantics,
      );
    } else if (file != null) {
      return svgFromFile(
        file!,
        alignment: alignment,
        fit: fit,
        width: width,
        height: height,
        placeholderBuilder: placeholderBuilder,
        semanticsLabel: semanticsLabel,
        excludeFromSemantics: excludeFromSemantics,
      );
    } else if (bytes != null) {
      return svgFromBytes(
        bytes!,
        alignment: alignment,
        fit: fit,
        width: width,
        height: height,
        placeholderBuilder: placeholderBuilder,
        semanticsLabel: semanticsLabel,
        excludeFromSemantics: excludeFromSemantics,
      );
    } else {
      return Container();
    }
  }
}
