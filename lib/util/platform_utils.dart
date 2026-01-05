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
import 'dart:io';
import 'dart:ui';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:async/async.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_custom_cursor/cursor_manager.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart' hide Response;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:macos_haptic_feedback/macos_haptic_feedback.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_taskbar/windows_taskbar.dart';
import 'package:xdg_directories/xdg_directories.dart';

import '/config.dart';
import '/domain/model/native_file.dart';
import '/pubspec.g.dart';
import '/routes.dart';
import '/ui/worker/cache.dart';
import '/util/log.dart';
import 'backoff.dart';
import 'web/web_utils.dart';

/// Global variable to access [PlatformUtilsImpl].
///
/// May be reassigned to mock specific functionally.
// ignore: non_constant_identifier_names
PlatformUtilsImpl PlatformUtils = PlatformUtilsImpl();

/// Helper providing platform related features.
class PlatformUtilsImpl {
  PlatformUtilsImpl() {
    Timer.periodic(Duration(milliseconds: 2000), (_) {
      if (_lastDeltaPing != null) {
        final difference = DateTime.now()
            .difference(_lastDeltaPing!)
            .abs()
            .inMilliseconds;

        isDeltaSynchronized.value = difference <= 2200;
      }

      _lastDeltaPing = DateTime.now();
    });
  }

  /// [Dio] client to use in queries.
  ///
  /// May be overridden to be mocked in tests.
  Dio? client;

  /// Indicator whether the device is asleep.
  final RxBool isDeltaSynchronized = RxBool(true);

  /// [Timer] updating the [_isActive] status after the [_activityTimeout] has
  /// passed.
  @visibleForTesting
  Timer? activityTimer;

  /// Downloads directory.
  Directory? _downloadDirectory;

  /// Cache directory.
  Directory? _cacheDirectory;

  /// Temporary directory.
  Directory? _temporaryDirectory;

  /// Library directory.
  Directory? _libraryDirectory;

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

  /// Last [DateTime] of a [isDeltaSynchronized] timer.
  DateTime? _lastDeltaPing;

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

  /// Indicates whether device is running on a Firebase Cloud Messaging
  /// supported OS, meaning it supports receiving push notifications.
  bool get pushNotifications => isWeb || isMobile;

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
  Future<Directory> get downloadsDirectory async {
    if (_downloadDirectory != null) {
      return _downloadDirectory!;
    }

    String path;
    if (PlatformUtils.isMobile) {
      path = (await getTemporaryDirectory()).path;
    } else {
      path = (await getDownloadsDirectory())!.path;
    }

    _downloadDirectory = Directory('$path${Config.downloads}');
    return _downloadDirectory!;
  }

  /// Returns a path to the cache directory.
  FutureOr<Directory?> get cacheDirectory async {
    if (PlatformUtils.isWeb) {
      return null;
    }

    try {
      _cacheDirectory ??= await getApplicationCacheDirectory();
      return _cacheDirectory!;
    } on MissingPluginException {
      return null;
    }
  }

  /// Returns a path to the temporary directory.
  FutureOr<Directory> get temporaryDirectory {
    if (_temporaryDirectory != null) {
      return _temporaryDirectory!;
    }

    return Future(() async {
      _temporaryDirectory = Directory(
        '${(await getTemporaryDirectory()).path}${Config.downloads}',
      );
      return _temporaryDirectory!;
    });
  }

  /// Returns a path to the library directory.
  ///
  /// Should be used to put local storage files and caches that aren't temporal.
  FutureOr<Directory> get libraryDirectory async {
    if (_libraryDirectory != null) {
      return _libraryDirectory!;
    }

    Directory? directory;

    try {
      if (isLinux) {
        directory ??= dataHome;
      } else {
        directory ??= await getLibraryDirectory();
      }
    } on MissingPluginException {
      directory = Directory('');
    } catch (_) {
      directory ??= await cacheDirectory;
      directory ??= await getApplicationDocumentsDirectory();
    }

    // Windows already contains both product name and company name in the path.
    //
    // Android already contains the bundle identifier in the path.
    if (PlatformUtils.isWindows || PlatformUtils.isAndroid) {
      return directory;
    }

    return Directory('${directory.path}/${Config.userAgentProduct}');
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
    bool temporary = false,
  }) async {
    if ((size != null || url != null) && !PlatformUtils.isWeb) {
      if (size == null) {
        final Headers headers = (await (await dio).head(url!)).headers;
        final List<String>? contentLength = headers['content-length'];

        if (contentLength != null) {
          size = int.parse((contentLength)[0]);
        }
      }

      final Directory directory = temporary
          ? await temporaryDirectory
          : await downloadsDirectory;
      String name = p.basenameWithoutExtension(filename);
      String ext = p.extension(filename);
      File file = File('${directory.path}/$filename');

      // TODO: Compare hashes instead of sizes.
      for (int i = 1; await file.exists() && await file.length() != size; ++i) {
        file = File('${directory.path}/$name ($i)$ext');
      }

      if (await file.exists()) {
        return file;
      }
    }

    return null;
  }

  /// Downloads a file by provided [url] using `save as` dialog.
  ///
  /// [onReceiveProgress] is only meaningful on non-Web platforms.
  Future<File?> saveTo(
    String url, {
    Function(int count, int total)? onReceiveProgress,
  }) async {
    String? to;

    if (!isWeb) {
      to = await FilePicker.platform.saveFile(
        fileName: url.split('/').lastOrNull ?? 'file',
        lockParentWindow: true,
      );

      if (to == null) {
        return null;
      }
    }

    return await download(
      url,
      url.split('/').lastOrNull ?? 'file',
      null,
      path: to,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Downloads a file from the provided [url].
  Future<File?> download(
    String url,
    String filename,
    int? size, {
    String? path,
    String? checksum,
    Function(int count, int total)? onReceiveProgress,
    CancelToken? cancelToken,
    bool temporary = false,
    int retries = 5,
  }) async {
    dynamic completeWith;
    int tries = 0;

    CancelableOperation<File?>? operation;
    operation = CancelableOperation.fromFuture(
      Future(() async {
        // Rethrows the [exception], if any other than `404` is thrown.
        void onError(dynamic exception) {
          if (exception is! DioException ||
              exception.response?.statusCode != 404) {
            completeWith = exception;
            operation?.cancel();
          } else {
            ++tries;

            if (tries <= retries) {
              // Continue the [Backoff.run] re-trying.
              throw exception;
            }
          }
        }

        if (PlatformUtils.isWeb) {
          await Backoff.run(() async {
            try {
              await WebUtils.downloadFile(url, filename);
            } catch (e) {
              onError(e);
            }
          }, cancel: cancelToken);
        } else {
          File? file;

          if (path == null) {
            // Retry fetching the size unless any other that `404` error is
            // thrown.
            file = await Backoff.run(() async {
              try {
                return await fileExists(
                  filename,
                  size: size,
                  url: url,
                  temporary: temporary,
                );
              } catch (e) {
                onError(e);
              }

              return null;
            }, cancel: cancelToken);
          }

          if (file == null) {
            Uint8List? data;
            if (checksum != null && CacheWorker.instance.exists(checksum)) {
              data = (await CacheWorker.instance.get(checksum: checksum)).bytes;
            }

            if (path == null) {
              final String name = p.basenameWithoutExtension(filename);
              final String extension = p.extension(filename);
              final Directory directory = temporary
                  ? await temporaryDirectory
                  : await downloadsDirectory;

              file = File('${directory.path}/$filename');
              for (int i = 1; await file!.exists(); ++i) {
                file = File('${directory.path}/$name ($i)$extension');
              }
            } else {
              file = File(path);
            }

            if (data == null) {
              // Retry the downloading unless any other that `404` error is
              // thrown.
              await Backoff.run(() async {
                try {
                  // TODO: Cache the response.
                  await (await dio).download(
                    url,
                    file!.path,
                    onReceiveProgress: onReceiveProgress,
                    cancelToken: cancelToken,
                  );
                } catch (e) {
                  onError(e);
                }
              }, cancel: cancelToken);
            } else {
              await file.writeAsBytes(data);
            }
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

  /// Downloads a video or an image from the provided [url] and saves it to the
  /// gallery.
  Future<void> saveToGallery(
    String url,
    String name, {
    String? checksum,
    int? size,
    bool isImage = false,
  }) async {
    if (isImage) {
      // SVGs can not be saved to the gallery.
      if (name.endsWith('.svg')) {
        throw UnsupportedError('SVGs are not supported in gallery.');
      }

      final CacheEntry cache = await CacheWorker.instance.get(
        url: url,
        checksum: checksum,
      );

      await ImageGallerySaver.saveImage(cache.bytes!, name: name);
    } else {
      final File? file = await PlatformUtils.download(
        url,
        name,
        size,
        checksum: checksum,
        temporary: true,
      );

      await ImageGallerySaver.saveFile(file!.path, name: name);
    }
  }

  /// Downloads a file from the provided [url] and opens [SharePlus] dialog with
  /// it.
  Future<void> share(String url, String name, {String? checksum}) async {
    // Provided file might already be cached.
    Uint8List? data;
    if (checksum != null && CacheWorker.instance.exists(checksum)) {
      data = (await CacheWorker.instance.get(checksum: checksum)).bytes;
    }

    if (data == null) {
      final Directory temp = await getTemporaryDirectory();
      final String path = '${temp.path}/$name';
      await (await dio).download(url, path);
      await SharePlus.instance.share(ShareParams(files: [XFile(path)]));

      File(path).delete();
    } else {
      await SharePlus.instance.share(
        ShareParams(files: [XFile.fromData(data, name: name)]),
      );
    }
  }

  /// Stores the provided [text] or [data] on the [Clipboard].
  Future<void> copy({
    String? text,
    SimpleFileFormat? format,
    Uint8List? data,
  }) async {
    if (text != null) {
      await Clipboard.setData(ClipboardData(text: text));
    } else if (data != null && format != null) {
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        return;
      }

      String? extension =
          (format.mimeTypes?.lastOrNull ?? format.fallbackFormats.lastOrNull)
              ?.split('/')
              .last;
      extension ??= '.bin';

      final String suggestedName =
          '${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Web's Clipboard API support only `text/plain`, `text/html` and
      // `image/png`, thus always try to encode image as PNG.
      if (isWeb) {
        try {
          final Codec decoded = await instantiateImageCodec(data);
          final FrameInfo frame = await decoded.getNextFrame();

          try {
            final ByteData? png = await frame.image.toByteData(
              format: ImageByteFormat.png,
            );

            if (png != null) {
              final item = DataWriterItem(suggestedName: suggestedName);
              item.add(
                Formats.png(
                  png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
                ),
              );
              await clipboard.write([item]);
            }
          } finally {
            // This object must be disposed by the recipient of the frame info.
            frame.image.dispose();
          }

          return;
        } catch (e) {
          rethrow;
        }
      }

      final item = DataWriterItem(suggestedName: suggestedName);
      item.add(format(data));
      await clipboard.write([item]);
    }
  }

  /// Keeps the [_isActive] status as [active].
  void keepActive([bool active = true]) {
    if (_isActive != active) {
      _isActive = active;
      _activityController?.add(active);
    }

    activityTimer?.cancel();

    if (active) {
      activityTimer = Timer(_activityTimeout, () {
        _isActive = false;
        _activityController?.add(false);
      });
    }
  }

  /// Returns the [FilePickerResult] of the file picking of the provided [type].
  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    List<String>? allowedExtensions,
  }) async {
    try {
      FileType accounted = type;
      if (type == FileType.custom && isMobile) {
        if (allowedExtensions == NativeFile.images) {
          accounted = FileType.image;
          allowedExtensions = null;
        }
      }

      return await FilePicker.platform.pickFiles(
        type: accounted,
        compressionQuality: compressionQuality,
        allowMultiple: allowMultiple,
        withData: withData,
        withReadStream: withReadStream,
        lockParentWindow: lockParentWindow,
        allowedExtensions: accounted == FileType.custom
            ? allowedExtensions
            : null,
      );
    } on PlatformException catch (e) {
      if (e.code == 'already_active') {
        return null;
      } else {
        rethrow;
      }
    }
  }

  /// Provides a haptic feedback of the provided [kind].
  Future<void> haptic({HapticKind kind = HapticKind.click}) async {
    if (PlatformUtils.isMacOS && !PlatformUtils.isWeb) {
      switch (kind) {
        case HapticKind.click:
          await MacosHapticFeedback().generic();
          break;

        case HapticKind.light:
          await MacosHapticFeedback().alignment();
          break;
      }
    } else {
      switch (kind) {
        case HapticKind.click:
          await HapticFeedback.selectionClick();
          break;

        case HapticKind.light:
          await HapticFeedback.lightImpact();
          break;
      }
    }
  }

  /// Retrieves a [String] from the asset bundle.
  ///
  /// Caches the response with the current [Pubspec.ref] version.
  Future<String> loadString(String asset) async {
    String? contents;

    // Browser may cache the GET request too persistent, even when the file is
    // indeed changed.
    if (PlatformUtils.isWeb) {
      try {
        final response = await (await (PlatformUtils.dio)).get(
          '${Config.origin}/assets/$asset?${Pubspec.ref}',
          options: Options(responseType: ResponseType.plain),
        );

        if (response.data is String) {
          contents = response.data as String;
        }
      } catch (_) {
        // No-op.
      }
    }

    return contents ?? await rootBundle.loadString(asset);
  }

  /// Retrieves a [ByteData] from the asset bundle.
  ///
  /// Caches the response with the current [Pubspec.ref] version.
  Future<ByteData> loadBytes(String asset) async {
    ByteData? contents;

    // Browser may cache the GET request too persistent, even when the file is
    // indeed changed.
    if (PlatformUtils.isWeb) {
      try {
        final response = await (await (PlatformUtils.dio)).get(
          '${Config.origin}/assets/$asset?${Pubspec.ref}',
          options: Options(responseType: ResponseType.bytes),
        );

        if (response.data is List<int>) {
          contents = ByteData.sublistView(
            Uint8List.fromList(response.data as List<int>),
          );
        }
      } catch (_) {
        // No-op.
      }
    }

    return contents ?? (await rootBundle.load(asset));
  }

  /// Forms and downloads the provided [bytes] as a file.
  Future<File?> createAndDownload(String name, Uint8List bytes) async {
    if (isWeb) {
      await WebUtils.downloadBlob(name, bytes);
      return null;
    }

    String? to;

    if (PlatformUtils.isDesktop) {
      to = await FilePicker.platform.saveFile(
        fileName: name,
        lockParentWindow: true,
      );
    } else {
      to = '${(await temporaryDirectory).path}/$name';
    }

    if (to != null) {
      final File file = File(to);
      await file.writeAsBytes(bytes);
      return file;
    }

    return null;
  }

  /// Refreshes the current browser's page.
  Future<void> setAppBadge(int count) async {
    Log.debug('setAppBadge($count)', '$runtimeType');

    if (isWeb) {
      return WebUtils.setBadge(count);
    }

    if (isWindows) {
      try {
        if (count == 0) {
          await WindowsTaskbar.resetOverlayIcon();
        } else {
          final String number = count > 9 ? '9+' : '$count';
          await WindowsTaskbar.setOverlayIcon(
            ThumbnailToolbarAssetIcon('assets/icons/notification/$number.ico'),
          );
        }
      } catch (_) {
        // No-op.
      }
    }

    try {
      if (await AppBadgePlus.isSupported()) {
        await AppBadgePlus.updateBadge(count);
      }
    } catch (_) {
      // No-op.
    }
  }

  /// Opens a directory containing the provided [File].
  ///
  /// If directory cannot be opened (for example, on Android or iOS), then opens
  /// the [File] itself.
  Future<void> openDirectoryOrFile(File file) async {
    if (PlatformUtils.isWeb) {
      // Web doesn't allow that.
      return;
    }

    if (PlatformUtils.isWindows) {
      // `explorer` is always included on Windows.
      await Process.start('explorer', ['/select,', p.normalize(file.path)]);
    } else if (PlatformUtils.isMacOS) {
      // `open` is always included on macOS.
      await Process.start('open', ['-R', p.normalize(file.path)]);
    } else if (PlatformUtils.isLinux) {
      // `xdg-open` seems to be installed by default in a large amount of
      // distros, thus we may rely on it installed on the user's machine.
      await Process.start('xdg-open', [p.normalize(file.parent.path)]);
    } else {
      await OpenFile.open(file.path);
    }
  }
}

/// Kind of a [PlatformUtilsImpl.haptic] feedback.
enum HapticKind { click, light }

/// Determining whether a [BuildContext] is mobile or not.
extension MobileExtensionOnContext on BuildContext {
  /// Returns `true` if [PlatformUtilsImpl.isMobile] and [MediaQuery]'s shortest
  /// side is less than `600p`, or otherwise always returns `false`.
  bool get isMobile => PlatformUtils.isMobile
      ? MediaQuery.sizeOf(this).shortestSide < 600
      : false;

  /// Returns `true` if [MediaQuery]'s width is less than `600p` on desktop and
  /// [MediaQuery]'s shortest side is less than `600p` on mobile.
  bool get isNarrow => PlatformUtils.isDesktop
      ? MediaQuery.sizeOf(this).width < 600
      : MediaQuery.sizeOf(this).shortestSide < 600;

  /// Returns `true` if [MediaQuery]'s width is less than `379p` on desktop and
  /// [MediaQuery]'s shortest side is less than `379p` on mobile.
  bool get isTiny => PlatformUtils.isDesktop
      ? MediaQuery.sizeOf(this).width < 379
      : MediaQuery.sizeOf(this).shortestSide < 379;
}

/// Extension adding an ability to pop the current [ModalRoute].
extension PopExtensionOnContext on BuildContext {
  /// Pops the [ModalRoute] from this [BuildContext], if any is active.
  void popModal([dynamic result]) {
    if (mounted) {
      final NavigatorState navigator = Navigator.of(this);
      final ModalRoute? modal = ModalRoute.of(this);

      if (modal?.isActive == true) {
        if (modal?.isCurrent == true) {
          navigator.pop(result);
        } else {
          navigator.removeRoute(modal!);
        }
      }
    }
  }
}

/// Helper defining custom [MouseCursor]s.
class CustomMouseCursors {
  /// Indicator whether these [CustomMouseCursors] are initialized.
  static bool _initialized = false;

  /// Returns a grab [MouseCursor].
  static MouseCursor get grab {
    if (PlatformUtils.isWindows && !PlatformUtils.isWeb) {
      return const FlutterCustomMemoryImageCursor(key: 'grab');
    }

    return SystemMouseCursors.grab;
  }

  /// Returns a grabbing [MouseCursor].
  static MouseCursor get grabbing {
    if (PlatformUtils.isWindows && !PlatformUtils.isWeb) {
      return const FlutterCustomMemoryImageCursor(key: 'grabbing');
    }

    return SystemMouseCursors.grabbing;
  }

  /// Returns a resize up-left down-right [MouseCursor].
  static MouseCursor get resizeUpLeftDownRight {
    if (PlatformUtils.isMacOS && !PlatformUtils.isWeb) {
      return const FlutterCustomMemoryImageCursor(key: 'resizeUpLeftDownRight');
    }

    return SystemMouseCursors.resizeUpLeftDownRight;
  }

  /// Returns a resize up-right down-left [MouseCursor].
  static MouseCursor get resizeUpRightDownLeft {
    if (PlatformUtils.isMacOS && !PlatformUtils.isWeb) {
      return const FlutterCustomMemoryImageCursor(key: 'resizeUpRightDownLeft');
    }

    return SystemMouseCursors.resizeUpRightDownLeft;
  }

  /// Ensures these [CustomMouseCursors] are initialized.
  static Future<void> ensureInitialized() async {
    if (!_initialized) {
      _initialized = true;

      if (!PlatformUtils.isWeb) {
        if (PlatformUtils.isWindows) {
          await _initCursor('assets/images/grab.bgra', 'grab');
          await _initCursor('assets/images/grabbing.bgra', 'grabbing');
        } else if (PlatformUtils.isMacOS) {
          await _initCursor(
            'assets/images/resizeUpLeftDownRight.png',
            'resizeUpLeftDownRight',
            width: 15,
            height: 15,
          );
          await _initCursor(
            'assets/images/resizeUpRightDownLeft.png',
            'resizeUpRightDownLeft',
            width: 15,
            height: 15,
          );
        }
      }
    }
  }

  /// Registers a custom [MouseCursor] from the provided [path] and [name].
  static Future<void> _initCursor(
    String path,
    String name, {
    double width = 30,
    double height = 30,
  }) async {
    try {
      final ByteData bytes = await rootBundle.load(path);

      await CursorManager.instance.registerCursor(
        CursorData()
          ..name = name
          ..buffer = bytes.buffer.asUint8List()
          ..height = height.round()
          ..width = width.round()
          ..hotX = width / 2
          ..hotY = height / 2,
      );
    } catch (e) {
      Log.warning(
        'Failed to initialize `$name` cursor due to: $e',
        'CustomMouseCursors',
      );
    }
  }
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
