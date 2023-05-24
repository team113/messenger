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
import '../reorderable_fit.dart';
import '/themes.dart';
import '/ui/page/call/component/desktop.dart';
import '/ui/page/call/controller.dart';

/// [Widget] that serves as a drag target for a list of [Participant].
///
/// It provides a secondary data source for the main widget and allows dragging
/// and dropping of participants between the two widgets.
class SecondaryTarget extends StatelessWidget {
  const SecondaryTarget({
    super.key,
    required this.size,
    required this.secondaryAxis,
    required this.secondary,
    required this.doughDraggedRenderer,
    required this.primaryDrags,
    required this.secondaryAlignment,
    this.onWillAccept,
    this.onAccept,
  });

  /// [Size] that represents the size of this [SecondaryTarget].
  final Size size;

  /// [Axis] enumeration value that specifies the secondary axis of this
  /// [SecondaryTarget].
  final Axis secondaryAxis;

  /// [Rx] participant that contains a list of [Participant] objects.
  final List<Participant> secondary;

  /// [Rx] participant that contains a [Participant] object.
  final Participant? doughDraggedRenderer;

  /// Count of a primary drag operations that have been performed.
  final int primaryDrags;

  /// [Rx] object that contains an [Alignment] object.
  final Alignment? secondaryAlignment;

  /// Called to determine whether this widget is interested in receiving a
  /// given piece of data being dragged over this drag target.
  final bool Function(DragData?)? onWillAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  final void Function(DragData)? onAccept;

  @override
  Widget build(BuildContext context) {
    // Pre-calculate the [ReorderableFit]'s size.
    double panelSize = max(
      ReorderableFit.calculateSize(
        maxSize: size.shortestSide / 4,
        constraints: Size(size.width, size.height - 45),
        axis: size.width >= size.height ? Axis.horizontal : Axis.vertical,
        length: secondary.length,
      ),
      130,
    );

    return AnimatedOpacity(
      key: const Key('SecondaryTargetAnimatedSwitcher'),
      duration: 200.milliseconds,
      opacity: secondary.isEmpty && doughDraggedRenderer != null ? 1.0 : 0.0,
      child: Align(
        alignment: secondaryAxis == Axis.horizontal
            ? Alignment.centerRight
            : Alignment.topCenter,
        child: SizedBox(
          width: secondaryAxis == Axis.horizontal
              ? panelSize / 1.6
              : double.infinity,
          height: secondaryAxis == Axis.horizontal
              ? double.infinity
              : panelSize / 1.6,
          child: DragTarget<DragData>(
            onWillAccept: onWillAccept,
            onAccept: onAccept,
            builder: (context, candidate, rejected) {
              return IgnorePointer(
                child: AnimatedOpacity(
                  key: const Key('SecondaryTargetAnimatedSwitcher'),
                  duration: 200.milliseconds,
                  opacity: primaryDrags >= 1 ? 1.0 : 0.0,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: secondaryAxis == Axis.horizontal ? 1 : 0,
                      bottom: secondaryAxis == Axis.vertical ? 1 : 0,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        left: secondaryAxis == Axis.horizontal
                            ? const BorderSide(
                                color: Color(0xFF888888),
                                width: 1,
                              )
                            : BorderSide.none,
                        bottom: secondaryAxis == Axis.vertical
                            ? const BorderSide(
                                color: Color(0xFF888888),
                                width: 1,
                              )
                            : BorderSide.none,
                      ),
                      boxShadow: const [
                        CustomBoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 8,
                          blurStyle: BlurStyle.outer,
                        )
                      ],
                    ),
                    child: ConditionalBackdropFilter(
                      child: AnimatedContainer(
                        duration: 300.milliseconds,
                        color: candidate.isNotEmpty
                            ? const Color(0x10FFFFFF)
                            : const Color(0x00FFFFFF),
                        child: Center(
                          child: SizedBox(
                            width: secondaryAxis == Axis.horizontal
                                ? min(panelSize, 150 + 44)
                                : null,
                            height: secondaryAxis == Axis.horizontal
                                ? null
                                : min(panelSize, 150 + 44),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.ease,
                                  scale: candidate.isNotEmpty ? 1.06 : 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0x40000000),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 35,
                                        color: Colors.white,
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
      ),
    );
  }
}
