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

import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/util/audio_utils.dart';

/// [Wrap] with [_MediaContainer]s which represents application sounds.
class SoundsWidget extends StatelessWidget {
  const SoundsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MediaContainer(
              asset: 'chinese',
              subtitle: 'Incoming call',
            ),
            _MediaContainer(
              asset: 'chinese-web',
              subtitle: 'Web incoming call',
            ),
            _MediaContainer(
              asset: 'ringing',
              subtitle: 'Outgoing call',
            ),
            _MediaContainer(
              asset: 'reconnect',
              subtitle: 'Call reconnection',
            ),
            _MediaContainer(
              asset: 'message_sent',
              subtitle: 'Sended message',
            ),
            _MediaContainer(
              asset: 'notification',
              subtitle: 'Notification sound',
            ),
            _MediaContainer(
              asset: 'pop',
              subtitle: 'Pop sound',
            ),
          ],
        ),
      ),
    );
  }
}

/// [Container] with [subtitle] and option to play the audio from [asset].
class _MediaContainer extends StatelessWidget {
  const _MediaContainer({this.asset, this.subtitle});

  /// Asset to play.
  final String? asset;

  /// Subtitle of this [_MediaContainer].
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '$asset.mp3',
            style: fonts.bodySmall,
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 80,
          width: 120,
          decoration: BoxDecoration(
            color: style.colors.onPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: GestureDetector(
            onTap: () => AudioUtils.once(
              AudioSource.asset('audio/$asset.mp3'),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 50,
              color: Color(0xFF1F3C5D),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              subtitle!,
              style: fonts.bodySmall,
              textAlign: TextAlign.start,
            ),
          ),
      ],
    );
  }
}
