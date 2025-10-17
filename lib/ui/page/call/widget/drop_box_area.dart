// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/routes.dart';
import '/themes.dart';
import 'drop_box.dart';

/// [DragTarget] with a [DropBox] within it.
class DropBoxArea<T extends Object> extends StatelessWidget {
  const DropBoxArea({
    super.key,
    this.axis,
    this.onWillAccept,
    this.onAccept,
    this.size = 50,
    this.visible = true,
  });

  /// Indicator whether this [DropBoxArea] should be visible.
  final bool visible;

  /// [Axis] to align this [DropBoxArea].
  final Axis? axis;

  /// Size of this [DropBoxArea] widget.
  final double size;

  /// Callback, called to determine whether this widget is interested in
  /// receiving the [T] being dragged over this target.
  final bool Function(T?)? onWillAccept;

  /// Callback, called when an acceptable [T] was dropped over this target.
  final void Function(T)? onAccept;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(router.context!).style;

    return Align(
      alignment: axis == Axis.horizontal
          ? Alignment.centerRight
          : Alignment.topCenter,
      child: SizedBox(
        width: axis == Axis.horizontal ? size / 1.6 : double.infinity,
        height: axis == Axis.horizontal ? double.infinity : size / 1.6,
        child: DragTarget<T>(
          onAcceptWithDetails: (e) => onAccept?.call(e.data),
          onWillAcceptWithDetails: (e) => onWillAccept?.call(e.data) ?? true,
          builder: (context, candidate, rejected) {
            return IgnorePointer(
              child: AnimatedOpacity(
                duration: 200.milliseconds,
                opacity: visible ? 1 : 0,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: axis == Axis.vertical ? 1 : 0,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      left: axis == Axis.horizontal
                          ? BorderSide(color: style.colors.secondary, width: 1)
                          : BorderSide.none,
                      bottom: axis == Axis.vertical
                          ? BorderSide(color: style.colors.secondary, width: 1)
                          : BorderSide.none,
                    ),
                    boxShadow: [
                      CustomBoxShadow(
                        color: style.colors.onBackgroundOpacity20,
                        blurRadius: 8,
                        blurStyle: BlurStyle.outer,
                      ),
                    ],
                  ),
                  child: AnimatedContainer(
                    duration: 300.milliseconds,
                    color: candidate.isNotEmpty
                        ? style.colors.onPrimaryOpacity7
                        : style.colors.transparent,
                    child: Center(
                      child: SizedBox(
                        width: axis == Axis.horizontal
                            ? min(size, 150 + 44)
                            : null,
                        height: axis == Axis.horizontal
                            ? null
                            : min(size, 150 + 44),
                        child: const DropBox(withBlur: false, dense: true),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
