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
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:window_manager/window_manager.dart';

import '/config.dart';
import 'web/web_utils.dart';

/// Global variable to access [PlatformUtilsImpl].
///
/// May be reassigned to mock specific functionally.
// ignore: non_constant_identifier_names
PlatformUtilsImpl PlatformUtils = PlatformUtilsImpl();

/// Helper providing platform related features.
class PlatformUtilsImpl {
  /// Path to the downloads directory.
  String? _downloadDirectory;

  /// Indicates whether application is running in a web browser.
  bool get isWeb => GetPlatform.isWeb;

  // TODO: Remove when jonataslaw/getx#1936 is fixed:
  //       https://github.com/jonataslaw/getx/issues/1936
  /// Indicates whether device's OS is macOS.
  bool get isMacOS => WebUtils.isMacOS || GetPlatform.isMacOS;

  /// Indicates whether device's OS is Windows.
  bool get isWindows => GetPlatform.isWindows;

  /// Indicates whether device's OS is Linux.
  bool get isLinux => GetPlatform.isLinux;

  /// Indicates whether device's OS is Android.
  bool get isAndroid => GetPlatform.isAndroid;

  /// Indicates whether device's OS is iOS.
  bool get isIOS => GetPlatform.isIOS;

  /// Indicates whether device is running on a mobile OS.
  bool get isMobile => GetPlatform.isIOS || GetPlatform.isAndroid;

  /// Indicates whether device is running on a desktop OS.
  bool get isDesktop =>
      PlatformUtils.isMacOS || GetPlatform.isWindows || GetPlatform.isLinux;

  /// Returns a stream broadcasting fullscreen changes.
  Stream<bool> get onFullscreenChange {
    if (isWeb) {
      return WebUtils.onFullscreenChange;
    } else if (isDesktop) {
      StreamController<bool>? controller;

      var windowListener = _WindowListener(
        onEnterFullscreen: () => controller!.add(true),
        onLeaveFullscreen: () => controller!.add(false),
      );

      controller = StreamController<bool>(
        onListen: () => WindowManager.instance.addListener(windowListener),
        onCancel: () => WindowManager.instance.removeListener(windowListener),
      );

      return controller.stream;
    }

    // TODO: Implement for [isMobile] using the
    //       [SystemChrome.setSystemUIChangeCallback].
    return const Stream.empty();
  }

  /// Returns a path to the downloads directory.
  Future<String> get downloadsDirectory async {
    if (_downloadDirectory != null) {
      return _downloadDirectory!;
    }

    String path;
    if (PlatformUtils.isMobile) {
      path = (await getTemporaryDirectory()).path;
    } else {
      path = (await getDownloadsDirectory())!.path;
    }

    _downloadDirectory = '$path${Config.downloads}';
    return _downloadDirectory!;
  }

  /// Enters fullscreen mode.
  Future<void> enterFullscreen() async {
    if (isWeb) {
      WebUtils.toggleFullscreen(true);
    } else if (isDesktop) {
      await WindowManager.instance.setFullScreen(true);
    } else if (isMobile) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [],
      );
    }
  }

  /// Exits fullscreen mode.
  Future<void> exitFullscreen() async {
    if (isWeb) {
      WebUtils.toggleFullscreen(false);
    } else if (isDesktop) {
      await WindowManager.instance.setFullScreen(false);

      // TODO: Remove when leanflutter/window_manager#131 is fixed:
      //       https://github.com/leanflutter/window_manager/issues/131
      Size size = await WindowManager.instance.getSize();
      await WindowManager.instance.setSize(Size(size.width + 1, size.height));
    } else if (isMobile) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  /// Returns a [File] with the provided [filename] and [size], if any exist in
  /// the [downloadsDirectory].
  ///
  /// If [size] is `null`, then an attempt to get the size from the given [url]
  /// will be performed.
  Future<File?> fileExists(
    String filename, {
    int? size,
    String? url,
  }) async {
    if ((size != null || url != null) && !PlatformUtils.isWeb) {
      size = size ??
          int.parse(((await Dio().head(url!)).headers['content-length']
              as List<String>)[0]);

      String downloads = await PlatformUtils.downloadsDirectory;
      String name = p.basenameWithoutExtension(filename);
      String ext = p.extension(filename);
      File file = File('$downloads/$filename');

      // TODO: File might already be downloaded, compare hashes.
      for (int i = 1; await file.exists() && await file.length() != size; ++i) {
        file = File('$downloads/$name ($i)$ext');
      }

      if (await file.exists()) {
        return file;
      }
    }

    return null;
  }

  /// Downloads a file from the provided [url].
  FutureOr<File?> download(
    String url,
    String filename,
    int? size, {
    Function(int count, int total)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    if (PlatformUtils.isWeb) {
      await WebUtils.downloadFile(url, filename);
      return null;
    } else {
      // Calls the provided [callback] using the exponential backoff algorithm.
      Future<T?> withBackoff<T>(Future<T> Function() callback) async {
        Duration backoff = Duration.zero;
        T? result;

        while (result == null) {
          try {
            for (int i = 0; i < backoff.inMilliseconds / 125; i++) {
              await Future.delayed(125.milliseconds);
              if (cancelToken?.isCancelled == true) {
                return null;
              }
            }

            result = await callback();
            return result;
          } catch (_) {
            if (backoff.inMilliseconds == 0) {
              backoff = 125.milliseconds;
            } else if (backoff < 16.seconds) {
              backoff *= 2;
            }
          }
        }

        return result;
      }

      // Retry fetching the size unless any other that `404` error is thrown.
      File? file = await withBackoff<File?>(
        () async {
          try {
            return await fileExists(filename, size: size, url: url);
          } on DioError catch (e) {
            if (e.response?.statusCode == 404) {
              rethrow;
            }
          } catch (_) {
            // No-op.
          }

          return null;
        },
      );

      if (file == null) {
        final String name = p.basenameWithoutExtension(filename);
        final String extension = p.extension(filename);
        final String path = await downloadsDirectory;

        file = File('$path/$filename');
        for (int i = 1; await file!.exists(); ++i) {
          file = File('$path/$name ($i)$extension');
        }

        // Retry the downloading unless any other that `404` error is thrown.
        await withBackoff(
          () async {
            try {
              await Dio().download(
                url,
                file!.path,
                onReceiveProgress: onReceiveProgress,
                cancelToken: cancelToken,
              );
            } on DioError catch (e) {
              if (e.response?.statusCode == 404) {
                rethrow;
              }
            } catch (_) {
              // No-op.
            }
          },
        );
      }

      return file;
    }
  }

  /// Downloads an image from the provided [url] and saves it to the gallery.
  Future<void> saveToGallery(String url, String name) async {
    if (isMobile && !isWeb) {
      final Directory temp = await getTemporaryDirectory();
      final String path = '${temp.path}/$name';
      await Dio().download(url, path);
      await ImageGallerySaver.saveFile(path, name: name);
      File(path).delete();
    }
  }

  /// Downloads a file from the provided [url] and opens [Share] dialog with it.
  Future<void> share(String url, String name) async {
    final Directory temp = await getTemporaryDirectory();
    final String path = '${temp.path}/$name';
    await Dio().download(url, path);
    await Share.shareFiles([path]);
    File(path).delete();
  }
}

/// Determining whether a [BuildContext] is mobile or not.
extension MobileExtensionOnContext on BuildContext {
  /// Returns `true` if [MediaQuery]'s width is less than `600p` on desktop and
  /// [MediaQuery]'s shortest side is less than `600p` on mobile.
  bool get isMobile => PlatformUtils.isDesktop
      ? MediaQuery.of(this).size.width < 600
      : MediaQuery.of(this).size.shortestSide < 600;
}

/// Listener interface for receiving window events.
class _WindowListener extends WindowListener {
  _WindowListener({
    required this.onLeaveFullscreen,
    required this.onEnterFullscreen,
  });

  /// Callback, called when the window exits fullscreen.
  final VoidCallback onLeaveFullscreen;

  /// Callback, called when the window enters fullscreen.
  final VoidCallback onEnterFullscreen;

  @override
  void onWindowEnterFullScreen() => onEnterFullscreen();

  @override
  void onWindowLeaveFullScreen() => onLeaveFullscreen();
}
