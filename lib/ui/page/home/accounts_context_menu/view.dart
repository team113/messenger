import 'dart:ui';

import 'package:flutter/material.dart';

class AccountsContextMenuView extends StatefulWidget {
  const AccountsContextMenuView({super.key, required this.child});

  /// widget that viewed in layout
  final Widget child;

  @override
  State<AccountsContextMenuView> createState() =>
      _AccountsContextMenuViewState();
}

class _AccountsContextMenuViewState extends State<AccountsContextMenuView> {
  late final OverlayPortalController _controller;

  @override
  initState() {
    _controller = OverlayPortalController();
    super.initState();
  }

  void _show() {
    _controller.show();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _controller,
      overlayChildBuilder: _buildOverlay,
      child: GestureDetector(
        onLongPress: _show,
        onSecondaryTap: _show,
        child: widget.child,
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _controller.hide();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),

          // вырез в нужном месте
          Positioned.fill(
            child: CustomPaint(
              painter: HolePainter(
                Rect.fromCenter(
                  center: Offset(320, 600),
                  width: 40,
                  height: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HolePainter extends CustomPainter {
  final Rect holeRect;

  HolePainter(this.holeRect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.clear;

    canvas.saveLayer(Offset.zero & size, Paint());

    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.transparent);

    canvas.drawRRect(
      RRect.fromRectAndRadius(holeRect, const Radius.circular(40)),
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HolePainter oldDelegate) =>
      holeRect != oldDelegate.holeRect;
}
