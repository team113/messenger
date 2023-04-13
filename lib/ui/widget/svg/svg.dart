// ignore_for_file: public_member_api_docs, sort_constructors_first
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
class AssetWidget extends StatelessWidget {
  final String asset;
  final Alignment alignment;
  final BoxFit fit;
  final double? height;
  final String? package;
  final WidgetBuilder? placeholderBuilder;
  final String? semanticsLabel;
  final double? width;
  final bool excludeFromSemantics;
  const AssetWidget({
    Key? key,
    required this.asset,
    this.alignment = Alignment.center,
    this.fit = BoxFit.contain,
    this.height,
    this.package,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.width,
    this.excludeFromSemantics = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgFromAsset(
      asset: asset,
      key: key,
      alignment: alignment,
      fit: fit,
      height: height,
      package: package,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      width: width,
      excludeFromSemantics: excludeFromSemantics,
    );
  }
}

/// Instantiates a widget rendering an SVG picture from an [Uint8List].
///
/// Either the [width] and [height] arguments should be specified, or the
/// widget should be placed in a context setting layout constraints tightly.
/// Otherwise, the image dimensions will change as the image is loaded, which
/// will result in ugly layout changes.
class BytesWidget extends StatelessWidget {
  final Uint8List bytes;
  final Alignment alignment;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? placeholderBuilder;
  final String? semanticsLabel;
  final bool excludeFromSemantics;
  const BytesWidget({
    Key? key,
    required this.bytes,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgFromBytes(
      bytes: bytes,
      key: key,
      alignment: Alignment.center,
      fit: fit,
      width: width,
      height: height,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
  }
}

/// Instantiates a widget rendering an SVG picture from a [File].
///
/// Either the [width] and [height] arguments should be specified, or the
/// widget should be placed in a context setting layout constraints tightly.
/// Otherwise, the image dimensions will change as the image is loaded, which
/// will result in ugly layout changes.
class FileWidget extends StatelessWidget {
  final File file;
  final Alignment alignment;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? placeholderBuilder;
  final String? semanticsLabel;
  final bool excludeFromSemantics;
  const FileWidget({
    Key? key,
    required this.file,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgFromFile(
      file: file,
      key: key,
      alignment: Alignment.center,
      excludeFromSemantics: excludeFromSemantics,
      fit: fit,
      height: height,
      semanticsLabel: semanticsLabel,
      width: width,
    );
  }
}
