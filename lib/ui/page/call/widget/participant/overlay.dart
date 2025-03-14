// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'package:medea_jason/medea_jason.dart';

import '../../controller.dart';
import '../conditional_backdrop.dart';
import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/svg/svg.dart';

/// [Participant] overlay displaying its `muted` and `video status` icons.
class ParticipantOverlayWidget extends StatelessWidget {
  const ParticipantOverlayWidget(
    this.participant, {
    super.key,
    this.muted = false,
    this.hovered = false,
    this.preferBackdrop = true,
  });

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
    final style = Theme.of(context).style;

    return Obx(() {
      bool isMuted;

      if (participant.source == MediaSourceKind.display ||
          participant.member.isDialing.isTrue) {
        isMuted = false;
      } else {
        isMuted = muted ?? participant.audio.value?.isMuted.value ?? true;
      }

      bool isVideoDisabled =
          participant.video.value?.renderer.value == null &&
          (participant.video.value?.direction.value.isEmitting ?? false) &&
          participant.member.owner == MediaOwnerKind.remote;

      bool isAudioDisabled =
          participant.audio.value != null &&
          participant.audio.value!.renderer.value == null &&
          participant.source != MediaSourceKind.display &&
          participant.member.owner == MediaOwnerKind.remote;

      final List<Widget> additionally = [];

      if (isAudioDisabled) {
        additionally.add(
          const Padding(
            padding: EdgeInsets.only(left: 3, right: 3),
            child: SvgIcon(SvgIcons.audioOffSmall),
          ),
        );
      } else if (isMuted) {
        additionally.add(
          const Padding(
            padding: EdgeInsets.only(left: 2, right: 2),
            child: SvgIcon(SvgIcons.microphoneOffSmall),
          ),
        );
      }

      if (participant.member.quality.value <= 1) {
        additionally.add(
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 3),
            child: SvgIcon(
              participant.member.quality.value <= 0
                  ? SvgIcons.noSignalSmall
                  : SvgIcons.lowSignalSmall,
            ),
          ),
        );
      }

      if (participant.source == MediaSourceKind.display) {
        if (additionally.isNotEmpty) {
          additionally.add(const SizedBox(width: 4));
        }

        if (isVideoDisabled) {
          additionally.add(
            const Padding(
              padding: EdgeInsets.only(left: 4, right: 4),
              child: SvgIcon(SvgIcons.screenShareSmall),
            ),
          );
        } else {
          additionally.add(
            const Padding(
              padding: EdgeInsets.only(left: 4, right: 4),
              child: SvgIcon(SvgIcons.screenShareSmall),
            ),
          );
        }
      } else if (isVideoDisabled) {
        if (additionally.isNotEmpty) {
          additionally.add(const SizedBox(width: 4));
        }
        additionally.add(
          const Padding(
            padding: EdgeInsets.only(left: 5, right: 5),
            child: SvgIcon(SvgIcons.videoOffSmall),
          ),
        );
      }

      final Widget name = Container(
        padding: const EdgeInsets.only(left: 3, right: 3),
        child: Text(
          participant.user.value?.title ?? 'dot'.l10n * 3,
          style: style.fonts.normal.regular.onPrimary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );

      final Widget child;

      if (hovered || additionally.isNotEmpty) {
        child = Container(
          key: const Key('Tooltip'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              CustomBoxShadow(
                color: style.colors.onBackgroundOpacity13,
                blurRadius: 8,
                blurStyle: BlurStyle.outer.workaround,
              ),
            ],
          ),
          child: ConditionalBackdropFilter(
            condition: preferBackdrop,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color:
                    preferBackdrop && ConditionalBackdropFilter.enabled
                        ? style.colors.primaryAuxiliaryOpacity25
                        : style.colors.primaryAuxiliaryOpacity90,
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
                    child:
                        additionally.isEmpty
                            ? name
                            : AnimatedSize(
                              duration: 150.milliseconds,
                              child: hovered ? name : const SizedBox(),
                            ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        child = const SizedBox();
      }

      return Center(
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 8),
                child: SafeAnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
