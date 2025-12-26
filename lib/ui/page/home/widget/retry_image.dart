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

import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/domain/model/attachment.dart';
import '/domain/model/file.dart';
import '/themes.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/ui/worker/cache.dart';

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
    this.thumbhash,
    this.fit,
    this.height,
    this.width,
    this.minWidth,
    this.aspectRatio,
    this.borderRadius,
    this.onForbidden,
    this.filter,
    this.cancelable = false,
    this.displayProgress = true,
    this.loadingBuilder,
  });

  /// Constructs a [RetryImage] from the provided [attachment] loading the
  /// [ImageAttachment.big] with a [ImageAttachment.small] fallback.
  factory RetryImage.attachment(
    ImageAttachment attachment, {
    BoxFit? fit,
    double? height,
    double? width,
    double? minWidth,
    BorderRadius? borderRadius,
    Future<void> Function()? onForbidden,
    ImageFilter? filter,
    bool cancelable = false,
    bool displayProgress = true,
  }) {
    final ImageFile image;

    final StorageFile original = attachment.original;
    if (original.checksum != null &&
        CacheWorker.instance.exists(original.checksum!)) {
      image = original as ImageFile;
    } else {
      image = attachment.big;
    }

    double? aspectRatio;
    if (image.width != null && image.height != null) {
      aspectRatio = image.width! / image.height!;
    }

    return RetryImage(
      image.url,
      checksum: image.checksum,
      thumbhash:
          image.thumbhash ??
          attachment.big.thumbhash ??
          attachment.medium.thumbhash ??
          attachment.small.thumbhash,
      fit: fit,
      height: height,
      width: width,
      minWidth: minWidth,
      aspectRatio: aspectRatio,
      borderRadius: borderRadius,
      onForbidden: onForbidden,
      filter: filter,
      cancelable: cancelable,
      displayProgress: displayProgress,
    );
  }

  /// URL of an image to display.
  final String url;

  /// SHA-256 checksum of the image to display.
  final String? checksum;

  /// [ThumbHash] of this [RetryImage].
  final ThumbHash? thumbhash;

  /// Callback, called when loading an image from the provided [url] fails with
  /// a forbidden network error.
  final FutureOr<void> Function()? onForbidden;

  /// [BoxFit] to apply to this [RetryImage].
  final BoxFit? fit;

  /// Height of this [RetryImage].
  final double? height;

  /// Width of this [RetryImage].
  final double? width;

  /// Minimal width of this [RetryImage].
  final double? minWidth;

  /// Aspect ratio of an image to display.
  ///
  /// Used to display [thumbhash] with the correct aspect ratio, as it loses
  /// precision.
  final double? aspectRatio;

  /// [ImageFilter] to apply to this [RetryImage].
  final ImageFilter? filter;

  /// [BorderRadius] to apply to this [RetryImage].
  final BorderRadius? borderRadius;

  /// Indicator whether an ongoing image fetching from the [url] is cancelable.
  final bool cancelable;

  /// Indicator whether the image fetching progress should be displayed.
  final bool displayProgress;

  /// Builder, building the background of this [RetryImage] in its loading
  /// state, when the [url] or [thumbhash] isn't displayed yet.
  final Widget Function()? loadingBuilder;

  @override
  State<RetryImage> createState() => _RetryImageState();
}

/// [State] of [RetryImage] maintaining image data loading with the exponential
/// backoff algorithm.
class _RetryImageState extends State<RetryImage> {
  /// Byte data of the fetched image.
  Uint8List? _image;

  /// Indicator whether the [_image] has been initialized.
  bool _imageInitialized = false;

  /// Image fetching progress.
  double _progress = 0;

  /// [CancelToken] canceling the [_loadImage] operation.
  CancelToken _cancelToken = CancelToken();

  /// Indicator whether image fetching has been canceled.
  bool _canceled = false;

  /// Indicator whether the [_image] is considered to be a SVG.
  bool _isSvg = false;

  @override
  void initState() {
    _loadImage();

    // We're expecting a checksum to properly fetch the image from the cache.
    if (widget.checksum == null) {
      widget.onForbidden?.call();
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant RetryImage oldWidget) {
    if (oldWidget.url != widget.url) {
      _cancelToken.cancel();
      _cancelToken = CancelToken();
      _loadImage();
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
    final style = Theme.of(context).style;

    Widget child;

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
          frameBuilder: (_, child, frame, _) {
            if (frame != null && _imageInitialized == false) {
              Future.delayed(Duration.zero, () {
                if (context.mounted) {
                  setState(() => _imageInitialized = true);
                }
              });
            }

            return child;
          },
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
          constraints: const BoxConstraints(minWidth: 200),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!_canceled && widget.displayProgress)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: CustomProgressIndicator.primary(
                    value: _progress == 0 ? null : _progress.clamp(0, 1),
                  ),
                ),
              if (widget.cancelable)
                Center(
                  child: _canceled
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: style.colors.onBackgroundOpacity20,
                                blurRadius: 8,
                                blurStyle: BlurStyle.outer.workaround,
                              ),
                            ],
                          ),
                          child: const SvgIcon(SvgIcons.download),
                        )
                      : const SvgIcon(SvgIcons.closePrimary),
                ),
            ],
          ),
        ),
      );
    }

    if (!_imageInitialized) {
      if (widget.thumbhash != null) {
        double? width = widget.width;

        if (widget.height != null &&
            widget.aspectRatio != null &&
            widget.fit != BoxFit.contain) {
          width ??= widget.height! * widget.aspectRatio!;
        }

        Widget thumbhash = Image(
          image: CacheWorker.instance.getThumbhashProvider(widget.thumbhash!),
          key: const Key('Thumbhash'),
          height: widget.height,
          width: width,
          fit: BoxFit.cover,
        );

        if (widget.aspectRatio != null && widget.fit == BoxFit.contain) {
          thumbhash = ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width ?? double.infinity,
              maxHeight: widget.height ?? double.infinity,
            ),
            child: AspectRatio(
              aspectRatio: widget.aspectRatio!,
              child: thumbhash,
            ),
          );
        }

        if (widget.borderRadius != null) {
          thumbhash = ClipRRect(
            borderRadius: widget.borderRadius!,
            child: thumbhash,
          );
        }

        return ConstrainedBox(
          constraints: BoxConstraints(minWidth: widget.minWidth ?? 0),
          child: SizedBox(
            height: widget.height,
            width: widget.width,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                if (widget.loadingBuilder != null) widget.loadingBuilder!(),
                Center(child: thumbhash),
                Positioned.fill(
                  child: Center(
                    child: SafeAnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: KeyedSubtree(
                        key: Key('Image_${widget.url}'),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (widget.loadingBuilder != null) {
        return Stack(children: [widget.loadingBuilder!(), child]);
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: widget.minWidth ?? 0),
      child: KeyedSubtree(
        key: Key('Image_${widget.url}'),
        child: SafeAnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: child,
        ),
      ),
    );
  }

  /// Loads the [_image] from the provided URL.
  FutureOr<void> _loadImage() async {
    final FutureOr<CacheEntry> result = CacheWorker.instance.get(
      url: widget.url,
      checksum: widget.checksum,
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
        await widget.onForbidden?.call();
      },
    );

    if (result is CacheEntry) {
      _image = result.bytes ?? _image;
    } else {
      _image = (await result).bytes ?? _image;
    }

    _isSvg = false;
    if (_image != null) {
      _isSvg =
          // Starts with `<svg`.
          (_image!.length >= 4 &&
              _image![0] == 60 &&
              _image![1] == 115 &&
              _image![2] == 118 &&
              _image![3] == 103) ||
          // Starts with `<?xml`.
          (_image!.length >= 5 &&
              _image![0] == 60 &&
              _image![1] == 63 &&
              _image![2] == 120 &&
              _image![3] == 109 &&
              _image![4] == 108);
    }

    if (mounted) {
      setState(() {});
    }
  }
}
