import 'dart:async';

import 'package:collection/collection.dart';
import 'package:medea_jason/medea_jason.dart';

import 'log.dart';

/// Helper providing direct access to media related resources like media
/// devices, media tracks, etc.
class MediaUtils {
  /// [Jason] communicating with the media resources.
  static Jason? _jason;

  /// [MediaManagerHandle] maintaining the media devices.
  static MediaManagerHandle? _mediaManager;

  /// [StreamController] of the [MediaDeviceDetails]s updating in the
  /// [MediaManagerHandle.onDeviceChange].
  static StreamController<List<MediaDeviceDetails>>? _devicesController;

  /// Returns the [Jason] instance of these [MediaUtils].
  static Jason? get jason {
    if (_jason == null) {
      _jason = Jason();
      onPanic((e) {
        Log.print('Panic: $e', 'Jason');
        _jason = null;
        _mediaManager = null;
      });
    }

    return _jason;
  }

  /// Returns the [MediaManagerHandle] instance of these [MediaUtils].
  static MediaManagerHandle? get mediaManager {
    _mediaManager ??= jason?.mediaManager();
    return _mediaManager;
  }

  /// Returns a [Stream] of the [MediaDeviceDetails]s changes.
  static Stream<List<MediaDeviceDetails>> get onDeviceChange {
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

  /// Returns the [MediaDeviceDetails]s currently available with the provided
  /// [kind], if specified.
  static Future<List<MediaDeviceDetails>> enumerateDevices([
    MediaDeviceKind? kind,
  ]) async {
    return (await mediaManager?.enumerateDevices() ?? [])
        .whereNot((e) => e.deviceId().isEmpty)
        .where((e) => kind == null || e.kind() == kind)
        .toList();
  }
}
