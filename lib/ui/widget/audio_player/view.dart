import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widget_button.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/worker/audio.dart';
import '/util/audio_utils.dart';

class AudioPlayer extends StatefulWidget {
  const AudioPlayer({
    super.key,
    required this.source,
    required this.id,
    required this.filename,
  });

  final String id;
  final AudioSource source;
  final String filename;

  @override
  State<AudioPlayer> createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<AudioPlayer> {
  final AudioWorker w = Get.find();

  bool _hovered = false;
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      final bool isActive = w.activeAudioId.value == widget.id;
      final bool isPlaying = w.isPlaying.value && isActive;
      final bool isLoading = w.isLoading.value && isActive;

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 53,
          child: Row(
            children: [
              MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: WidgetButton(
                  onPressed: () {
                    if (isActive && isPlaying) {
                      w.pause();
                    } else {
                      w.play(widget.id, widget.source);
                    }
                  },
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
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : Center(
                            child: Icon(
                              isPlaying
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.filename,
                      style: style.fonts.medium.regular.onBackground,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: isActive
                          ? Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2.0,
                                    activeTrackColor: style.colors.primary,
                                    inactiveTrackColor:
                                        style.colors.secondaryHighlightDarkest,
                                    thumbColor: style.colors.primary,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 5.0,
                                    ),
                                  ),
                                  child: SizedBox(
                                    height: 17,
                                    child: Slider(
                                      value: w.position.value.inMilliseconds
                                          .toDouble()
                                          .clamp(
                                            0,
                                            w.duration.value.inMilliseconds
                                                        .toDouble() >
                                                    0
                                                ? w
                                                      .duration
                                                      .value
                                                      .inMilliseconds
                                                      .toDouble()
                                                : 1.0,
                                          ),
                                      max: w.duration.value.inMilliseconds
                                          .toDouble(),
                                      onChanged: (v) {
                                        w.seek(
                                          Duration(milliseconds: v.toInt()),
                                        );
                                      },
                                      onChangeStart: (v) {},
                                      onChangeEnd: (v) async {},
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      w.position.value.hhMmSs(),
                                      style:
                                          style.fonts.smaller.regular.secondary,
                                    ),
                                    Text(
                                      ' / ',
                                      style:
                                          style.fonts.smaller.regular.secondary,
                                    ),
                                    Text(
                                      w.duration.value.hhMmSs(),
                                      style:
                                          style.fonts.smaller.regular.secondary,
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
