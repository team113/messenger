import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';

class ContextMenuOverlay extends StatefulWidget {
  final Offset position;
  final EdgeInsets margin;
  final List<ContextMenuItem> actions;
  final void Function() onOverlayClose;

  const ContextMenuOverlay({
    super.key,
    required this.position,
    required this.margin,
    required this.actions,
    required this.onOverlayClose,
  });

  @override
  State<ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<ContextMenuOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (style, _) = Theme.of(context).styles;

    return LayoutBuilder(builder: (_, constraints) {
      double qx = 1, qy = 1;
      if (widget.position.dx > (constraints.maxWidth) / 2) qx = -1;
      if (widget.position.dy > (constraints.maxHeight) / 2) qy = -1;
      final Alignment alignment = Alignment(qx, qy);

      return Listener(
        onPointerUp: (_) async {
          await _controller.reverse();
          widget.onOverlayClose();
        },
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Container(
            color: style.colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: widget.position.dx +
                      widget.margin.left -
                      widget.margin.right,
                  top: widget.position.dy +
                      widget.margin.top -
                      widget.margin.bottom,
                  child: FractionalTranslation(
                    translation: Offset(
                      alignment.x > 0 ? 0 : -1,
                      alignment.y > 0 ? 0 : -1,
                    ),
                    child: ContextMenu(actions: widget.actions),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
