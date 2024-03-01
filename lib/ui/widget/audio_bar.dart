import 'dart:ui';
import 'package:flutter/material.dart';
import '/themes.dart'; // Assuming this is where your style and CustomBoxShadow are defined
import '/ui/page/call/widget/conditional_backdrop.dart'; // For the conditional backdrop
import 'package:get/get.dart';
import '/store/audio_player.dart';

class AudioBarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style; // Assuming this accesses your theme/style data
    final AudioStore audioStore = Get.find<AudioStore>();

    // Replicating some CustomAppBar styling elements for consistency
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Modifiable as needed
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8), // Assuming a bottom margin to give some space from the chat contents
      height: 42.0,
      decoration: BoxDecoration(
        borderRadius: style.cardRadius,
        // boxShadow: [
        //   CustomBoxShadow(
        //     blurRadius: 8,
        //     color: style.colors.onBackgroundOpacity13,
        //     blurStyle: BlurStyle.outer.workaround,
        //   ),
        // ],
      ),
      child: ConditionalBackdropFilter(
        condition: style.cardBlur > 0,
        filter: ImageFilter.blur(
          sigmaX: style.cardBlur,
          sigmaY: style.cardBlur,
        ),
        borderRadius: style.cardRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            border: style.cardBorder,
            color: style.cardColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Your play/pause icon
              Icon(Icons.play_arrow, color: style.colors.onPrimary, size: 24),
              // Text displaying what's currently playing
              Expanded(
                child: Text(
                  audioStore.currentAudio.value,
                  // 'Now Playing: Dummy Title',
                  // style: style.fonts.small.regular.onPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Your stop icon or other action
              Icon(Icons.stop, color: style.colors.onPrimary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
