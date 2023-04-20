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

import '../controller.dart';
import '../component/desktop.dart';
import '../widget/conditional_backdrop.dart';
import '/themes.dart';

import 'reorderable_fit.dart';

/// [DragTarget] of an empty [_secondaryView].
class SecondaryTargetWidget extends StatelessWidget {
  const SecondaryTargetWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return Obx(() {
        Axis secondaryAxis =
            c.size.width >= c.size.height ? Axis.horizontal : Axis.vertical;

        // Pre-calculate the [ReorderableFit]'s size.
        double panelSize = max(
          ReorderableFit.calculateSize(
            maxSize: c.size.shortestSide / 4,
            constraints: Size(c.size.width, c.size.height - 45),
            axis:
                c.size.width >= c.size.height ? Axis.horizontal : Axis.vertical,
            length: c.secondary.length,
          ),
          130,
        );

        return AnimatedSwitcher(
          key: const Key('SecondaryTargetAnimatedSwitcher'),
          duration: 200.milliseconds,
          child: c.secondary.isEmpty && c.doughDraggedRenderer.value != null
              ? Align(
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
                    child: DragTarget<DesktopDragData>(
                      onWillAccept: (d) => d?.chatId == c.chatId.value,
                      onAccept: (DesktopDragData d) {
                        if (secondaryAxis == Axis.horizontal) {
                          c.secondaryAlignment.value = Alignment.centerRight;
                        } else {
                          c.secondaryAlignment.value = Alignment.topCenter;
                        }
                        c.unfocus(d.participant);
                      },
                      builder: (context, candidate, rejected) {
                        return Obx(() {
                          return IgnorePointer(
                            child: AnimatedSwitcher(
                              key: const Key('SecondaryTargetAnimatedSwitcher'),
                              duration: 200.milliseconds,
                              child: c.primaryDrags.value >= 1
                                  ? Container(
                                      padding: EdgeInsets.only(
                                        left: secondaryAxis == Axis.horizontal
                                            ? 1
                                            : 0,
                                        bottom: secondaryAxis == Axis.vertical
                                            ? 1
                                            : 0,
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
                                              width: secondaryAxis ==
                                                      Axis.horizontal
                                                  ? min(panelSize, 150 + 44)
                                                  : null,
                                              height: secondaryAxis ==
                                                      Axis.horizontal
                                                  ? null
                                                  : min(panelSize, 150 + 44),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  AnimatedScale(
                                                    duration: const Duration(
                                                        milliseconds: 300),
                                                    curve: Curves.ease,
                                                    scale: candidate.isNotEmpty
                                                        ? 1.06
                                                        : 1,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0x40000000),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                      ),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.all(10),
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
                                    )
                                  : Container(key: UniqueKey()),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                )
              : Container(),
        );
      });
    });
  }
}
