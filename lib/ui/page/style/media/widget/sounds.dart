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
import 'package:get/get.dart';

import '/ui/page/style/controller.dart';
import '/themes.dart';

class SoundsWidget extends StatelessWidget {
  const SoundsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: StyleController(),
        builder: (StyleController c) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                Obx(
                  () => _MediaCard(
                    title: 'chinese.mp3',
                    subtitle: 'Incoming call',
                    child: _PlayPauseButton(
                      isPlaying: c.isPlayingMap['chinese.mp3']!,
                      onPlay: () => c.play('chinese.mp3'),
                      onStop: () => c.stop('chinese.mp3'),
                    ),
                  ),
                ),
                Obx(
                  () => _MediaCard(
                    title: 'chinese-web.mp3',
                    subtitle: 'Web incoming call',
                    child: _PlayPauseButton(
                      isPlaying: c.isPlayingMap['chinese-web.mp3']!,
                      onPlay: () => c.play('chinese-web.mp3'),
                      onStop: () => c.stop('chinese-web.mp3'),
                    ),
                  ),
                ),
                Obx(
                  () => _MediaCard(
                    title: 'ringing.mp3',
                    subtitle: 'Outgoing call',
                    child: _PlayPauseButton(
                      isPlaying: c.isPlayingMap['ringing.mp3']!,
                      onPlay: () => c.play('ringing.mp3'),
                      onStop: () => c.stop('ringing.mp3'),
                    ),
                  ),
                ),
                Obx(
                  () => _MediaCard(
                    title: 'reconnect.mp3',
                    subtitle: 'Call reconnection',
                    child: _PlayPauseButton(
                      isPlaying: c.isPlayingMap['reconnect.mp3']!,
                      onPlay: () => c.play('reconnect.mp3'),
                      onStop: () => c.stop('reconnect.mp3'),
                    ),
                  ),
                ),
                Obx(
                  () => _MediaCard(
                    title: 'message_sent.mp3',
                    subtitle: 'Sended message',
                    child: _PlayPauseButton(
                      isPlaying: c.isPlayingMap['message_sent.mp3']!,
                      onPlay: () => c.play('message_sent.mp3'),
                      onStop: () => c.stop('message_sent.mp3'),
                    ),
                  ),
                ),
                Obx(
                  () => _MediaCard(
                    title: 'notification.mp3',
                    subtitle: 'Notification sound',
                    child: _PlayPauseButton(
                      isPlaying: c.isPlayingMap['notification.mp3']!,
                      onPlay: () => c.play('notification.mp3'),
                      onStop: () => c.stop('notification.mp3'),
                    ),
                  ),
                ),
                Obx(
                  () => _MediaCard(
                    title: 'pop.mp3',
                    subtitle: 'Pop sound',
                    child: _PlayPauseButton(
                      isPlaying: c.isPlayingMap['pop.mp3']!,
                      onPlay: () => c.play('pop.mp3'),
                      onStop: () => c.stop('pop.mp3'),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({this.child, this.title = '', this.subtitle = ''});

  final String title;

  final Widget? child;

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            title,
            style: fonts.bodySmall,
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 80,
          width: 120,
          decoration: BoxDecoration(
            color: style.colors.onPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            subtitle,
            style: fonts.bodySmall,
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({this.isPlaying = false, this.onStop, this.onPlay});

  final bool isPlaying;

  final void Function()? onStop;

  final void Function()? onPlay;

  @override
  Widget build(BuildContext context) {
    return isPlaying
        ? GestureDetector(
            onTap: onStop,
            child: const Icon(
              Icons.pause_rounded,
              size: 50,
              color: Color(0xFF1F3C5D),
            ),
          )
        : GestureDetector(
            onTap: onPlay,
            child: const Icon(
              Icons.play_arrow_rounded,
              size: 50,
              color: Color(0xFF1F3C5D),
            ),
          );
  }
}
