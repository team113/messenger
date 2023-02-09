import 'dart:async';

import 'package:collection/collection.dart';
import 'package:medea_jason/medea_jason.dart';

/// Helper providing direct access to media related resources like media
/// devices, media tracks, etc.
class MediaUtils {
  static Jason? _jason;
  static MediaManagerHandle? _mediaManager;
  static StreamController<List<MediaDeviceInfo>>? _devicesController;

  static Jason? get jason {
    _jason ??= Jason();
    return _jason;
  }

  static MediaManagerHandle? get mediaManager {
    _mediaManager ??= jason?.mediaManager();
    return _mediaManager;
  }

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

  static Future<List<MediaDeviceInfo>> enumerateDevices([
    MediaDeviceKind? kind,
  ]) async {
    return (await mediaManager?.enumerateDevices() ?? [])
        .whereNot((e) => e.deviceId().isEmpty)
        .where((e) => kind == null || e.kind() == kind)
        .toList();
  }
}
