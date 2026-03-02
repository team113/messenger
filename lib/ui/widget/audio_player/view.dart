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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../animated_switcher.dart';
import '../widget_button.dart';
import '/domain/model/attachment.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/util/audio_utils.dart';
import 'controller.dart';

/// Audio player with controls.
class AudioPlayer extends StatelessWidget {
  const AudioPlayer({
    super.key,
    required this.source,
    required this.id,
    required this.filename,
    this.progress,
  });

  /// Source of the audio to play.
  final AudioSource source;

  /// Unique identifier of the audio.
  final AttachmentId id;

  /// Name of the audio file.
  final String filename;

  /// Indicates uploading progress.
  final Widget? progress;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder<AudioPlayerController>(
      init: AudioPlayerController(Get.find(), id: id, source: source),
      tag: id.val,
      builder: (c) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                MouseRegion(
                  onEnter: (_) => c.hovered = true,
                  onExit: (_) => c.hovered = false,
                  child:
                      progress ??
                      WidgetButton(
                        key: Key('PlayerButton$id'),
                        onPressed: c.togglePlay,
                        child: Obx(
                          () => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.hovered
                                  ? style.colors.backgroundAuxiliaryLighter
                                  : null,
                              border: Border.all(
                                width: 2,
                                color: style.colors.primary,
                              ),
                            ),
                            child: SafeAnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: c.isLoading
                                  ? const Padding(
                                      key: ValueKey('loader'),
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    )
                                  : Center(
                                      key: ValueKey('icon_${c.isPlaying}'),
                                      child: Icon(
                                        c.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 36,
                                        color: const Color(0xFF1F3C5D),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        filename,
                        style: style.fonts.small.regular.onBackground,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Obx(
                        () => AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: c.isActive
                              ? KeyedSubtree(
                                  key: const ValueKey('timeline'),
                                  child: _buildTimeline(c, style, context),
                                )
                              : const SizedBox.shrink(key: ValueKey('empty')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeline(
    AudioPlayerController c,
    Style style,
    BuildContext context,
  ) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.0,
            activeTrackColor: style.colors.primary,
            inactiveTrackColor: style.colors.secondaryHighlightDarkest,
            thumbColor: style.colors.primary,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
          ),
          child: SizedBox(
            height: 17,
            child: Slider(
              key: Key('AudioSlider$id'),
              onChangeStart: (_) => c.onSliderChangeStart(),
              onChangeEnd: (v) => c.onSliderChangeEnd(),
              value: c.getSliderValue(),
              max: c.duration.inMilliseconds.toDouble() > 0
                  ? c.duration.inMilliseconds.toDouble()
                  : 1.0,
              onChanged: (v) => c.position = Duration(milliseconds: v.toInt()),
            ),
          ),
        ),
        Row(
          children: [
            Text(
              c.position.hhMmSs(),
              style: style.fonts.smaller.regular.secondary,
            ),
            Text(' / ', style: style.fonts.smaller.regular.secondary),
            Text(
              c.duration.hhMmSs(),
              style: style.fonts.smaller.regular.secondary,
            ),
          ],
        ),
      ],
    );
  }
}
