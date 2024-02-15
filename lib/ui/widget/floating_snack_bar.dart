// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import '/ui/page/home/widget/avatar.dart';

/// Animated message briefly displayed at the bottom of the screen.
///
/// Custom implementation of a default [SnackBar].
class FloatingSnackBar extends StatefulWidget {
  const FloatingSnackBar({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 1),
    this.onEnd,
    this.bottom = 16,
    this.offset,
  });

  /// Content to display in this [FloatingSnackBar].
  final Widget child;

  /// [Duration] to display this [FloatingSnackBar] for.
  final Duration duration;

  /// Callback, called when this [FloatingSnackBar] disappears.
  final VoidCallback? onEnd;

  /// Bottom margin to apply to this [FloatingSnackBar].
  final double bottom;

  final Offset? offset;

  static OverlayEntry? entry;

  /// Displays a [FloatingSnackBar] in a [Overlay] with the provided [title].
  static void show(String title, {double bottom = 16, Offset? at}) {
    final style = Theme.of(router.context!).style;

    // OverlayEntry? entry;

    entry?.remove();
    entry = OverlayEntry(
      builder: (_) => FloatingSnackBar(
        onEnd: () {
          if (entry?.mounted == true) {
            entry?.remove();
          }
          entry = null;
        },
        bottom: bottom,
        offset: at,
        child: Text(title, style: style.fonts.normal.regular.onPrimary),
      ),
    );

    router.overlay?.insert(entry!);
  }

  @override
  State<FloatingSnackBar> createState() => _FloatingSnackBarState();
}

/// State of a [FloatingSnackBar] maintaining the [_opacity].
class _FloatingSnackBarState extends State<FloatingSnackBar>
    with SingleTickerProviderStateMixin {
  /// Initial opacity of the [FloatingSnackBar].
  static const double _initialOpacity = 0;

  /// Final opacity of the [FloatingSnackBar].
  static const double _finalOpacity = 1;

  /// Current opacity of the [FloatingSnackBar].
  double _opacity = _initialOpacity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _opacity = _finalOpacity);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(router.context!).style;

    return LayoutBuilder(builder: (context, constraints) {
      double qx = 1, qy = 1;

      if (widget.offset != null) {
        if (widget.offset!.dx > (constraints.maxWidth) / 2) qx = -1;
        if (widget.offset!.dy > (constraints.maxHeight) / 2) qy = -1;
      }

      final Alignment alignment = Alignment(qx, qy);

      return Stack(
        children: [
          Positioned(
            top: widget.offset?.dy,
            left: widget.offset?.dx,
            bottom: widget.offset == null ? widget.bottom : null,
            width: widget.offset == null
                ? MediaQuery.of(context).size.width
                : null,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _opacity = _initialOpacity),
                child: FractionalTranslation(
                  translation: const Offset(-0.5, 0.5),
                  child: AnimatedOpacity(
                    opacity: _opacity,
                    duration: const Duration(milliseconds: 120),
                    onEnd: _onEnd,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        // color: style.cardColor.darken(0.03),
                        color: style.colors.onSecondaryOpacity50,
                        border: style.cardHoveredBorder,
                        boxShadow: [
                          BoxShadow(
                            color: style.colors.onBackgroundOpacity20,
                            blurRadius: 8,
                            blurStyle: BlurStyle.outer.workaround,
                          ),
                        ],
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Changes the [_opacity] after some delay to the [_initialOpacity] and
  /// invokes the [FloatingSnackBar.onEnd] afterwards.
  Future<void> _onEnd() async {
    if (_opacity == _finalOpacity) {
      await Future.delayed(widget.duration, () {
        if (mounted) {
          setState(() => _opacity = _initialOpacity);
        }
      });
    } else if (_opacity == _initialOpacity) {
      widget.onEnd?.call();
    }
  }
}
