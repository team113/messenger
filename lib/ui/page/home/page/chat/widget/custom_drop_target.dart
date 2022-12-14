import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Wraps [DropTarget] widget with enabling only last [DropTarget].
class CustomDropTarget extends StatefulWidget {
  const CustomDropTarget({
    required Key key,
    this.onDragDone,
    this.onDragEntered,
    this.onDragExited,
    required this.child,
  }) : super(key: key);

  /// Child [Widget].
  final Widget child;

  /// Callback called on [DropTarget.onDragDone].
  final void Function(DropDoneDetails)? onDragDone;

  /// Callback called on [DropTarget.onDragEntered].
  final void Function(DropEventDetails)? onDragEntered;

  /// Callback called on [DropTarget.onDragExited].
  final void Function(DropEventDetails)? onDragExited;

  @override
  State<CustomDropTarget> createState() => _CustomDropTargetState();
}

/// State of [CustomDropTarget].
class _CustomDropTargetState extends State<CustomDropTarget> {
  /// List of [CustomDropTarget]s [Key]s.
  static final RxList<Key> keys = RxList<Key>([]);

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      keys.add(widget.key!);
    });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      keys.remove(widget.key);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return DropTarget(
        enable: keys.lastOrNull == widget.key,
        onDragDone: widget.onDragDone,
        onDragEntered: widget.onDragEntered,
        onDragExited: widget.onDragExited,
        child: widget.child,
      );
    });
  }
}
