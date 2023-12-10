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
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import '/config.dart';
import '/themes.dart';
import '/ui/page/auth/widget/cupertino_button.dart';
import '/ui/widget/widget_button.dart';
import '/util/audio_utils.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

class AudioPlayer extends StatefulWidget {

  /// Optional height this [AudioPlayer] occupies.
  final double? height;

  /// Optional width this [AudioPlayer] occupies.
  final double? width;

  /// Callback, called on the video loading errors.
  final Future<void> Function()? onError;

  /// Constructs a [AudioPlayer] from the provided [url].
  const AudioPlayer.url(
      this.url, {
        super.key,
        this.checksum,
        this.height,
        this.width,
        this.friendly_name,
        this.onError,
      })  : bytes = null,
        path = null;

  /// Constructs a [AudioPlayer] from the provided [bytes].
  const AudioPlayer.bytes(
      this.bytes, {
        super.key,
        this.height,
        this.width,
        this.friendly_name,
        this.onError,
      })  : url = null,
        checksum = null,
        path = null;

  /// Constructs a [AudioPlayer] from the provided file [path].
  const AudioPlayer.file(
      this.path, {
        super.key,
        this.height,
        this.width,
        this.friendly_name,
        this.onError,
      })  : url = null,
        checksum = null,
        bytes = null;

  /// URL of the video to display.
  final String? url;

  /// SHA-256 checksum of the video to display.
  final String? checksum;

  /// Byte data of the video to display.
  final Uint8List? bytes;

  /// Path to the audio [File].
  final String? path;

  /// Name of [File] to display.
  final String? friendly_name;

  String get path_or_url {
    return path != null ? path! : url!;
  }

  @override
  State<AudioPlayer> createState() => _AudioPlayerState();

}

class _AudioPlayerState extends State<AudioPlayer> {

  /// Indicator whether this [PlayableAsset] is hovered.
  bool _hovered = false;

  /// [StreamSubscription] for the audio playback.
  StreamSubscription? _audio;

  /// rewind / forward slider limits
  var _currentSliderValueMs = 0.0.obs;
  var _maxSliderValueMs = 1000.0.obs;

  /// current audio stream player
  PlayerController? _audioStream;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(children: [
      Row(children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: WidgetButton(
            onPressed: _audio != null ? _stopAudio : _playAudio,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _hovered ? style.colors.backgroundAuxiliaryLighter : null,
                border: Border.all(
                  width: 2,
                  color: style.colors.primary,
                ),
              ),
              child: Center(
                child: Icon(
                  _audio != null
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 36,
                  color: const Color(0xFF1F3C5D),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.friendly_name ?? "<no name>",
                style: style.fonts.medium.regular.onBackground,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              SelectionContainer.disabled(
                child: StyledCupertinoButton(
                  padding: EdgeInsets.zero,
                  label: 'Download',
                  style: style.fonts.smaller.regular.primary,
                  onPressed: () async {
                    var bn = widget.friendly_name ?? "audio.mp3";
                    final file = await PlatformUtils.saveTo(
                      '${Config.downloads}/${bn}',
                    );
                    if (file != null) {
                      MessagePopup.success(
                          '${widget.path_or_url} downloaded to ${Config.downloads}/${bn}');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ]),
      Row(children: [
        Expanded(
          child: Obx(() => Slider(
              value: _currentSliderValueMs.value,
              max: _maxSliderValueMs.value,
              label: _currentSliderValueMs.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _audioStream?.seek(value);
                });
              })),
        ),
        Obx(() => Text(
          "${(_currentSliderValueMs/60000.0).floor()}:${((_currentSliderValueMs % 60000.0) / 1000.0).floor()}/"
              "${(_maxSliderValueMs/60000.0).floor()}:${((_maxSliderValueMs % 60000.0) / 1000.0).floor()}",
          style: style.fonts.medium.regular.onBackground,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
      ]),
    ]);
  }

  void _playAudio() {
    var asrc = widget.path != null ? AudioSource.file(widget.path!) : AudioSource.url(widget.url!);
    _audioStream = AudioUtils.createPlayStream(asrc, loop: false, stop_others: true);
    _audio = _audioStream?.beginPlay(
        onData: (_) => {
            _audioStream?.getDurationStream().listen((event) {
            _maxSliderValueMs.value = event.inMilliseconds.toDouble();
            }),
            _audioStream?.getPositionStream().listen((event) {
              _currentSliderValueMs.value = event.inMilliseconds.toDouble();
            })
        },
        onDone: () => {
          _stopAudio(external_call: true)
        });
    setState(() {});
  }

  /// Stops the audio.
  void _stopAudio({bool external_call=false}) {
    if (!external_call) {
      _audio?.cancel();
    }
    _audio = null;
    _audioStream = null;

    setState(() {});
  }

}
