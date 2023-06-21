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

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/call/widget/dock.dart';
import '/ui/page/home/widget/animated_slider.dart';

/// [Dock] which is used to handle the incoming and outgoing calls
/// with buttons.
class StyledDock extends StatelessWidget {
  const StyledDock({
    super.key,
    this.dockKey,
    this.showBottomUi = true,
    this.child,
    this.onEnter,
    this.onHover,
    this.onExit,
    this.listener,
  });

  /// [Key] for handling [dock] widget states.
  final GlobalKey<State<StatefulWidget>>? dockKey;

  /// Indicator whether to show the [child].
  final bool? showBottomUi;

  /// [Widget] to display at the bottom of this [StyledDock].
  final Widget? child;

  /// Callback, called when the mouse cursor enters the area of this
  /// [StyledDock].
  final void Function(PointerEnterEvent)? onEnter;

  /// Callback, called when the mouse cursor moves in the area of this
  /// [StyledDock].
  final void Function(PointerHoverEvent)? onHover;

  /// Callback, called when the mouse cursor leaves the area of this
  /// [StyledDock].
  final void Function(PointerExitEvent)? onExit;

  /// Callback, called every time the value of the animation changes.
  final void Function()? listener;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Padding(
      key: const Key('DockedPadding'),
      padding: const EdgeInsets.only(bottom: 5),
      child: AnimatedSlider(
        key: const Key('DockedPanelPadding'),
        isOpen: showBottomUi!,
        duration: 400.milliseconds,
        translate: false,
        listener: listener,
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
                )
              ],
            ),
            margin: const EdgeInsets.fromLTRB(10, 2, 10, 2),
            child: ConditionalBackdropFilter(
              key: dockKey,
              borderRadius: BorderRadius.circular(30),
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: style.colors.onSecondaryOpacity20,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 5,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
