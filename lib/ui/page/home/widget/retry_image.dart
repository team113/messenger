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
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/domain/model/attachment.dart';
import '/domain/model/file.dart';
import '/domain/service/file.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

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
    super.key,
    this.checksum,
    this.fallbackUrl,
    this.fallbackChecksum,
    this.fit,
    this.height,
    this.width,
    this.borderRadius,
    this.onForbidden,
    this.filter,
    this.cancelable = false,
    this.autoLoad = true,
    this.displayProgress = true,
  });

  /// Constructs a [RetryImage] from the provided [attachment] loading the
  /// [ImageAttachment.big] with a [ImageAttachment.small] fallback.
  factory RetryImage.attachment(
    ImageAttachment attachment, {
    BoxFit? fit,
    double? height,
    double? width,
    BorderRadius? borderRadius,
    Future<void> Function()? onForbidden,
    ImageFilter? filter,
    bool cancelable = false,
    bool autoLoad = true,
    bool displayProgress = true,
  }) {
    final StorageFile image;

    final StorageFile original = attachment.original;
    if (original.checksum != null && FIFOCache.exists(original.checksum!)) {
      image = original;
    } else {
      image = attachment.big;
    }

    return RetryImage(
      image.url,
      checksum: image.checksum,
      fallbackUrl: attachment.small.url,
      fallbackChecksum: attachment.small.checksum,
      fit: fit,
      height: height,
      width: width,
      borderRadius: borderRadius,
      onForbidden: onForbidden,
      filter: filter,
      cancelable: cancelable,
      autoLoad: autoLoad,
      displayProgress: displayProgress,
    );
  }

  /// URL of an image to display.
  final String url;

  /// SHA-256 checksum of the image to display.
  final String? checksum;

  /// URL of a fallback image to display.
  final String? fallbackUrl;

  /// SHA-256 checksum of the fallback image to display.
  final String? fallbackChecksum;

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
  final ImageFilter? filter;

  /// [BorderRadius] to apply to this [RetryImage].
  final BorderRadius? borderRadius;

  /// Indicator whether an ongoing image fetching from the [url] is cancelable.
  final bool cancelable;

  /// Indicator whether the image fetching should start as soon as this
  /// [RetryImage] is displayed.
  final bool autoLoad;

  /// Indicator whether the image fetching progress should be displayed.
  final bool displayProgress;

  @override
  State<RetryImage> createState() => _RetryImageState();
}

/// [State] of [RetryImage] maintaining image data loading with the exponential
/// backoff algorithm.
class _RetryImageState extends State<RetryImage> {
  /// Byte data of the fetched image.
  Uint8List? _image;

  /// Byte data of the fetched fallback image.
  Uint8List? _fallback;

  /// Image fetching progress.
  double _progress = 0;

  /// [CancelToken] canceling the [_loadImage] operation.
  CancelToken _cancelToken = CancelToken();

  /// [CancelToken] canceling the [_loadFallback] operation.
  CancelToken _fallbackToken = CancelToken();

  /// Indicator whether image fetching has been canceled.
  bool _canceled = false;

  /// Indicator whether the [_image] is considered to be a SVG.
  bool _isSvg = false;

  @override
  void initState() {
    _loadFallback();

    if (widget.autoLoad) {
      _loadImage();
    } else {
      _canceled = true;
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant RetryImage oldWidget) {
    if (oldWidget.fallbackUrl != widget.fallbackUrl) {
      _fallbackToken.cancel();
      _fallbackToken = CancelToken();
      _loadFallback();
    }

    if (oldWidget.url != widget.url ||
        (!oldWidget.autoLoad && widget.autoLoad)) {
      _cancelToken.cancel();
      _cancelToken = CancelToken();
      _loadImage();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    _fallbackToken.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;

    if (_image != null) {
      Widget image;

      if (_isSvg) {
        return SvgImage.bytes(
          _image!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit ?? BoxFit.contain,
        );
      } else {
        image = Image.memory(
          _image!,
          key: const Key('Loaded'),
          height: widget.height,
          width: widget.width,
          fit: widget.fit,
        );
      }

      if (widget.filter != null) {
        image = ImageFiltered(imageFilter: widget.filter!, child: image);
      }

      if (widget.borderRadius != null) {
        image = ClipRRect(borderRadius: widget.borderRadius!, child: image);
      }

      child = image;
    } else {
      child = WidgetButton(
        onPressed: widget.cancelable
            ? () {
                if (_canceled) {
                  _canceled = false;
                  _cancelToken = CancelToken();
                  _loadImage();
                } else {
                  _canceled = true;
                  _cancelToken.cancel();
                }

                setState(() {});
              }
            : null,
        child: Container(
          key: const Key('Loading'),
          height: widget.height,
          constraints: const BoxConstraints(minWidth: 200),
          alignment: Alignment.center,
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 46,
              maxWidth: 46,
              minWidth: 10,
              minHeight: 10,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!_canceled && widget.displayProgress)
                  CustomProgressIndicator(
                    size: 40,
                    blur: false,
                    padding: const EdgeInsets.all(4),
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.secondary,
                    value: _progress == 0 ? null : _progress.clamp(0, 1),
                  ),
                if (widget.cancelable)
                  Center(
                    child: _canceled
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  blurStyle: BlurStyle.outer,
                                ),
                              ],
                            ),
                            child: SvgImage.asset(
                              'assets/icons/download.svg',
                              height: 40,
                            ),
                          )
                        : SvgImage.asset(
                            'assets/icons/close_primary.svg',
                            height: 13,
                          ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.fallbackUrl != null && _image == null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: _fallback == null
                ? SizedBox(width: 200, height: widget.height)
                : ClipRect(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: 15,
                        sigmaY: 15,
                        tileMode: TileMode.clamp,
                      ),
                      child: Transform.scale(
                        scale: 1.2,
                        child: Image.memory(
                          _fallback!,
                          key: const Key('Fallback'),
                          height: widget.height,
                          width: widget.width,
                          fit: widget.fit,
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned.fill(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child:
                    KeyedSubtree(key: Key('Image_${widget.url}'), child: child),
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: KeyedSubtree(
        key: Key('Image_${widget.url}'),
        child: child,
      ),
    );
  }

  /// Loads the [_fallback] from the provided URL.
  FutureOr<void> _loadFallback() async {
    if (widget.fallbackUrl == null) {
      return;
    }

    _fallback = await FileService.downloadAndCache(
      widget.fallbackUrl!,
      widget.fallbackChecksum,
      cancelToken: _fallbackToken,
      onForbidden: () async {
        widget.onForbidden?.call();
        _cancelToken.cancel();
        _fallbackToken.cancel();
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  /// Loads the [_image] from the provided URL.
  FutureOr<void> _loadImage() async {
    _image = await FileService.downloadAndCache(
      widget.url,
      widget.checksum,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          _progress = received / total;
          if (mounted) {
            setState(() {});
          }
        }
      },
      cancelToken: _cancelToken,
      onForbidden: () async {
        widget.onForbidden?.call();
        _cancelToken.cancel();
        _fallbackToken.cancel();
      },
    );
    _isSvg = false;

    if (_image != null) {
      _isSvg = _image!.length >= 4 &&
          _image![0] == 60 &&
          _image![1] == 115 &&
          _image![2] == 118 &&
          _image![3] == 103;
    }

    if (mounted) {
      setState(() {});
    }
  }
}
