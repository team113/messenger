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

/// Instantiates a widget rendering an SVG picture from an [AssetBundle].
///
/// The key will be derived from the `assetName`, `package`, and `bundle`
/// arguments. The `package` argument must be non-`null` when displaying an SVG
/// from a package and `null` otherwise.
///
/// Either the [width] and [height] arguments should be specified, or the widget
/// should be placed in a context that sets tight layout constraints. Otherwise,
/// the image dimensions will change as the image is loaded, which will result
/// in ugly layout changes.
class SvgFromAsset extends StatelessWidget {
  const SvgFromAsset(
    this.asset, {
    super.key,
    this.alignment = Alignment.center,
    this.excludeFromSemantics = false,
    this.fit = BoxFit.contain,
    this.height,
    this.package,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.width,
  });

  /// Path to an asset containing an SVG image to display.
  final String asset;

  /// [Alignment] to display this image with.
  final Alignment? alignment;

  /// [BoxFit] to apply to this image.
  final BoxFit? fit;

  /// Width to constrain this image with.
  final double? width;

  /// Height to constrain this image with.
  final double? height;

  /// TODO: docs
  final String? package;

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
  Widget build(BuildContext context) => throw UnimplementedError();
}

/// Instantiates a widget rendering an SVG picture from an [Uint8List].
///
/// Either the [width] and [height] arguments should be specified, or the widget
/// should be placed in a context setting layout constraints tightly. Otherwise,
/// the image dimensions will change as the image is loaded, which will result
/// in ugly layout changes.
class SvgFromBytes extends StatelessWidget {
  const SvgFromBytes(
    this.bytes, {
    super.key,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  });

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
  Widget build(BuildContext context) => throw UnimplementedError();
}

/// Instantiates a widget rendering an SVG picture from a [File].
///
/// Either the [width] and [height] arguments should be specified, or the widget
/// should be placed in a context setting layout constraints tightly. Otherwise,
/// the image dimensions will change as the image is loaded, which will result
/// in ugly layout changes.
class SvgFromFile extends StatelessWidget {
  const SvgFromFile(this.file,{
    super.key,
    
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  });

  /// [File] representing an SVG image to display.
  final File? file;

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
  Widget build(BuildContext context) => throw UnimplementedError();
}
