import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/page/chat/widget/swipeable_status.dart';

import '../controller.dart';
import 'custom_selection_container.dart';

/// Specify the type of selected text [SelectionItem]
/// for better formatting when copying and cancel
/// the horizontal scroll timeline [SwipeableStatus].
class CustomSelectionText extends StatelessWidget {
  const CustomSelectionText({
    Key? key,
    required this.controller,
    required this.position,
    required this.type,
    this.animation,
    required this.child,
  }) : super(key: key);

  /// Records a contact on the [CustomSelectionContainer].
  final ChatController controller;

  /// Message position index.
  final int position;

  /// Selected text type.
  final SelectionItem type;

  /// Optional animation that controls a [SwipeableStatus].
  final AnimationController? animation;

  /// Widget in which there will be text to selection.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Rx<bool> isTap = controller.isTapMessage;

    return Listener(
      onPointerDown: (_) {
        if (!isTap.value) {
          isTap.value = true;
        }
      },
      onPointerUp: (_) {
        if (isTap.value) {
          isTap.value = false;
        }
      },
      onPointerCancel: (_) {
        if (isTap.value) {
          isTap.value = false;
        }
      },
      child: CustomSelectionContainer(
        controller: controller,
        selectionData: SelectionData(position, type),
        animation: animation,
        child: child,
      ),
    );
  }
}
