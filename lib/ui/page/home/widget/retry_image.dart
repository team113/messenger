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

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// [Image] wrapper performs image loading with backoff.
class RetryImage extends StatefulWidget {
  const RetryImage(
    this.url, {
    this.error403,
    this.fit,
    this.height,
    Key? key,
  }) : super(key: key);

  /// URL of the image.
  final String url;

  /// Callback called when image loading from the [url] failed with code 403.
  final Future<void> Function()? error403;

  /// [BoxFit] of the image.
  final BoxFit? fit;

  /// Height of the image.
  final double? height;

  @override
  State<RetryImage> createState() => _RetryImageState();
}

/// [State] of [RetryImage] maintaining image data loading with backoff.
class _RetryImageState extends State<RetryImage> {
  /// [Timer] used to performs image loading with backoff.
  Timer? _timer;

  /// [Uint8List] image bytes.
  Uint8List? _image;

  /// Image downloading progress.
  double _progress = 0;

  /// Timeout of the backoff loading.
  Duration _backoffTimeout = const Duration(microseconds: 250);

  @override
  void initState() {
    _loadImage();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _image != null
      ? Image.memory(
          _image!,
          height: widget.height,
          fit: widget.fit,
          key: const Key('RetryImageLoaded'),
        )
      : Container(
          height: widget.height,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 40,
              maxWidth: 40,
              minWidth: 10,
              minHeight: 10,
            ),
            child: AspectRatio(
              aspectRatio: 1 / 1,
              child: CircularProgressIndicator(
                key: const Key('RetryImageLoading'),
                value: _progress == 0 ? null : _progress,
              ),
            ),
          ),
        );

  /// Loads image with backoff.
  Future<void> _loadImage() async {
    Response? data;

    try {
      data = await Dio().get(
        widget.url,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _progress = received / total;
            if (mounted) {
              setState(() {});
            }
          }
        },
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioError catch (_) {
      if (_.response?.statusCode == 403) {
        await widget.error403?.call();
      }
    }

    if (data?.data != null && data!.statusCode == 200) {
      _image = data.data;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _timer = Timer(
      _backoffTimeout,
      () {
        if (_backoffTimeout < const Duration(seconds: 32)) {
          _backoffTimeout *= 2;
        }
        _loadImage();
      },
    );
  }
}
