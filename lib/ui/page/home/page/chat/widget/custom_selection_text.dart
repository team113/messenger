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
    required this.type,
    required this.groupId,
    required this.child,
  }) : super(key: key);

  /// Records a contact on the [CustomSelectionContainer].
  final ChatController controller;

  /// Selected text type.
  final SelectionItem type;

  /// Grouping multiple [SelectionData] in a group.
  final int groupId;

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
        selectionData: SelectionData(type, groupId),
        child: child,
      ),
    );
  }
}
