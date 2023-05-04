import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../themes.dart';
import '../../component/desktop.dart';
import '../../controller.dart';
import '../conditional_backdrop.dart';
import '../reorderable_fit.dart';

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
    required this.unfocus,
    this.onWillAccept,
  });

  /// [Size] object that represents the size of the widget.
  final Size size;

  /// [Axis] enumeration value that specifies the secondary axis of the widget.
  final Axis secondaryAxis;

  /// [RxList] object that contains a list of Participant objects.
  ///
  /// It represents the secondary data source of the widget.
  final RxList<Participant> secondary;

  /// [Rx] object that contains a Participant object.
  ///
  /// It represents the participant that is currently being dragged.
  final Rx<Participant?> doughDraggedRenderer;

  /// Callback function that called when a drag operation enters the target
  /// [Widget] to determine whether the [Widget] can accept the dragged data.
  final bool Function(DragData?)? onWillAccept;

  /// [RxInt] object that represents the number of primary drag operations
  /// that have been performed.
  final RxInt primaryDrags;

  /// [Rx] object that contains an [Alignment] object.
  ///
  /// It represents the alignment of the secondary widget with respect
  /// to the primary [Widget].
  final Rx<Alignment?> secondaryAlignment;

  /// Callback [Function] that called to remove focus from the
  /// specified [Participant].
  final void Function(Participant) unfocus;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
        opacity:
            secondary.isEmpty && doughDraggedRenderer.value != null ? 1.0 : 0.0,
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
              onAccept: (DragData d) {
                if (secondaryAxis == Axis.horizontal) {
                  secondaryAlignment.value = Alignment.centerRight;
                } else {
                  secondaryAlignment.value = Alignment.topCenter;
                }
                unfocus(d.participant);
              },
              builder: (context, candidate, rejected) {
                return IgnorePointer(
                  child: AnimatedOpacity(
                    key: const Key('SecondaryTargetAnimatedSwitcher'),
                    duration: 200.milliseconds,
                    opacity: primaryDrags.value >= 1 ? 1.0 : 0.0,
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
    });
  }
}
