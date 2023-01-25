// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

/// Lightweight message which briefly displays at the bottom of the screen.
class FloatingSnackBar extends StatefulWidget {
  const FloatingSnackBar({
    super.key,
    required this.content,
    this.duration = const Duration(seconds: 2),
    this.onTap,
  });

  /// The primary content of the snack bar.
  final Widget content;

  /// The amount of time the snack bar should be displayed.
  final Duration duration;

  /// Callback, called when this [FloatingSnackBar] is tapped.
  final VoidCallback? onTap;

  @override
  State<FloatingSnackBar> createState() => _FloatingSnackBarState();
}

/// State of an [FloatingSnackBar] used to animate of appearance and
/// disappearance.
class _FloatingSnackBarState extends State<FloatingSnackBar>
    with SingleTickerProviderStateMixin {
  /// [Curve] animation of appearance and disappearance.
  static const Curve _snackBarFadeCurve =
      Interval(0.45, 1.0, curve: Curves.fastOutSlowIn);

  /// Indicator whether the animation is forward or not.
  bool _isForward = true;

  /// [AnimationController] of this [FloatingSnackBar].
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 250),
    vsync: this,
  )
    ..forward()
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(
          widget.duration,
          () {
            if (mounted && _isForward) {
              _isForward = false;
              _controller.reverse();
            }
          },
        );
      } else if (status == AnimationStatus.dismissed) {
        widget.onTap?.call();
      }
    });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              bottom: 72,
              width: constraints.maxWidth,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_isForward) {
                      _isForward = false;
                      _controller.reverse();
                    }
                  },
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _controller,
                      curve: _snackBarFadeCurve,
                    ),
                    child: widget.content,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
