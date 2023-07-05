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
import 'dart:io';

import 'package:async/async.dart';
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
import '/routes.dart';
import 'backoff.dart';
import 'web/web_utils.dart';

/// Global variable to access [PlatformUtilsImpl].
///
/// May be reassigned to mock specific functionally.
// ignore: non_constant_identifier_names
PlatformUtilsImpl PlatformUtils = PlatformUtilsImpl();

/// Helper providing platform related features.
class PlatformUtilsImpl {
  /// [Dio] client to use in queries.
  ///
  /// May be overridden to be mocked in tests.
  Dio? client;

  /// Path to the downloads directory.
  String? _downloadDirectory;

  /// `User-Agent` header to put in the network requests.
  String? _userAgent;

  /// Returns a [Dio] client to use in queries.
  Future<Dio> get dio async {
    client ??= Dio(
      BaseOptions(headers: {if (!isWeb) 'User-Agent': await userAgent}),
    );

    return client!;
  }

  /// [StreamController] of the application's [_isActive] status changes.
  StreamController<bool>? _activityController;

  /// [StreamController] of the application's window focus changes.
  StreamController<bool>? _focusController;

  /// Indicator whether the application is in active state.
  bool _isActive = true;

  /// [Timer] updating the [_isActive] status after the [_activityTimeout] has
  /// passed.
  Timer? _activityTimer;

  /// [Duration] of inactivity to consider [_isActive] as `false`.
  static const Duration _activityTimeout = Duration(seconds: 15);

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

  /// Returns a `User-Agent` header to put in the network requests.
  Future<String> get userAgent async {
    _userAgent ??= await WebUtils.userAgent;
    return _userAgent!;
  }

  /// Returns a stream broadcasting the application's window focus changes.
  Stream<bool> get onFocusChanged {
    if (_focusController != null) {
      return _focusController!.stream;
    }

    if (isWeb) {
      return WebUtils.onFocusChanged;
    } else if (isDesktop) {
      _WindowListener listener = _WindowListener(
        onBlur: () => _focusController!.add(false),
        onFocus: () => _focusController!.add(true),
      );

      _focusController = StreamController<bool>.broadcast(
        onListen: () => WindowManager.instance.addListener(listener),
        onCancel: () {
          WindowManager.instance.removeListener(listener);
          _focusController?.close();
          _focusController = null;
        },
      );
    } else {
      Worker? worker;

      _focusController = StreamController<bool>.broadcast(
        onListen: () => worker = ever(
          router.lifecycle,
          (AppLifecycleState a) => _focusController?.add(a.inForeground),
        ),
        onCancel: () {
          worker?.dispose();
          _focusController?.close();
          _focusController = null;
        },
      );
    }

    return _focusController!.stream;
  }

  /// Returns a stream broadcasting the application's active status changes.
  Stream<bool> get onActivityChanged {
    if (_activityController != null) {
      return _activityController!.stream;
    }

    StreamSubscription? focusSubscription;

    _activityController = StreamController<bool>.broadcast(
      onListen: () {
        focusSubscription = onFocusChanged.listen((focused) {
          if (focused) {
            keepActive();
          } else {
            keepActive(false);
          }
        });
      },
      onCancel: () {
        focusSubscription?.cancel();
        _activityController?.close();
        _activityController = null;
      },
    );

    return _activityController!.stream;
  }

  /// Returns a stream broadcasting the application's window size changes.
  Stream<MapEntry<Size, Offset>> get onResized {
    StreamController<MapEntry<Size, Offset>>? controller;

    final _WindowListener listener = _WindowListener(
      onResized: (pair) => controller!.add(pair),
    );

    controller = StreamController<MapEntry<Size, Offset>>(
      onListen: () => WindowManager.instance.addListener(listener),
      onCancel: () => WindowManager.instance.removeListener(listener),
    );

    return controller.stream;
  }

  /// Returns a stream broadcasting the application's window position changes.
  Stream<Offset> get onMoved {
    StreamController<Offset>? controller;

    final _WindowListener listener = _WindowListener(
      onMoved: (position) => controller!.add(position),
    );

    controller = StreamController<Offset>(
      onListen: () => WindowManager.instance.addListener(listener),
      onCancel: () => WindowManager.instance.removeListener(listener),
    );

    return controller.stream;
  }

  /// Indicates whether the application's window is in focus.
  Future<bool> get isFocused async {
    if (isWeb) {
      return Future.value(WebUtils.isFocused);
    } else if (isDesktop) {
      try {
        return await WindowManager.instance.isFocused();
      } on MissingPluginException {
        return true;
      }
    } else {
      return Future.value(router.lifecycle.value.inForeground);
    }
  }

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

  /// Indicates whether the application is in active state.
  Future<bool> get isActive async => _isActive && await isFocused;

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
          int.parse(((await (await dio).head(url!)).headers['content-length']
              as List<String>)[0]);

      String downloads = await PlatformUtils.downloadsDirectory;
      String name = p.basenameWithoutExtension(filename);
      String ext = p.extension(filename);
      File file = File('$downloads/$filename');

      // TODO: Compare hashes instead of sizes.
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
  Future<File?> download(
    String url,
    String filename,
    int? size, {
    Function(int count, int total)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    dynamic completeWith;

    CancelableOperation<File?>? operation;
    operation = CancelableOperation.fromFuture(
      Future(() async {
        // Rethrows the [exception], if any other than `404` is thrown.
        void onError(dynamic exception) {
          if (exception is! DioError || exception.response?.statusCode != 404) {
            completeWith = exception;
            operation?.cancel();
          }
        }

        if (PlatformUtils.isWeb) {
          await Backoff.run(
            () async {
              try {
                await WebUtils.downloadFile(url, filename);
              } catch (e) {
                onError(e);
              }
            },
            cancelToken,
          );
        } else {
          File? file;

          // Retry fetching the size unless any other that `404` error is
          // thrown.
          file = await Backoff.run(
            () async {
              try {
                return await fileExists(filename, size: size, url: url);
              } catch (e) {
                onError(e);
              }

              return null;
            },
            cancelToken,
          );

          if (file == null) {
            final String name = p.basenameWithoutExtension(filename);
            final String extension = p.extension(filename);
            final String path = await downloadsDirectory;

            file = File('$path/$filename');
            for (int i = 1; await file!.exists(); ++i) {
              file = File('$path/$name ($i)$extension');
            }

            // Retry the downloading unless any other that `404` error is
            // thrown.
            await Backoff.run(
              () async {
                try {
                  await (await dio).download(
                    url,
                    file!.path,
                    onReceiveProgress: onReceiveProgress,
                    cancelToken: cancelToken,
                  );
                } catch (e) {
                  onError(e);
                }
              },
              cancelToken,
            );
          }

          return file;
        }

        return null;
      }),
    );

    cancelToken?.whenCancel.whenComplete(operation.cancel);

    final File? result = await operation.valueOrCancellation();
    if (completeWith != null) {
      throw completeWith;
    }

    return result;
  }

  /// Downloads an image from the provided [url] and saves it to the gallery.
  Future<void> saveToGallery(String url, String name) async {
    if (isMobile && !isWeb) {
      final Directory temp = await getTemporaryDirectory();
      final String path = '${temp.path}/$name';
      await (await dio).download(url, path);
      await ImageGallerySaver.saveFile(path, name: name);
      File(path).delete();
    }
  }

  /// Downloads a file from the provided [url] and opens [Share] dialog with it.
  Future<void> share(String url, String name) async {
    final Directory temp = await getTemporaryDirectory();
    final String path = '${temp.path}/$name';
    await (await dio).download(url, path);
    await Share.shareXFiles([XFile(path)]);
    File(path).delete();
  }

  /// Stores the provided [text] on the [Clipboard].
  void copy({required String text}) =>
      Clipboard.setData(ClipboardData(text: text));

  /// Keeps the [_isActive] status as [active].
  void keepActive([bool active = true]) {
    _isActive = active;
    _activityController?.add(active);

    _activityTimer?.cancel();

    if (active) {
      _activityTimer = Timer(_activityTimeout, () {
        _isActive = false;
        _activityController?.add(false);
      });
    }
  }
}

/// Determining whether a [BuildContext] is mobile or not.
extension MobileExtensionOnContext on BuildContext {
  /// Returns `true` if [PlatformUtilsImpl.isMobile] and [MediaQuery]'s shortest
  /// side is less than `600p`, or otherwise always returns `false`.
  bool get isMobile => PlatformUtils.isMobile
      ? MediaQuery.of(this).size.shortestSide < 600
      : false;

  /// Returns `true` if [MediaQuery]'s width is less than `600p` on desktop and
  /// [MediaQuery]'s shortest side is less than `600p` on mobile.
  bool get isNarrow => PlatformUtils.isDesktop
      ? MediaQuery.of(this).size.width < 600
      : MediaQuery.of(this).size.shortestSide < 600;
}

/// Listener interface for receiving window events.
class _WindowListener extends WindowListener {
  _WindowListener({
    this.onLeaveFullscreen,
    this.onEnterFullscreen,
    this.onFocus,
    this.onBlur,
    this.onResized,
    this.onMoved,
  });

  /// Callback, called when the window exits fullscreen.
  final VoidCallback? onLeaveFullscreen;

  /// Callback, called when the window enters fullscreen.
  final VoidCallback? onEnterFullscreen;

  /// Callback, called when the window gets focus.
  final VoidCallback? onFocus;

  /// Callback, called when the window loses focus.
  final VoidCallback? onBlur;

  /// Callback, called when the window resizes.
  final void Function(MapEntry<Size, Offset> pair)? onResized;

  /// Callback, called when the window moves.
  final void Function(Offset offset)? onMoved;

  @override
  void onWindowEnterFullScreen() => onEnterFullscreen?.call();

  @override
  void onWindowLeaveFullScreen() => onLeaveFullscreen?.call();

  @override
  void onWindowFocus() => onFocus?.call();

  @override
  void onWindowBlur() => onBlur?.call();

  @override
  void onWindowResized() async => onResized?.call(
        MapEntry<Size, Offset>(
          await windowManager.getSize(),
          await windowManager.getPosition(),
        ),
      );

  @override
  void onWindowMoved() async =>
      onMoved?.call(await windowManager.getPosition());
}
