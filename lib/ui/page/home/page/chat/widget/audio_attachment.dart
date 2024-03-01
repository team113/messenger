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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '/domain/model/attachment.dart';
import '/domain/model/sending_status.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/store/audio_player.dart';
import '/util/audio_utils.dart';
// import '/ui/worker/cache.dart';

/// Visual representation of a audio file [Attachment].
class AudioAttachment extends StatefulWidget {
  const AudioAttachment(this.attachment, {super.key,
    // this.onPressed
  });

  /// [Attachment] to display.
  final Attachment attachment;

  /// Callback, called when this [AudioAttachment] is pressed.
  // final void Function()? onPressed;

  @override
  State<AudioAttachment> createState() => _AudioAttachmentState();
}

/// State of a [AudioAttachment] maintaining the [_hovered] indicator.
class _AudioAttachmentState extends State<AudioAttachment> {
  /// Indicator whether this [AudioAttachment] is playing.
  bool _hovered = false;

  /// Indicator whether this [AudioAttachment] has loaded.
  bool _loaded = false;

  @override
  void initState() {
    if (widget.attachment is FileAttachment) {
      (widget.attachment as FileAttachment).init();
    }

    super.initState();

    print(widget.attachment);
    print(widget.attachment.id);
    // debugDumpObject(widget.attachment);
  }
  @override
  Widget build(BuildContext context) {
    final Attachment e = widget.attachment;

    return Obx(() {
      final style = Theme.of(context).style;

      final AudioStore audioStore = Get.find<AudioStore>();
      // var audio = audioStore.currentAudio.value;

      var isCurrent = audioStore.currentAudio.value == e.id.toString();
      var isPlaying = audioStore.playing.value;
      var isCurrentPlaying = isCurrent && isPlaying;

      // var _currentSliderValueMs = 0.0.obs;
      // var _maxSliderValueMs = 1000.0.obs;
      var _currentSliderValueMs = audioStore.currentSongPosition.value.inMilliseconds.toDouble();
      var _maxSliderValueMs = audioStore.currentSongDuration.value.inMilliseconds.toDouble();

      Widget leading = Container();

      if (e is FileAttachment) {
        leading = Container(
          key: const Key('Play'),
          height: 29,
          width: 29,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: style.colors.primary,
          ),
          child: Center(
            child: Icon(
              isCurrentPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 25,
              // color: const Colors.white
              color: const Color(0xFFFFFFFF)
            ),
            // child: Transform.translate(
            //   // offset: const Offset(0.3, -0.5),
            //   // child: SvgIcon(isCurrentPlaying ? SvgIcons.pause : SvgIcons.play),
            // ),
          ),
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
              Icons.play_arrow_rounded,
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

      // return Text(
      //   'Hello world',
      //   style: style.fonts.medium.regular.onBackground,
      //   maxLines: 1,
      //   overflow: TextOverflow.ellipsis,
      // );

      return MouseRegion(
        // onEnter: (_) => setState(() => _hovered = true),
        // onExit: (_) => setState(() => _hovered = false),
        child: Padding(
          key: Key('AudioFile_${e.id}'),
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: WidgetButton(
            onPressed: () {
              var path;

              if (e is LocalAttachment) {
                path.value = (e as LocalAttachment).file.path;
              }
              var url = e.original.url;

              if (isCurrent) {
                if (isPlaying) {
                  audioStore.stop();
                  // audioStore.pause();
                } else {
                  audioStore.play(path, url);
                }
              } else {
                audioStore.setCurrentAudio(e.id.toString());
                audioStore.play(path, url);
              }
            },
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
                      if (isCurrentPlaying)
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 4, // take 80% of space
                              child: Slider(
                                value: _currentSliderValueMs,
                                max: _maxSliderValueMs,
                                label: _currentSliderValueMs.round().toString(),
                                onChanged: (double value) {
                                  audioStore.seek(value);
                                },
                              ),
                            ),
                            Expanded(
                              flex: 1, // take 20% of space
                              child: Text(
                                "${(_currentSliderValueMs/60000.0).floor().toString().padLeft(2, '0')}:${((_currentSliderValueMs % 60000.0) / 1000.0).floor().toString().padLeft(2, '0')}/"
                                "${(_maxSliderValueMs/60000.0).floor().toString().padLeft(2, '0')}:${((_maxSliderValueMs % 60000.0) / 1000.0).floor().toString().padLeft(2, '0')}",
                                style: style.fonts.small.regular.secondary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      if (!isCurrentPlaying)
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
      );
    });
  }
}
