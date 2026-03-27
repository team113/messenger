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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/controller.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/svg/svg.dart';

/// [Participant] overlay displaying its `muted` and `video status` icons.
class ParticipantOverlayWidget extends StatelessWidget {
  const ParticipantOverlayWidget(
    this.participant, {
    super.key,
    this.muted = false,
    this.hovered = false,
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

      final List<List<SvgData>> icons = [
        // Connection related icons.
        [
          if (participant.member.quality.value <= 0)
            SvgIcons.noSignalSmall
          else if (participant.member.quality.value <= 1)
            SvgIcons.lowSignalSmall,
        ],

        // Status related icons.
        [
          if (isAudioDisabled)
            SvgIcons.audioOffSmall
          else if (isMuted)
            SvgIcons.microphoneOffSmall,

          if (participant.source == MediaSourceKind.display)
            SvgIcons.screenShareSmall
          else if (isVideoDisabled)
            SvgIcons.videoOffSmall,
        ],
      ].whereNot((e) => e.isEmpty).toList();

      final Widget name = Transform.translate(
        // Adjust vertical alignment to match design
        // (default centering is slightly off).
        offset: Offset(0, -2),
        child: Text(
          participant.user.value?.title() ?? 'dot'.l10n * 3,
          style: style.fonts.normal.regular.onPrimary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );

      final Widget child;

      if (hovered || icons.isNotEmpty) {
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: style.colors.primaryAuxiliaryOpacity90,
            ),
            padding: EdgeInsets.all(8),
            height: 32,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...icons
                    .mapIndexed((i, e) {
                      final bool isLast = i == icons.length - 1;

                      return [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: e
                              .map((e) => SvgIcon(e, width: 16, height: 16))
                              .toList(),
                        ),
                        if ((isLast && hovered) || !isLast) _Separator(),
                      ];
                    })
                    .expand((e) => e),
                Flexible(
                  child: icons.isEmpty
                      ? name
                      : AnimatedSize(
                          duration: 150.milliseconds,
                          child: hovered ? name : const SizedBox.shrink(),
                        ),
                ),
              ],
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

/// Vertical separator between icon groups.
class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      color: style.colors.onPrimaryOpacity25,
      width: 1,
      height: 10,
    );
  }
}
