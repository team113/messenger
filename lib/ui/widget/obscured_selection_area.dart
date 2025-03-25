import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import '/routes.dart';

class ObscuredSelectionArea extends StatefulWidget {
  const ObscuredSelectionArea({
    super.key,
    this.focusNode,
    this.selectionControls,
    this.contextMenuBuilder = _defaultContextMenuBuilder,
    this.magnifierConfiguration,
    this.onSelectionChanged,
    required this.child,
  });

  /// Configuration for the magnifier in the selection region.
  final TextMagnifierConfiguration? magnifierConfiguration;

  /// An optional focus node to use as the focus node for this widget.
  final FocusNode? focusNode;

  /// Delegate to build the selection handles and toolbar.
  ///
  /// If it is null, the platform specific selection control is used.
  final TextSelectionControls? selectionControls;

  /// Builds the text selection toolbar when requested by the user.
  final SelectableRegionContextMenuBuilder? contextMenuBuilder;

  /// Called when the selected content changes.
  final ValueChanged<SelectedContent?>? onSelectionChanged;

  /// Child widget [SelectionArea] applies to.
  final Widget child;

  @override
  State<ObscuredSelectionArea> createState() => _ObscuredSelectionAreaState();

  static Widget _defaultContextMenuBuilder(
    BuildContext context,
    SelectableRegionState selectableRegionState,
  ) {
    return AdaptiveTextSelectionToolbar.selectableRegion(
      selectableRegionState: selectableRegionState,
    );
  }
}

class _ObscuredSelectionAreaState extends State<ObscuredSelectionArea> {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (router.obscuring.isNotEmpty) {
        return KeyedSubtree(key: _key, child: widget.child);
      }

      return SelectionArea(
        magnifierConfiguration: widget.magnifierConfiguration,
        focusNode: widget.focusNode,
        selectionControls: widget.selectionControls,
        contextMenuBuilder: widget.contextMenuBuilder,
        onSelectionChanged: widget.onSelectionChanged,
        child: KeyedSubtree(key: _key, child: widget.child),
      );
    });
  }
}
