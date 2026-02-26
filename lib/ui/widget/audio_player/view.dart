import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widget_button.dart';
import '/domain/model/attachment.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/worker/audio.dart';
import '/util/audio_utils.dart';

/// Audio player with controls.
class AudioPlayer extends StatefulWidget {
  const AudioPlayer({
    super.key,
    required this.source,
    required this.id,
    required this.filename,
  });

  /// Source of the audio to play.
  final AudioSource source;

  /// Unique identifier of the audio.
  final AttachmentId id;

  /// Name of the audio file.
  final String filename;

  @override
  State<AudioPlayer> createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<AudioPlayer> {
  final AudioWorker _worker = Get.find();

  bool _hovered = false;
  bool _wasPlaying = false;

  double _getSliderValue(Duration position, Duration duration) {
    final posMs = position.inMilliseconds.toDouble();
    final durMs = duration.inMilliseconds.toDouble();
    if (durMs <= 0) return 0.0;
    return posMs.clamp(0.0, durMs);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      final bool isActive = _worker.activeAudioId.value == widget.id.val;
      final bool isPlaying = _worker.isPlaying.value && isActive;
      final bool isLoading = _worker.isLoading.value && isActive;
      final position = _worker.position.value;
      final duration = _worker.duration.value;

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: WidgetButton(
                  key: const Key('PlayerButton'),
                  onPressed: () {
                    if (isActive && isPlaying) {
                      _worker.pause();
                    } else {
                      _worker.play(widget.id.val, widget.source);
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
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: const CircularProgressIndicator(),
                          )
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      widget.filename,
                      style: style.fonts.small.regular.onBackground,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isActive
                          ? KeyedSubtree(
                              key: const ValueKey('timeline'),
                              child: _buildTimeline(position, duration, style),
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
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

  Widget _buildTimeline(Duration position, Duration duration, Style style) {
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
              onChangeStart: (_) {
                _wasPlaying = _worker.isPlaying.value;
                _worker.pause();
              },
              onChangeEnd: (_) {
                if (_wasPlaying) {
                  _worker.play(widget.id.val, widget.source);
                }
              },
              value: _getSliderValue(position, duration),
              max: duration.inMilliseconds.toDouble() > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1.0,
              onChanged: (v) => _worker.seek(Duration(milliseconds: v.toInt())),
            ),
          ),
        ),
        Row(
          children: [
            Text(
              position.hhMmSs(),
              style: style.fonts.smaller.regular.secondary,
            ),
            Text(' / ', style: style.fonts.smaller.regular.secondary),
            Text(
              duration.hhMmSs(),
              style: style.fonts.smaller.regular.secondary,
            ),
          ],
        ),
      ],
    );
  }
}
