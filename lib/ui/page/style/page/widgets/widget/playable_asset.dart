// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/config.dart';
import '/themes.dart';
import '/ui/page/auth/widget/cupertino_button.dart';
import '/ui/widget/widget_button.dart';
import '/util/audio_utils.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// Playable [asset] with the player.
class PlayableAsset extends StatefulWidget {
  const PlayableAsset(this.asset, {super.key, this.once = true});

  /// Audio asset to play.
  final String asset;

  /// Indicator whether the sound should be played once.
  final bool once;

  @override
  State<PlayableAsset> createState() => _PlayableAssetState();
}

/// State of a [PlayableAsset] maintaining the [_audio].
class _PlayableAssetState extends State<PlayableAsset> {
  /// Indicator whether this [PlayableAsset] is hovered.
  bool _hovered = false;

  /// [StreamSubscription] for the audio playback.
  StreamSubscription? _audio;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Row(
      children: [
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
                color: _hovered
                    ? style.colors.backgroundAuxiliaryLighter
                    : null,
                border: Border.all(width: 2, color: style.colors.primary),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.asset}.mp3',
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
                  final file = await PlatformUtils.saveTo(
                    '${Config.origin}/assets/assets/audio/${widget.asset}.mp3',
                  );
                  if (file != null) {
                    MessagePopup.success('${widget.asset}.mp3 downloaded');
                  }
                },
              ),
            ),
          ],
        ),
      ],
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
