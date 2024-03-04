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

import '/domain/model/attachment.dart';
import '/domain/model/sending_status.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/widget_button.dart';
import '/store/audio_player.dart';
import '/util/audio_utils.dart';

/// Visual representation of a audio file [Attachment].
class AudioAttachment extends StatefulWidget {
  const AudioAttachment(this.attachment, {super.key});

  /// [Attachment] to display.
  final Attachment attachment;

  @override
  State<AudioAttachment> createState() => _AudioAttachmentState();
}

/// State of a [AudioAttachment] maintaining the [_hovered] indicator.
class _AudioAttachmentState extends State<AudioAttachment> {
  @override
  void initState() {
    if (widget.attachment is FileAttachment) {
      (widget.attachment as FileAttachment).init();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Attachment e = widget.attachment;

    return Obx(() {
      final style = Theme.of(context).style;

      final AudioPlayerController audioPlayer =
          Get.find<AudioPlayerController>();

      var isCurrent = audioPlayer.currentAudio.value == e.id.toString();
      var isPlaying = audioPlayer.playing.value;

      var playedPosition =
          audioPlayer.currentSongPosition.value.inMilliseconds.toDouble();
      var totalDuration =
          audioPlayer.currentSongDuration.value.inMilliseconds.toDouble();
      var bufferedPosition =
          audioPlayer.bufferedPosition.value.inMilliseconds.toDouble();

      // This determines if buffering is blocking the playing
      var bufferDifference = bufferedPosition - playedPosition;

      var isBuffering = audioPlayer.buffering.value &&
          isPlaying &&
          bufferDifference <
              const Duration(seconds: 1).inMilliseconds.toDouble();

      Widget leading = Container();

      if (e is FileAttachment) {
        Widget icon;

        if (isCurrent) {
          if (isPlaying) {
            if (isBuffering) {
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
              if (isCurrent) {
                if (isPlaying) {
                  audioPlayer.player.pause();
                } else {
                  audioPlayer.player.play();
                }
              } else {
                String? path = (e is LocalAttachment) ? e.file.path : null;
                String? url = e.original.url;

                AudioSource audioSource = path != null
                    ? AudioSource.file(path)
                    : AudioSource.url(url);

                audioPlayer.player.setTrack(audioSource);
                audioPlayer.currentAudio.value = e.id.toString();
                audioPlayer.player.play();
              }
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth:
                    400, // Here we set some minimal width, so message never jumps
                // in width after Slider is shown
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
                                      value: playedPosition,
                                      secondaryTrackValue: bufferedPosition,
                                      max: totalDuration,
                                      label: playedPosition.round().toString(),
                                      onChanged: (double value) {
                                        Duration seekDuration = Duration(
                                            milliseconds: value.round());
                                        audioPlayer.player.seek(seekDuration);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                    "${(playedPosition / 60000.0).floor().toString().padLeft(2, '0')}:${((playedPosition % 60000.0) / 1000.0).floor().toString().padLeft(2, '0')}/"
                                    "${(totalDuration / 60000.0).floor().toString().padLeft(2, '0')}:${((totalDuration % 60000.0) / 1000.0).floor().toString().padLeft(2, '0')}",
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
