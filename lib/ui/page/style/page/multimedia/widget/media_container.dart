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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/themes.dart';
import '/ui/widget/widget_button.dart';
import '/util/audio_utils.dart';
import '/util/message_popup.dart';

/// [Container] with [subtitle] and option to play the audio from [asset].
class MediaContainer extends StatefulWidget {
  const MediaContainer(this.asset, {super.key, this.subtitle});

  /// Name of the audio asset to play.
  final String? asset;

  /// Subtitle of this [MediaContainer].
  final String? subtitle;

  @override
  State<MediaContainer> createState() => MediaContainerState();
}

/// State of an [MediaContainer] maintaining the [_isPlaying] and [_audio].
class MediaContainerState extends State<MediaContainer> {
  /// Indicator whether the audio is currently playing.
  bool _isPlaying = false;

  /// [StreamSubscription] for the audio playback.
  StreamSubscription? _audio;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return DefaultTextStyle(
      style: fonts.bodySmall!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: WidgetButton(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: 'audio/${widget.asset}.mp3'),
                );
                MessagePopup.success('Path to the asset has been copied');
              },
              child: Text('${widget.asset}.mp3'),
            ),
          ),
          Container(
            height: 80,
            width: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F3C5D)),
            ),
            child: GestureDetector(
              onTap: _isPlaying ? _stopAudio : _playAudio,
              child: Icon(
                _isPlaying ? Icons.pause_outlined : Icons.play_arrow_rounded,
                size: 50,
                color: const Color(0xFF1F3C5D),
              ),
            ),
          ),
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(widget.subtitle!),
            ),
        ],
      ),
    );
  }

  /// Starts playback of the audio asset.
  void _playAudio() {
    _audio = AudioUtils.play(AudioSource.asset('audio/${widget.asset}.mp3'));
    _isPlaying = true;
    setState(() {});
  }

  /// Stops playback of the audio asset.
  void _stopAudio() {
    _audio?.cancel();
    _isPlaying = false;
    setState(() {});
  }
}
