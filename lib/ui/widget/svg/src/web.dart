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
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:js' as js;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/util/log.dart';

/// Instantiates a widget rendering an SVG picture from an [AssetBundle].
///
/// The key will be derived from the [asset] and [package] arguments. The
/// [package] argument must be non-`null` when displaying an SVG from a package
/// and `null` otherwise.
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
  final Alignment alignment;

  /// [BoxFit] to apply to this image.
  final BoxFit fit;

  /// Width to constrain this image with.
  final double? width;

  /// Height to constrain this image with.
  final double? height;

  /// [String] that identifies the package of the asset.
  final String? package;

  /// Builder, building a [Widget] to display when this SVG image is being
  /// loaded, fetched or initialized.
  final WidgetBuilder? placeholderBuilder;

  /// Label to put on the [Semantics] of this [Widget].
  ///
  /// Only meaningful, if [excludeFromSemantics] is not `true`.
  final String? semanticsLabel;

  /// Indicator whether this [Widget] should be excluded from the [Semantics].
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    String path = package == null ? asset : 'packages/$package/$asset';
    return _BrowserSvg(
      key: key,
      loader: _AssetSvgLoader(path),
      alignment: alignment,
      excludeFromSemantics: excludeFromSemantics,
      fit: fit,
      height: height,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      width: width,
    );
  }
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
  final Uint8List bytes;

  /// [Alignment] to display this image with.
  final Alignment alignment;

  /// [BoxFit] to apply to this image.
  final BoxFit fit;

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
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) => _BrowserSvg(
        key: key,
        loader: _BytesSvgLoader(bytes),
        alignment: alignment,
        excludeFromSemantics: excludeFromSemantics,
        fit: fit,
        height: height,
        placeholderBuilder: placeholderBuilder,
        semanticsLabel: semanticsLabel,
        width: width,
      );
}

/// Instantiates a widget rendering an SVG picture from a [File].
///
/// Either the [width] and [height] arguments should be specified, or the widget
/// should be placed in a context setting layout constraints tightly. Otherwise,
/// the image dimensions will change as the image is loaded, which will result
/// in ugly layout changes.
class SvgFromFile extends StatelessWidget {
  const SvgFromFile(
    this.file, {
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
  final File file;

  /// [Alignment] to display this image with.
  final Alignment alignment;

  /// [BoxFit] to apply to this image.
  final BoxFit fit;

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
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) => _BrowserSvg(
        key: key,
        loader: _FileSvgLoader(file),
        alignment: alignment,
        excludeFromSemantics: excludeFromSemantics,
        fit: fit,
        height: height,
        placeholderBuilder: placeholderBuilder,
        semanticsLabel: semanticsLabel,
        width: width,
      );
}

/// SVG picture loader.
abstract class _SvgLoader {
  /// Returns an [Uint8List] of the SVG file this loader represents.
  FutureOr<Uint8List> load();
}

/// SVG picture loader from an asset.
class _AssetSvgLoader implements _SvgLoader {
  const _AssetSvgLoader(this.asset);

  /// Asset path of the SVG picture.
  final String asset;

  /// Naive [LinkedHashMap]-based cache of [Uint8List]s.
  ///
  /// FIFO policy is used, meaning if [_cache] exceeds its [_cacheSize], then
  /// the first inserted element is removed.
  static final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();

  /// Maximum allowed length of the [_cache].
  static const _cacheSize = 50;

  @override
  FutureOr<Uint8List> load() {
    if (_cache[asset] != null) {
      return _cache[asset]!;
    }

    return Future(() async {
      String image = await rootBundle.loadString(asset);
      Uint8List bytes = Uint8List.fromList(utf8.encode(image));

      _cache[asset] = bytes;
      if (_cache.length > _cacheSize) {
        _cache.remove(_cache.keys.first);
      }

      return bytes;
    });
  }

  @override
  bool operator ==(Object other) =>
      other is _AssetSvgLoader && other.asset == asset;

  @override
  int get hashCode => asset.hashCode;
}

/// SVG picture loader from raw bytes.
class _BytesSvgLoader implements _SvgLoader {
  _BytesSvgLoader(this.bytes);

  /// Bytes of the SVG picture.
  final Uint8List bytes;

  @override
  Future<Uint8List> load() => Future.value(bytes);
}

/// SVG picture loader from a [File].
class _FileSvgLoader implements _SvgLoader {
  _FileSvgLoader(this.file);

  /// [File] to load the SVG picture from.
  final File file;

  @override
  Future<Uint8List> load() => file.readAsBytes();
}

/// Creates a widget that renders a SVG picture through [Image.network] on
/// `html` renderer and through [SvgPicture.memory] on `CanvasKit` renderer.
class _BrowserSvg extends StatefulWidget {
  const _BrowserSvg({
    super.key,
    required this.loader,
    required this.width,
    required this.height,
    required this.alignment,
    required this.excludeFromSemantics,
    required this.fit,
    required this.placeholderBuilder,
    required this.semanticsLabel,
  });

  /// Loader to load the SVG from.
  final _SvgLoader loader;

  /// If specified, the width to use for the SVG. If unspecified, the SVG
  /// will take the width of its parent.
  final double? width;

  /// If specified, the height to use for the SVG. If unspecified, the SVG
  /// will take the height of its parent.
  final double? height;

  /// How to align the picture within its parent widget.
  final Alignment alignment;

  /// Whether to exclude this picture from semantics.
  ///
  /// Useful for pictures which do not contribute meaningful information to an
  /// application.
  final bool excludeFromSemantics;

  /// How to inscribe the picture into the space allocated during layout.
  /// The default is [BoxFit.contain].
  final BoxFit fit;

  /// The placeholder to use while fetching, decoding, and parsing the SVG data.
  final WidgetBuilder? placeholderBuilder;

  /// The [Semantics.label] for this picture.
  ///
  /// The value indicates the purpose of the picture, and will be
  /// read out by screen readers.
  final String? semanticsLabel;

  @override
  _BrowserSvgState createState() => _BrowserSvgState();
}

/// State of [_BrowserSvg].
class _BrowserSvgState extends State<_BrowserSvg> {
  /// Index of a loading used to show previous SVG while loading the next one.
  int _loadIndex = 0;

  /// Decoded SVG image.
  String? _image;

  /// Raw bytes of an SVG image.
  Uint8List? _imageBytes;

  /// Indicates whether the current renderer is `CanvasKit`.
  bool get rendererCanvasKit => js.context['flutterCanvasKit'] != null;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_BrowserSvg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loader != widget.loader) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    _loadIndex++;
    var idx = _loadIndex;

    try {
      FutureOr<Uint8List> future = widget.loader.load();
      if (future is Uint8List) {
        _imageBytes = future;
      } else {
        _imageBytes = await future;
      }

      if (idx == _loadIndex) {
        var b64 = base64.encode(_imageBytes!.toList());
        _image = 'data:image/svg+xml;base64,$b64';

        if (mounted == true) {
          setState(() {});
        }
      }
    } catch (e, stack) {
      Log.error('Error loading SVG: $e\n$stack');
    }
  }

  /// Builds a placeholder displayed while loading a SVG picture.
  Widget _buildPlaceholder(BuildContext context) =>
      widget.placeholderBuilder == null
          ? const SizedBox()
          : Builder(builder: widget.placeholderBuilder!);

  @override
  Widget build(BuildContext context) => _image == null
      ? _buildPlaceholder(context)
      : rendererCanvasKit
          ? SvgPicture.memory(
              _imageBytes!,
              height: widget.height,
              fit: widget.fit,
              width: widget.width,
            )
          : Container(
              height: widget.height,
              width: widget.width,
              alignment: Alignment.center,
              child: Image.network(
                _image!,
                height: widget.height,
                fit: widget.fit,
                width: widget.width,
              ),
            );
}
