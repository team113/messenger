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

/// Playable [asset] with optional [subtitle] to put underneath the player.
class PlayableAsset extends StatefulWidget {
  const PlayableAsset(
    this.asset, {
    super.key,
    this.subtitle,
    this.once = true,
  });

  /// Audio asset to play.
  final String asset;

  /// Subtitle to put under.
  final String? subtitle;

  /// Indicator whether the sound should be played once.
  final bool once;

  @override
  State<PlayableAsset> createState() => _PlayableAssetState();
}

/// State of a [PlayableAsset] maintaining the [_audio].
class _PlayableAssetState extends State<PlayableAsset> {
  /// [StreamSubscription] for the audio playback.
  StreamSubscription? _audio;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return DefaultTextStyle(
      style: style.fonts.small.regular.onBackground,
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
              onTap: _audio != null ? _stopAudio : _playAudio,
              child: Icon(
                _audio != null
                    ? Icons.pause_outlined
                    : Icons.play_arrow_rounded,
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

  /// Plays the audio.
  void _playAudio() {
    if (widget.once) {
      AudioUtils.once(AudioSource.asset('audio/${widget.asset}.mp3'));
    } else {
      _audio = AudioUtils.play(AudioSource.asset('audio/${widget.asset}.mp3'));
      setState(() {});
    }
  }

  /// Stops the audio.
  void _stopAudio() {
    _audio?.cancel();
    _audio = null;
    setState(() {});
  }
}
