// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:path/path.dart' as p;

import '/domain/model/audio_track.dart';
import '/domain/model/attachment.dart';
import '/domain/model/sending_status.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/widget_button.dart';
import '/ui/worker/audio_player.dart';

/// Visual representation of an audio file [Attachment].
class AudioAttachment extends StatelessWidget {
  const AudioAttachment(this.attachment, {super.key});

  /// [Attachment] to display.
  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final Attachment e = attachment;

    /// [AudioPlayerWorker] to audio player.
    final AudioPlayerWorker audioPlayer = AudioPlayerWorker.instance;

    return Obx(() {
      final style = Theme.of(context).style;

      bool isCurrent = audioPlayer.currentAudio.value == e.id.toString();
      bool isPlaying = audioPlayer.playing.value;
      bool isBuffering = audioPlayer.buffering.value;
      bool isCompleted = audioPlayer.completed.value;

      Duration totalDuration = audioPlayer.currentSongDuration.value;
      Duration playedPosition = audioPlayer.currentSongPosition.value;
      Duration bufferedPosition = audioPlayer.bufferedPosition.value;

      // Sometimes new track duration hasn't been calculated yet (so it's 0),
      // but buffered position stays from the previous track (greater than 0):
      // - this causes [Slider] to crash as value should be within min and max.
      //
      // We fix it by first checking if bufferedPosition exceeds totalDuration and
      // if yes - setting bufferedPosition to zero.
      //
      // fyi: manually resetting the position in the [AudioPlayerWorker] on
      // track change didn't work. Seems to be the problem either with
      // media_kit library or the way values come from the multiple streams.
      if (bufferedPosition > totalDuration) {
        bufferedPosition = Duration.zero;
      }

      // Same as previous comment.
      if (playedPosition > totalDuration) {
        playedPosition = Duration.zero;
      }

      // This determines if buffering is blocking the playing
      int bufferDifferenceInMs =
          bufferedPosition.inMilliseconds - playedPosition.inMilliseconds;

      bool isAudioBuffering = isPlaying &&
          isBuffering &&
          !isCompleted &&
          bufferDifferenceInMs < const Duration(seconds: 1).inMilliseconds;

      Widget leading = Container();

      if (e is FileAttachment) {
        Widget icon;

        if (isCurrent) {
          if (isPlaying) {
            if (isAudioBuffering) {
              icon = const CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              );
            } else {
              icon = const Icon(
                Icons.pause_rounded,
                size: 25,
                color: Color(0xFFFFFFFF),
              );
            }
          } else {
            icon = const Icon(
              Icons.play_arrow_rounded,
              size: 25,
              color: Color(0xFFFFFFFF),
            );
          }
        } else {
          icon = const Icon(
            Icons.play_arrow_rounded,
            size: 25,
            color: Color(0xFFFFFFFF),
          );
        }

        leading = Container(
          key: const Key('Play'),
          height: 29,
          width: 29,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: style.colors.primary,
          ),
          child: Center(child: icon),
        );
      } else if (e is LocalAttachment) {
        switch (e.status.value) {
          case SendingStatus.sending:
            leading = SizedBox.square(
              key: const Key('Sending'),
              dimension: 29,
              child: CircularProgressIndicator(
                value: e.progress.value,
                backgroundColor: style.colors.onPrimary,
                strokeWidth: 5,
              ),
            );
            break;

          case SendingStatus.sent:
            leading = Icon(
              Icons.check_circle,
              key: const Key('Sent'),
              size: 29,
              color: style.colors.acceptAuxiliary,
            );
            break;

          case SendingStatus.error:
            leading = Icon(
              Icons.error_outline,
              key: const Key('Error'),
              size: 29,
              color: style.colors.danger,
            );
            break;
        }
      }

      return MouseRegion(
        child: Padding(
          key: Key('AudioFile_${e.id}'),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: WidgetButton(
            onPressed: () {
              if (isCurrent && isPlaying) {
                audioPlayer.pause();
              } else {
                AudioTrack track = attachment.toAudioTrack();
                audioPlayer.play(track);
              }
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                // Here we set some minimal width, so message never jumps
                // in width after Slider is shown
                minWidth: 450,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SafeAnimatedSwitcher(
                      key: Key('AttachmentStatus_${e.id}'),
                      duration: 250.milliseconds,
                      child: leading,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.basenameWithoutExtension(e.filename),
                                style: style.fonts.medium.regular.onBackground,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              p.extension(e.filename),
                              style: style.fonts.medium.regular.onBackground,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        if (isCurrent)
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Padding(
                                  padding: EdgeInsets.zero,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                        trackHeight: 1.0,
                                        thumbShape: const RoundSliderThumbShape(
                                            enabledThumbRadius: 8.0),
                                        // This removes the additional circular area around the thumb.
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                                overlayRadius: 1.0),
                                        thumbColor: style.colors.primary,
                                        activeTrackColor: style
                                            .colors.primaryHighlightLightest),
                                    child: Slider(
                                      value: playedPosition.inMilliseconds
                                          .toDouble(),
                                      secondaryTrackValue: bufferedPosition
                                          .inMilliseconds
                                          .toDouble(),
                                      max: totalDuration.inMilliseconds
                                          .toDouble(),
                                      label: playedPosition.inMilliseconds
                                          .toDouble()
                                          .round()
                                          .toString(),
                                      onChanged: (double value) {
                                        Duration seekPosition = Duration(
                                            milliseconds: value.round());
                                        audioPlayer.seek(seekPosition);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                    'label_a_slash_b'.l10nfmt({
                                      'a': playedPosition.hhMmSs(),
                                      'b': totalDuration.hhMmSs()
                                    }),
                                    style: style.fonts.small.regular.secondary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end),
                              )
                            ],
                          ),
                        if (!isCurrent)
                          Text(
                            'label_kb'.l10nfmt({
                              'amount': e.original.size == null
                                  ? 'dot'.l10n * 3
                                  : e.original.size! ~/ 1024
                            }),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: style.fonts.small.regular.secondary,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
