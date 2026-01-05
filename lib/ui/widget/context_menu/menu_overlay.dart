// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:flutter/material.dart';

import '/themes.dart';
import 'menu.dart';

/// [ContextMenu] with [FadeTransition].
///
/// Intended to be used as an [OverlayEntry].
class ContextMenuOverlay extends StatefulWidget {
  const ContextMenuOverlay({
    super.key,
    required this.position,
    required this.actions,
    this.onDismissed,
  });

  /// Position of [ContextMenu].
  final Offset position;

  /// [ContextMenuItem]s representing the actions of the [ContextMenu].
  final List<ContextMenuItem> actions;

  /// Callback, called when animation of this [ContextMenuOverlay] is
  /// [AnimationStatus.dismissed].
  final void Function()? onDismissed;

  @override
  State<ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

/// State of a [ContextMenuOverlay] maintaining the [_controller].
class _ContextMenuOverlayState extends State<ContextMenuOverlay>
    with TickerProviderStateMixin {
  /// Controller animating [FadeTransition].
  AnimationController? _controller;

  /// Animation of [FadeTransition].
  late Animation<double> _animation;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(parent: _controller!, curve: Curves.easeIn);

    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return LayoutBuilder(
      builder: (_, constraints) {
        double qx = 1, qy = 1;
        if (widget.position.dx > (constraints.maxWidth) / 2) qx = -1;
        if (widget.position.dy > (constraints.maxHeight) / 2) qy = -1;
        final Alignment alignment = Alignment(qx, qy);

        return Listener(
          onPointerUp: (_) async {
            await _controller?.reverse();
            widget.onDismissed?.call();
          },
          child: FadeTransition(
            opacity: _animation,
            child: Container(
              color: style.colors.transparent,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: widget.position.dx,
                    top: widget.position.dy,
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
      },
    );
  }
}
