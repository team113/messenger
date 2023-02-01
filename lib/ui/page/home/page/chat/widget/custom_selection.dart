import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/util/platform_utils.dart';

/// Custom text selection widget.
class CustomSelection extends StatelessWidget {
  const CustomSelection({
    Key? key,
    required this.text,
    this.onSelected,
    this.enabled,
  }) : super(key: key);

  /// [Widget] with text for selecting it.
  final Widget text;

  /// Indicator whether selection is enabled or not.
  final RxBool? enabled;

  /// Callback called when some text was selected or unselected.
  final void Function(String text)? onSelected;

  @override
  Widget build(BuildContext context) {
    final Widget selectionArea = SelectionArea(
      contextMenuBuilder: (_, state) => PlatformUtils.isMobile
          ? AdaptiveTextSelectionToolbar.selectableRegion(
              selectableRegionState: state,
            )
          : const SizedBox(),
      onSelectionChanged: (s) => onSelected?.call(s?.plainText ?? ''),
      child: ContextMenuInterceptor(child: text),
    );

    if (enabled == null) {
      return selectionArea;
    } else {
      return Obx(() {
        if (enabled!.value) {
          return selectionArea;
        } else {
          return ContextMenuInterceptor(child: text);
        }
      });
    }
  }
}
