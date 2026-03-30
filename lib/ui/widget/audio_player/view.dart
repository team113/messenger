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
import '/ui/worker/audio.dart' show AudioItem;
import '/util/audio_utils.dart';
import 'controller.dart';
import 'slider.dart';

/// Audio player with controls.
class AudioPlayer extends StatelessWidget {
  const AudioPlayer({
    super.key,
    required this.item,
    this.progress,
    this.onForbidden,
  });

  /// Metadata of the audio.
  final AudioItem item;

  /// Indicates uploading progress.
  final Widget? progress;

  /// Callback, called when [source] fetch fails with `403` status code.
  final Future<AudioSource?> Function()? onForbidden;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: AudioPlayerController(
        Get.find(),
        item: item,
        onForbidden: onForbidden,
      ),
      tag: item.id.val,
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
                        item.title ?? ('dot'.l10n * 3),
                        style: style.fonts.small.regular.onBackground,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Obx(() {
                        final Widget slider;

                        if (c.isActive) {
                          slider = _slider(context, c);
                        } else {
                          slider = const SizedBox(height: 17);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: slider,
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
      final Widget button;

      if (c.isLoading) {
        button = const Padding(
          key: Key('Loader'),
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        );
      } else {
        button = Center(
          key: Key('Icon_${c.isPlaying}'),
          child: Icon(
            c.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 36,
            color: style.colors.primaryDark,
          ),
        );
      }

      return WidgetButton(
        key: c.isLoading
            ? Key('StopAudio_${item.id.val}')
            : c.isPlaying
            ? Key('PauseAudio_${item.id.val}')
            : Key('PlayAudio_${item.id.val}'),
        onPressed: c.isLoading ? c.stop : c.playOrPause,
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
            child: button,
          ),
        ),
      );
    });
  }

  /// Builds a slider.
  Widget _slider(BuildContext context, AudioPlayerController c) {
    return Obx(() {
      return SeekSlider(
        key: Key('AudioSlider${item.id.val}'),
        position: c.position,
        duration: c.duration,
        onDragStart: (_) => c.onSliderChangeStart(),
        onDragged: (v) => c.onSliderChange(v),
        onDragEnd: (_) => c.onSliderChangeEnd(),
      );
    });
  }
}

/// Builds a timeline.
Widget _timeline(BuildContext context, AudioPlayerController c) {
  final style = Theme.of(context).style;

  return Obx(() {
    final Widget loader;

    if (c.isDurationLoading.value) {
      loader = Container(
        key: const Key('Loader'),
        width: 27,
        height: 10,
        decoration: BoxDecoration(
          color: style.colors.onSecondaryOpacity20,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    } else {
      loader = Text(
        key: const Key('Duration'),
        c.duration.hhMmSs(),
        style: style.fonts.smaller.regular.secondary,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'label_a_slash_space'.l10nfmt({'a': c.position.hhMmSs()}),
          style: style.fonts.smaller.regular.secondary,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: loader,
        ),
      ],
    );
  });
}
