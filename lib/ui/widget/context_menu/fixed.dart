import 'package:flutter/material.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';

class FixedContextMenu extends StatefulWidget {
  const FixedContextMenu({
    Key? key,
    required this.objectKey,
    required this.actions,
    this.availableSpace = Rect.largest,
  }) : super(key: key);

  final GlobalKey objectKey;
  final Rect availableSpace;
  final List<ContextMenuButton> actions;

  @override
  State<FixedContextMenu> createState() => _FixedContextMenuState();
}

class _FixedContextMenuState extends State<FixedContextMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Positioned(child: child),
      ],
    );
  }
}
