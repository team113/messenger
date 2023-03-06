// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:medea_jason/medea_jason.dart';

import '../controller.dart';
import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import 'call_cover.dart';
import 'conditional_backdrop.dart';
import 'video_view.dart';

/// [Participant] visual representation.
class ParticipantWidget extends StatelessWidget {
  const ParticipantWidget(
    this.participant, {
    super.key,
    this.fit,
    this.muted = false,
    this.outline,
    this.respectAspectRatio = false,
    this.offstageUntilDetermined = false,
    this.onSizeDetermined,
    this.animate = true,
    this.borderRadius = BorderRadius.zero,
    this.expanded = false,
  });

  /// [Participant] this [ParticipantWidget] represents.
  final Participant participant;

  /// [BoxFit] mode of a [Participant.video] renderer.
  final BoxFit? fit;

  /// Indicator whether this video should display `muted` icon or not.
  ///
  /// If `null`, then displays [Participant.audio] muted status.
  final bool? muted;

  /// Indicator whether [Participant.video] should take exactly the size of its
  /// renderer's stream.
  final bool respectAspectRatio;

  /// Indicator whether [Participant.video] should be placed in an [Offstage]
  /// until its size is determined.
  final bool offstageUntilDetermined;

  /// Callback, called when the [Participant.video]'s size is determined.
  final Function? onSizeDetermined;

  /// Optional outline of this video.
  final Color? outline;

  /// Indicator whether [participant] change should be animated or not.
  final bool animate;

  /// Border radius of [Participant.video].
  final BorderRadius? borderRadius;

  /// Indicator whether this [ParticipantWidget] should have its background
  /// expanded.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool hasVideo = participant.video.value?.renderer.value != null;

      // [Widget]s to display in background when no video is available.
      List<Widget> background() {
        return [
          CallCoverWidget(
            participant.user.value?.user.value.callCover,
            user: participant.user.value?.user.value,
          )
        ];
      }

      return Stack(
        children: [
          if (!hasVideo) ...background(),
          AnimatedSwitcher(
            key: const Key('AnimatedSwitcher'),
            duration: animate
                ? const Duration(milliseconds: 200)
                : const Duration(seconds: 1),
            child: !hasVideo
                ? Container()
                : Center(
                    child: RtcVideoView(
                      participant.video.value!.renderer.value
                          as RtcVideoRenderer,
                      source: participant.source,
                      key: participant.videoKey,
                      mirror:
                          participant.member.owner == MediaOwnerKind.local &&
                              participant.source == MediaSourceKind.Device,
                      fit: fit,
                      borderRadius: borderRadius ?? BorderRadius.circular(10),
                      border:
                          outline == null ? null : Border.all(color: outline!),
                      onSizeDetermined: onSizeDetermined,
                      enableContextMenu: false,
                      respectAspectRatio: respectAspectRatio,
                      offstageUntilDetermined: offstageUntilDetermined,
                      framelessBuilder: () => Stack(children: background()),
                    ),
                  ),
          ),
          Positioned.fill(
            child: _handRaisedIcon(participant.member.isHandRaised.value),
          ),
        ],
      );
    });
  }

  /// Returns a raised hand animated icon.
  Widget _handRaisedIcon(bool isRaised) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: isRaised
          ? CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xD8818181),
              child: SvgLoader.asset(
                'assets/icons/hand_up.svg',
                width: 90,
              ),
            )
          : Container(),
    );
  }
}

/// [Participant] overlay displaying its `muted` and `video status` icons.
class ParticipantOverlayWidget extends StatelessWidget {
  const ParticipantOverlayWidget(
    this.participant, {
    Key? key,
    this.muted = false,
    this.hovered = false,
    this.preferBackdrop = true,
  }) : super(key: key);

  /// [Participant] this [ParticipantOverlayWidget] represents.
  final Participant participant;

  /// Indicator whether this video should display `muted` icon or not.
  ///
  /// If `null`, then displays [Participant.audio] muted status.
  final bool? muted;

  /// Indicator whether this [ParticipantOverlayWidget] is being hovered meaning
  /// its label should be visible.
  final bool hovered;

  /// Indicator whether [ConditionalBackdropFilter] should be enabled.
  final bool preferBackdrop;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool isMuted;

      if (participant.source == MediaSourceKind.Display) {
        isMuted = false;
      } else {
        isMuted = muted ?? participant.audio.value?.isMuted.value ?? false;
      }

      bool isVideoDisabled = participant.video.value?.renderer.value == null &&
          (participant.video.value?.direction.value.isEmitting ?? false) &&
          participant.member.owner == MediaOwnerKind.remote;

      bool isAudioDisabled = participant.audio.value != null &&
          participant.audio.value!.renderer.value == null &&
          participant.source != MediaSourceKind.Display &&
          participant.member.owner == MediaOwnerKind.remote;

      List<Widget> additionally = [];

      if (isAudioDisabled) {
        additionally.add(
          Padding(
            padding: const EdgeInsets.only(left: 3, right: 3),
            child: SvgLoader.asset(
              'assets/icons/audio_off_small.svg',
              width: 20.88,
              height: 17,
              fit: BoxFit.fitWidth,
            ),
          ),
        );
      } else if (isMuted) {
        additionally.add(
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 2),
            child: SvgLoader.asset(
              'assets/icons/microphone_off_small.svg',
              height: 16.5,
            ),
          ),
        );
      }

      if (participant.source == MediaSourceKind.Display) {
        if (additionally.isNotEmpty) {
          additionally.add(const SizedBox(width: 4));
        }

        if (isVideoDisabled) {
          additionally.add(
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4),
              child: SvgLoader.asset(
                'assets/icons/screen_share_small.svg',
                height: 12,
              ),
            ),
          );
        } else {
          additionally.add(
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4),
              child: SvgLoader.asset(
                'assets/icons/screen_share_small.svg',
                height: 12,
              ),
            ),
          );
        }
      } else if (isVideoDisabled) {
        if (additionally.isNotEmpty) {
          additionally.add(const SizedBox(width: 4));
        }
        additionally.add(
          Padding(
            padding: const EdgeInsets.only(left: 5, right: 5),
            child: SvgLoader.asset(
              'assets/icons/video_off_small.svg',
              width: 19.8,
              height: 17,
            ),
          ),
        );
      }

      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const IgnorePointer(
              child: SizedBox(width: double.infinity, height: double.infinity),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: hovered || additionally.isNotEmpty
                        ? Container(
                            key: const Key('AnimatedSwitcherLabel'),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                CustomBoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 8,
                                  blurStyle: BlurStyle.outer,
                                )
                              ],
                            ),
                            child: ConditionalBackdropFilter(
                              condition: preferBackdrop,
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: preferBackdrop
                                      ? const Color(0x4D165084)
                                      : const Color(0xBB1F3C5D),
                                ),
                                padding: EdgeInsets.only(
                                  left: 6,
                                  right: additionally.length >= 2 ? 6 : 6,
                                  top: 4,
                                  bottom: 4,
                                ),
                                height: 32,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ...additionally,
                                    if (additionally.isNotEmpty && hovered)
                                      const SizedBox(width: 3),
                                    Flexible(
                                      child: AnimatedSize(
                                        duration: 150.milliseconds,
                                        child: hovered
                                            ? Container(
                                                padding: const EdgeInsets.only(
                                                  left: 3,
                                                  right: 3,
                                                ),
                                                child: Text(
                                                  participant.user.value
                                                          ?.user.value.name?.val ??
                                                      participant
                                                          .user
                                                          .value
                                                          ?.user
                                                          .value
                                                          .num
                                                          .val ??
                                                      'dot'.l10n * 3,
                                                  style: context
                                                      .theme
                                                      .outlinedButtonTheme
                                                      .style!
                                                      .textStyle!
                                                      .resolve({
                                                    MaterialState.disabled
                                                  })!.copyWith(
                                                    fontSize: 15,
                                                    color:
                                                        const Color(0xFFFFFFFF),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              )
                                            : const SizedBox(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Obx(() {
                final Widget child;

                if (participant.member.isConnected.value) {
                  child = Container();
                } else if (participant.member.isRedialing.value) {
                  child = Container(
                    key: Key(
                      'ParticipantRedialing_${participant.member.id}',
                    ),
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.4),
                    child: Padding(
                      padding: const EdgeInsets.all(21.0),
                      child: Center(
                        child: SpinKitDoubleBounce(
                          key: participant.redialingKey,
                          color: const Color(0xFFEEEEEE),
                          size: 100 / 1.5,
                          duration: const Duration(milliseconds: 4500),
                        ),
                      ),
                    ),
                  );
                } else {
                  child = Container(
                    key: Key('ParticipantConnecting_${participant.member.id}'),
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.2),
                    child: const Center(
                      child: CustomProgressIndicator(size: 64),
                    ),
                  );
                }

                return AnimatedSwitcher(
                  duration: 250.milliseconds,
                  child: child,
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}

/// [Participant] background decoration containing a border.
class ParticipantDecoratorWidget extends StatelessWidget {
  const ParticipantDecoratorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.passthrough,
        children: [
          const SizedBox(width: double.infinity, height: double.infinity),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x30000000), width: 0.5),
              ),
              child: const IgnorePointer(),
            ),
          ),
        ],
      ),
    );
  }
}
