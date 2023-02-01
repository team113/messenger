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

import '/routes.dart';
import '/themes.dart';

/// Lightweight message which briefly displays at the bottom of the screen.
class FloatingSnackBar extends StatefulWidget {
  const FloatingSnackBar({
    super.key,
    required this.content,
    this.duration = const Duration(seconds: 2),
    this.onEnd,
  });

  /// The primary content of the [FloatingSnackBar].
  final Widget content;

  /// The amount of time the [FloatingSnackBar] should be displayed.
  final Duration duration;

  /// Callback, called when the [FloatingSnackBar] display stops.
  final VoidCallback? onEnd;

  /// Displays a [FloatingSnackBar] using an [OverlayEntry].
  static void show(String title) {
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (_) => FloatingSnackBar(
        content: Text(
          title,
          style: const TextStyle(color: Colors.black, fontSize: 15),
        ),
        onEnd: () {
          if (entry?.mounted == true) {
            entry?.remove();
          }
          entry = null;
        },
      ),
    );

    router.overlay?.insert(entry!);
  }

  @override
  State<FloatingSnackBar> createState() => _FloatingSnackBarState();
}

/// State of an [FloatingSnackBar] used to animate of appearance and
/// disappearance.
class _FloatingSnackBarState extends State<FloatingSnackBar>
    with SingleTickerProviderStateMixin {
  /// Initial value of the opacity animation.
  static const double _initialOpacity = 0.45;

  /// Final value of the opacity animation.
  static const double _finalOpacity = 1;

  /// Value of the opacity animation.
  double _opacity = _initialOpacity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => setState(() => _opacity = _finalOpacity));
  }

  /// Callback, called when completion of the opacity animation.
  Future<void> _onEnd() async {
    if (_opacity == _finalOpacity) {
      await Future.delayed(
        widget.duration,
        () {
          if (mounted) {
            setState(() => _opacity = _initialOpacity);
          }
        },
      );
    } else if (_opacity == _initialOpacity) {
      widget.onEnd?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(router.context!).extension<Style>()!;

    return Stack(
      children: [
        Positioned(
          bottom: 72,
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: GestureDetector(
              onTap: () => setState(() => _opacity = _initialOpacity),
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 120),
                onEnd: _onEnd,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: style.cardHoveredColor,
                    border: style.cardHoveredBorder,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        blurStyle: BlurStyle.outer,
                      ),
                    ],
                  ),
                  child: widget.content,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
