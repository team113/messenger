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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/tooltip_button.dart';
import '/ui/widget/svg/svg.dart';

/// Title bar which containing information about the call.
class TitleBar extends StatelessWidget {
  const TitleBar({
    super.key,
    required this.fullscreen,
    required this.constraints,
    this.children = const <Widget>[],
    this.height,
    this.onTap,
    this.toggleFullscreen,
  });

  /// Indicator whether the view is fullscreen or not.
  final bool fullscreen;

  /// Height of the [TitleBar].
  final double? height;

  /// Maximum width that satisfies the constraints.
  final BoxConstraints constraints;

  /// [Widget]s to display.
  final List<Widget> children;

  /// Callback, called when this [TitleBar] is tapped.
  final void Function()? onTap;

  /// Toggles fullscreen on and off.
  final void Function()? toggleFullscreen;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Container(
      key: const ValueKey('TitleBar'),
      color: style.colors.backgroundAuxiliaryLight,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Handles double tap to toggle fullscreen.
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: toggleFullscreen,
          ),

          // Left part of the title bar that displays the recipient or
          // the caller, its avatar and the call's state.
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: constraints,
              child: InkWell(
                onTap: onTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            ),
          ),

          // Right part of the title bar that displays buttons.
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TooltipButton(
                    onTap: toggleFullscreen,
                    hint: fullscreen
                        ? 'btn_fullscreen_exit'.l10n
                        : 'btn_fullscreen_enter'.l10n,
                    child: SvgImage.asset(
                      'assets/icons/fullscreen_${fullscreen ? 'exit' : 'enter'}.svg',
                      width: 12,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
