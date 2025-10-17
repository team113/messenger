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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/themes.dart';
import '/ui/page/home/widget/animated_slider.dart';

/// [AnimatedSlider] wrapping a [child] within dock-decorated [Container].
class DockDecorator extends StatelessWidget {
  const DockDecorator({
    super.key,
    this.show = true,
    this.dockKey,
    this.onEnter,
    this.onHover,
    this.onExit,
    this.onAnimation,
    this.child,
  });

  /// Indicator whether the [AnimatedSlider] should display the [child].
  final bool show;

  /// [Key] of the [child] wrapping [Container] itself.
  final Key? dockKey;

  /// Callback, called when the mouse cursor enters the area of this
  /// [DockDecorator].
  final void Function(PointerEnterEvent)? onEnter;

  /// Callback, called when the mouse cursor moves in the area of this
  /// [DockDecorator].
  final void Function(PointerHoverEvent)? onHover;

  /// Callback, called when the mouse cursor leaves the area of this
  /// [DockDecorator].
  final void Function(PointerExitEvent)? onExit;

  /// Callback, called every time the value of [AnimatedSlider] animation
  /// changes.
  final void Function()? onAnimation;

  /// [Widget] wrapped by this [DockDecorator].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Padding(
      key: const Key('DockedPadding'),
      padding: const EdgeInsets.only(bottom: 5),
      child: AnimatedSlider(
        key: const Key('DockedPanelPadding'),
        isOpen: show,
        duration: 400.milliseconds,
        translate: false,
        listener: onAnimation,
        child: MouseRegion(
          onEnter: onEnter,
          onHover: onHover,
          onExit: onExit,
          child: Container(
            decoration: BoxDecoration(
              color: style.colors.transparent,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                CustomBoxShadow(
                  color: style.colors.onBackgroundOpacity20,
                  blurRadius: 8,
                  blurStyle: BlurStyle.outer,
                ),
              ],
            ),
            margin: const EdgeInsets.fromLTRB(10, 2, 10, 2),
            child: Container(
              key: dockKey,
              decoration: BoxDecoration(
                color: style.colors.primaryAuxiliaryOpacity90,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
