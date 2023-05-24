import 'package:flutter/material.dart';
import 'package:messenger/ui/page/home/page/chat/widget/animated_offset.dart';

class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool _hovered = false;
  Offset _shift = Offset.zero;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 300),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return MouseRegion(
        opaque: false,
        onEnter: (_) {
          _shift = Offset.zero;
          setState(() => _hovered = true);
        },
        onExit: (_) {
          _shift = Offset.zero;
          setState(() => _hovered = false);
        },
        onHover: (e) {
          // _shift = Offset(
          //   (e.localPosition.dx - constraints.maxWidth / 4) /
          //       (constraints.maxWidth / 4),
          //   (e.localPosition.dy - constraints.maxWidth / 4) /
          //       (constraints.maxWidth / 4),
          // );

          // print(_shift);

          setState(() {});
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            _controller.reset();
            _controller.forward();
          },
          child: AnimatedOffset(
            offset: _shift * 2,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 100),
              scale: _hovered ? 1.05 : 1,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 -
                        Tween<double>(begin: 0.0, end: 0.2)
                            .animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(0.0, 1.0,
                                    curve: Curves.ease),
                              ),
                            )
                            .value +
                        Tween<double>(begin: 0.0, end: 0.2)
                            .animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(0.5, 1.0,
                                    curve: Curves.ease),
                              ),
                            )
                            .value,
                    child: child,
                  );

                  return Transform.scale(
                    scale: 0.8 +
                        Tween<double>(begin: 0.0, end: 0.2)
                            .animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(
                                  0.0,
                                  0.5,
                                  curve: Curves.ease,
                                ),
                              ),
                            )
                            .value +
                        Tween<double>(begin: 0.0, end: 0.2)
                            .animate(
                              CurvedAnimation(
                                parent: _controller,
                                curve: const Interval(
                                  0.5,
                                  1.0,
                                  curve: Curves.ease,
                                ),
                              ),
                            )
                            .value,
                    child: child,
                  );
                },
                child: widget.child,
              ),
            ),
          ),
        ),
      );
    });
  }
}
