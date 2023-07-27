import 'package:audioplayers/audioplayers.dart';

import '/domain/service/disposable_service.dart';

class AudioWorker extends DisposableService {
  Future<AudioResource?> play(AudioSource source) async {
    final AudioPlayer player = AudioPlayer();
    await player.play(source.source);

    return AudioResource();
  }
}

class AudioResource {
  final AudioPlayer player = AudioPlayer();

  void dispose() {}
}

enum AudioSourceKind { asset, file, url }

abstract class AudioSource {
  const AudioSource();

  factory AudioSource.asset(String asset) = AssetAudioSource;
  factory AudioSource.file(String file) = FileAudioSource;
  factory AudioSource.url(String url) = UrlAudioSource;

  AudioSourceKind get kind;
}

class AssetAudioSource extends AudioSource {
  const AssetAudioSource(this.asset);

  final String asset;

  @override
  AudioSourceKind get kind => AudioSourceKind.asset;
}

class FileAudioSource extends AudioSource {
  const FileAudioSource(this.file);

  final String file;

  @override
  AudioSourceKind get kind => AudioSourceKind.file;
}

class UrlAudioSource extends AudioSource {
  const UrlAudioSource(this.url);

  final String url;

  @override
  AudioSourceKind get kind => AudioSourceKind.url;
}

extension on AudioSource {
  Source get source => switch (kind) {
        AudioSourceKind.asset => AssetSource((this as AssetAudioSource).asset),
        AudioSourceKind.file =>
          DeviceFileSource((this as FileAudioSource).file),
        AudioSourceKind.url => UrlSource((this as UrlAudioSource).url),
      };
}
