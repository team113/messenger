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
import 'package:get/get.dart';

import '../animated_switcher.dart';
import '../widget_button.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/util/audio_utils.dart';
import 'controller.dart';
import 'slider.dart';

/// Audio player with controls.
class AudioPlayer extends StatelessWidget {
  const AudioPlayer({
    super.key,
    required this.source,
    required this.id,
    required this.filename,
    this.progress,
    this.onForbidden,
  });

  /// [AudioSource] of the audio to play.
  final AudioSource source;

  /// Unique identifier of the audio.
  final AudioId id;

  /// Name of the audio file.
  final String filename;

  /// Indicates uploading progress.
  final Widget? progress;

  /// Callback, called when [source] fetch fails with `403` status code.
  final FutureOr<AudioSource?> Function()? onForbidden;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: AudioPlayerController(
        Get.find(),
        id: id,
        source: source,
        onForbidden: onForbidden,
      ),
      tag: id.val,
      builder: (AudioPlayerController c) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 48, minWidth: 260),
            child: Row(
              children: [
                MouseRegion(
                  onEnter: (_) => c.hovered.value = true,
                  onExit: (_) => c.hovered.value = false,
                  child: progress ?? _play(context, c),
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
                      Obx(() {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: c.isActive
                                  ? KeyedSubtree(
                                      key: const ValueKey('timeline'),
                                      child: _slider(context, c),
                                    )
                                  : const SizedBox(
                                      key: ValueKey('empty'),
                                      height: 17,
                                    ),
                            ),
                            _timeline(context, c),
                          ],
                        );
                      }),
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

  /// Builds a play/pause button.
  Widget _play(BuildContext context, AudioPlayerController c) {
    final style = Theme.of(context).style;

    return Obx(() {
      return WidgetButton(
        key: Key('PlayerButton${id.val}'),
        onPressed: c.isLoading ? c.stop : c.togglePlay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.hovered.value
                ? style.colors.backgroundAuxiliaryLighter
                : null,
            border: Border.all(width: 2, color: style.colors.primary),
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
      );
    });
  }

  /// Builds a slider.
  Widget _slider(BuildContext context, AudioPlayerController c) {
    return Obx(
      () => SeekSlider(
        key: Key('AudioSlider${id.val}'),
        position: c.position,
        duration: c.duration,
        onChangeStart: (_) => c.onSliderChangeStart(),
        onChangeEnd: (_) => c.onSliderChangeEnd(),
        onChanged: (v) => c.position = Duration(milliseconds: v.toInt()),
      ),
    );
  }
}

/// Builds a timeline.
Widget _timeline(BuildContext context, AudioPlayerController c) {
  final style = Theme.of(context).style;

  return Obx(
    () => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${c.position.hhMmSs()} / ',
          style: style.fonts.smaller.regular.secondary,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: c.isDurationLoading.value
              ? Container(
                  key: const ValueKey('duration_skeleton'),
                  width: 27,
                  height: 10,
                  decoration: BoxDecoration(
                    color: style.colors.onSecondaryOpacity20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(
                  key: const ValueKey('duration_text'),
                  c.duration.hhMmSs(),
                  style: style.fonts.smaller.regular.secondary,
                ),
        ),
      ],
    ),
  );
}
