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

import '/util/platform_utils.dart';
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
    this.onClosed,
  });

  /// Position of [ContextMenu].
  final Offset position;

  /// [ContextMenuItem]s representing the actions of the [ContextMenu].
  final List<ContextMenuItem> actions;

  /// Callback, called when animation of this [ContextMenuOverlay] is
  /// [AnimationStatus.dismissed].
  final void Function()? onDismissed;

  /// Callback, called when this [ContextMenuOverlay] starts closing.
  final void Function()? onClosed;

  @override
  State<ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

/// State of a [ContextMenuOverlay] maintaining the [_controller].
class _ContextMenuOverlayState extends State<ContextMenuOverlay>
    with TickerProviderStateMixin {
  /// Controller animating [FadeTransition].
  late final AnimationController _controller;

  /// Animation of [FadeTransition].
  late final Animation<double> _animation;

  /// Closes the [ContextMenu].
  Future<void> _dismiss() async {
    widget.onClosed?.call();
    await _controller.reverse();
    widget.onDismissed?.call();
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // macOS users are used to behaviour different from Windows.
    final bool consumeOutsideTaps = PlatformUtils.isMacOS;

    return LayoutBuilder(
      builder: (_, constraints) {
        double qx = 1, qy = 1;
        if (widget.position.dx > (constraints.maxWidth) / 2) qx = -1;
        if (widget.position.dy > (constraints.maxHeight) / 2) qy = -1;
        final Alignment alignment = Alignment(qx, qy);

        return FadeTransition(
          opacity: _animation,
          child: Stack(
            children: [
              if (consumeOutsideTaps)
                MouseRegion(cursor: SystemMouseCursors.basic, opaque: false),
              Positioned(
                left: widget.position.dx,
                top: widget.position.dy,
                child: FractionalTranslation(
                  translation: Offset(
                    alignment.x > 0 ? 0 : -1,
                    alignment.y > 0 ? 0 : -1,
                  ),
                  child: TapRegion(
                    consumeOutsideTaps: consumeOutsideTaps,
                    onTapInside: (_) => _dismiss(),
                    onTapOutside: (_) => _dismiss(),
                    child: ContextMenu(actions: widget.actions),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
