import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '../controller.dart';
import '/domain/model/ongoing_call.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/svg/svg.dart';
import 'video_view.dart';

/// [Participant] visual representation.
class ParticipantWidget extends StatelessWidget {
  const ParticipantWidget(
    this.participant, {
    Key? key,
    this.enableContextMenu = true,
    this.fit = BoxFit.cover,
    this.muted = false,
    this.withLabels = true,
    this.outline,
    this.respectAspectRatio = false,
    this.offstageUntilDetermined = false,
    this.onSizeDetermined,
    this.hovered = false,
    this.animate = true,
    this.borderRadius,
  }) : super(key: key);

  /// [Participant] this [ParticipantWidget] represents.
  final Participant participant;

  /// [BoxFit] mode of a [Participant.video] renderer.
  final BoxFit fit;

  /// Indicator whether this video should display `muted` icon or not.
  ///
  /// If `null`, then displays [Participant.audio] muted status.
  final bool? muted;

  /// Indicator whether [muted] and label should be displayed or not.
  final bool withLabels;

  /// Indicator whether [Participant.video] should take exactly the size of its
  /// renderer's stream.
  final bool respectAspectRatio;

  /// Indicator whether [Participant.video] should be placed in an [Offstage]
  /// until its size is determined.
  final bool offstageUntilDetermined;

  /// Callback, called when the [Participant.video]'s size is determined.
  final Function? onSizeDetermined;

  /// Indicator whether default context menu is enabled over this widget or not.
  ///
  /// Only effective under the web, since only web has default context menu.
  final bool enableContextMenu;

  /// Optional outline of this video.
  final Color? outline;

  /// Indicator whether this [ParticipantWidget] is being hovered meaning its
  /// label should be visible.
  final bool hovered;

  /// Indicator whether [participant] change should be animated or not.
  final bool animate;

  /// Border radius of [Participant.video].
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool isMuted = muted ?? participant.audio.value?.muted ?? true;

      return IgnorePointer(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedSwitcher(
              duration: animate
                  ? const Duration(milliseconds: 200)
                  : const Duration(seconds: 1),
              child: participant.video.value == null ||
                      participant.video.value?.isEnabled == false
                  ? Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          AvatarWidget.fromUser(
                            participant.user.value?.user.value,
                            radius: 30,
                          ),
                          Positioned(
                            right: 15,
                            top: 15,
                            child: _handRaisedIcon(
                              participant.handRaised.value,
                            ),
                          ),
                          Positioned(
                            left: 15,
                            top: 15,
                            child: _videoDisabledIcon(),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        RtcVideoView(
                          participant.video.value!,
                          mirror: participant.owner == MediaOwnerKind.local &&
                              participant.source == MediaSourceKind.Device,
                          fit: fit,
                          borderRadius:
                              borderRadius ?? BorderRadius.circular(10),
                          outline: outline,
                          onSizeDetermined: onSizeDetermined,
                          enableContextMenu: enableContextMenu,
                          respectAspectRatio: respectAspectRatio,
                          offstageUntilDetermined: offstageUntilDetermined,
                        ),
                        Positioned(
                          right: 15,
                          top: 15,
                          child: _handRaisedIcon(participant.handRaised.value),
                        ),
                      ],
                    ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: withLabels && (isMuted || hovered)
                  ? Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 6.3),
                      margin: const EdgeInsets.only(bottom: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: const Color(0xDD818181),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMuted) ...[
                            const SizedBox(width: 1),
                            SvgLoader.asset(
                              'assets/icons/microphone_off_small.svg',
                              width: 11,
                            ),
                          ],
                          Flexible(
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: hovered
                                  ? Padding(
                                      padding: EdgeInsets.only(
                                          left: isMuted ? 6 : 1),
                                      child: Text(
                                        participant.user.value?.user.value.name
                                                ?.val ??
                                            participant.user.value?.user.value
                                                .num.val ??
                                            '...',
                                        style: context.theme.outlinedButtonTheme
                                            .style!.textStyle!
                                            .resolve({
                                          MaterialState.disabled
                                        })!.copyWith(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : const SizedBox(width: 1, height: 25),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: 1, height: 1),
            ),
          ],
        ),
      );
    });
  }

  /// Returns a raised hand animated icon.
  Widget _handRaisedIcon(bool isRaised) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: isRaised
          ? CircleAvatar(
              backgroundColor: const Color(0xD8818181),
              radius: 15,
              child: SvgLoader.asset(
                'assets/icons/hand_up.svg',
                width: 30,
              ),
            )
          : Container(),
    );
  }

  /// Returns a disabled video animated icon.
  Widget _videoDisabledIcon() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: participant.video.value?.isEnabled == false
          ? CircleAvatar(
              backgroundColor: const Color(0xD8818181),
              radius: 15,
              child: SvgLoader.asset(
                'assets/icons/video_off.svg',
                width: 30,
              ),
            )
          : Container(),
    );
  }
}
