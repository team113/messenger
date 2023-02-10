import 'dart:async';

import 'package:collection/collection.dart';
import 'package:medea_jason/medea_jason.dart';

/// Helper providing direct access to media related resources like media
/// devices, media tracks, etc.
class MediaUtils {
  /// [Jason] communicating with the media resources.
  static Jason? _jason;

  /// [MediaManagerHandle] maintaining the media devices.
  static MediaManagerHandle? _mediaManager;

  /// [StreamController] of the [MediaDeviceInfo]s updating in the
  /// [MediaManagerHandle.onDeviceChange].
  static StreamController<List<MediaDeviceInfo>>? _devicesController;

  /// Returns the [Jason] instance of these [MediaUtils].
  static Jason? get jason {
    _jason ??= Jason();
    return _jason;
  }

  /// Returns the [MediaManagerHandle] instance of these [MediaUtils].
  static MediaManagerHandle? get mediaManager {
    _mediaManager ??= jason?.mediaManager();
    return _mediaManager;
  }

  /// Returns a [Stream] of the [MediaDeviceInfo]s changes.
  static Stream<List<MediaDeviceInfo>> get onDeviceChange {
    if (_devicesController == null) {
      _devicesController = StreamController.broadcast();
      mediaManager?.onDeviceChange(() async {
        print('_devicesController!.add');
        _devicesController!.add(
          (await mediaManager?.enumerateDevices() ?? [])
              .whereNot((e) => e.deviceId().isEmpty)
              .toList(),
        );
      });
    }

    return _devicesController!.stream;
  }

  /// Returns the [MediaDeviceInfo]s currently available with the provided
  /// [kind], if specified.
  static Future<List<MediaDeviceInfo>> enumerateDevices([
    MediaDeviceKind? kind,
  ]) async {
    return (await mediaManager?.enumerateDevices() ?? [])
        .whereNot((e) => e.deviceId().isEmpty)
        .where((e) => kind == null || e.kind() == kind)
        .toList();
  }
}
