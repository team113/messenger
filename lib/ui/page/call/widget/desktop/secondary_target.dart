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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../conditional_backdrop.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/component/desktop.dart';
import '/ui/page/call/controller.dart';

class SecondaryTarget extends StatelessWidget {
  const SecondaryTarget({
    super.key,
    required this.axis,
    required this.size,
    required this.participant,
    required this.drags,
    this.draggableParticipant,
    this.onWillAccept,
    this.onAccept,
  });

  /// [Axis] along which the [SecondaryTarget] is aligned.
  final Axis axis;

  /// Size of this [SecondaryTarget] widget.
  final double size;

  /// [Participant]s to display.
  final List<Participant> participant;

  /// [Participant] being dragged currently with its dough broken.
  final Participant? draggableParticipant;

  /// Count of a currently happening drags of the videos.
  final int drags;

  /// Called to determine whether this widget is interested in receiving a
  /// given piece of data being dragged over this drag target.
  final bool Function(DragData?)? onWillAccept;

  /// Called when an acceptable piece of data was dropped over this
  /// drag target.
  final void Function(DragData)? onAccept;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(router.context!).extension<Style>()!;

    // Axis secondaryAxis =
    //     c.size.width >= c.size.height ? Axis.horizontal : Axis.vertical;

    // // Pre-calculate the [ReorderableFit]'s size.
    // double panelSize = max(
    //   ReorderableFit.calculateSize(
    //     maxSize: c.size.shortestSide / 4,
    //     constraints: Size(c.size.width, c.size.height - 45),
    //     axis: c.size.width >= c.size.height ? Axis.horizontal : Axis.vertical,
    //     length: c.secondary.length,
    //   ),
    //   130,
    // );

    return AnimatedSwitcher(
      key: const Key('SecondaryTargetAnimatedSwitcher'),
      duration: 200.milliseconds,
      child: participant.isEmpty && draggableParticipant != null
          ? Align(
              alignment: axis == Axis.horizontal
                  ? Alignment.centerRight
                  : Alignment.topCenter,
              child: SizedBox(
                width: axis == Axis.horizontal ? size / 1.6 : double.infinity,
                height: axis == Axis.horizontal ? double.infinity : size / 1.6,
                child: DragTarget<DragData>(
                  onWillAccept: onWillAccept,
                  onAccept: onAccept,
                  builder: (context, candidate, rejected) {
                    return IgnorePointer(
                      child: AnimatedOpacity(
                        key: const Key('SecondaryTargetAnimatedSwitcher'),
                        duration: 200.milliseconds,
                        opacity: drags >= 1 ? 1 : 0,
                        child: Container(
                          padding: EdgeInsets.only(
                            left: axis == Axis.horizontal ? 1 : 0,
                            bottom: axis == Axis.vertical ? 1 : 0,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              left: axis == Axis.horizontal
                                  ? BorderSide(
                                      color: style.colors.secondary,
                                      width: 1,
                                    )
                                  : BorderSide.none,
                              bottom: axis == Axis.vertical
                                  ? BorderSide(
                                      color: style.colors.secondary,
                                      width: 1,
                                    )
                                  : BorderSide.none,
                            ),
                            boxShadow: [
                              CustomBoxShadow(
                                color: style.colors.onBackgroundOpacity20,
                                blurRadius: 8,
                                blurStyle: BlurStyle.outer,
                              )
                            ],
                          ),
                          child: ConditionalBackdropFilter(
                            child: AnimatedContainer(
                              duration: 300.milliseconds,
                              color: candidate.isNotEmpty
                                  ? style.colors.onPrimaryOpacity7
                                  : style.colors.transparent,
                              child: Center(
                                child: SizedBox(
                                  width: axis == Axis.horizontal
                                      ? min(size, 150 + 44)
                                      : null,
                                  height: axis == Axis.horizontal
                                      ? null
                                      : min(size, 150 + 44),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedScale(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.ease,
                                        scale: candidate.isNotEmpty ? 1.06 : 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: style
                                                .colors.onBackgroundOpacity27,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(
                                              10,
                                            ),
                                            child: Icon(
                                              Icons.add_rounded,
                                              size: 35,
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          : Container(),
    );
  }
}
