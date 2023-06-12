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
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '../../controller.dart';
import '../call_cover.dart';
import '../raised_hand.dart';
import '../video_view.dart';
import '/domain/model/ongoing_call.dart';
import '/themes.dart';
import '/ui/widget/progress_indicator.dart';

/// [Participant] visual representation.
class ParticipantWidget extends StatelessWidget {
  const ParticipantWidget(
    this.participant, {
    super.key,
    this.fit,
    this.outline,
    this.respectAspectRatio = false,
    this.offstageUntilDetermined = false,
    this.onSizeDetermined,
    this.animate = true,
    this.borderRadius = BorderRadius.zero,
  });

  /// [Participant] this [ParticipantWidget] represents.
  final Participant participant;

  /// [BoxFit] mode of a [Participant.video] renderer.
  final BoxFit? fit;

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

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

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
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.center,
              children: [
                if (previous.isNotEmpty) previous.first,
                if (current != null) current,
              ],
            ),
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
          Obx(() {
            final Widget child;

            if (participant.member.isConnected.value) {
              child = Container();
            } else if (participant.member.isRedialing.isTrue) {
              child = Container(
                key: Key('ParticipantRedialing_${participant.member.id}'),
                width: double.infinity,
                height: double.infinity,
                color: style.colors.onBackgroundOpacity50,
                child: Padding(
                  padding: const EdgeInsets.all(21.0),
                  child: Center(
                    child: SpinKitDoubleBounce(
                      color: style.colors.secondaryHighlight,
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
                color: style.colors.onBackgroundOpacity50,
                child: const Center(
                  child: CustomProgressIndicator(size: 64),
                ),
              );
            }

            return AnimatedSwitcher(duration: 250.milliseconds, child: child);
          }),
          Center(
            child: RaisedHand(participant.member.isHandRaised.value),
          ),
        ],
      );
    });
  }
}
