import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller.dart';
import 'custom_selection_container.dart';

/// [CustomSelectionText] to copy text and listen for click.
class CustomSelectionText extends StatelessWidget {
  const CustomSelectionText({
    Key? key,
    required this.selections,
    required this.isTapMessage,
    required this.position,
    required this.type,
    this.animation,
    required this.child,
  }) : super(key: key);

  /// Storage [SelectionData].
  final Map<int, List<SelectionData>> selections;

  /// Clicking on [SelectionData].
  final Rx<bool> isTapMessage;

  /// Message position index.
  final int position;

  /// Selected text type.
  final SelectionItem type;

  /// Controller for an animation..
  final AnimationController? animation;

  /// [Widget] in which there will be text to selection.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => isTapMessage.value = true,
      onPointerUp: (_) => isTapMessage.value = false,
      onPointerCancel: (_) => isTapMessage.value = false,
      child: CustomSelectionContainer(
        selections: selections,
        position: position,
        type: type,
        animation: animation,
        child: child,
      ),
    );
  }
}
