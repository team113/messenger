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

import '../../../widget/animated_button.dart';
import '/domain/repository/chat.dart';
import '/themes.dart';
import '/ui/page/call/widget/tooltip_button.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/svg/svg.dart';

/// Title bar to put to the [desktopCall].
class TitleBar extends StatelessWidget {
  const TitleBar({
    super.key,
    required this.chat,
    required this.title,
    this.height,
    this.onTap,
    this.toggleFullscreen,
    this.fullscreen = false,
    this.onFloating,
    this.onSecondary,
    this.onPrimary,
  });

  /// Indicator whether fullscreen icon should be turned on.
  final bool fullscreen;

  /// Height of this [TitleBar].
  final double? height;

  /// [RxChat] to display in this [TitleBar].
  final RxChat? chat;

  /// Title of this [TitleBar].
  final String title;

  /// Callback, called when this [TitleBar] is tapped.
  final void Function()? onTap;

  /// Callback, called to toggle fullscreen on and off.
  final void Function()? toggleFullscreen;

  /// Callback, called to enter 'floating window' display mode.
  final void Function()? onFloating;

  /// Callback, called to enter 'side panel' display mode.
  final void Function()? onSecondary;

  /// Callback, called to enter 'all equal' display mode.
  final void Function()? onPrimary;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left part of the title bar that displays the recipient or the
              // caller, its avatar and the call's state.
              Flexible(
                child: InkWell(
                  onTap: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 10),
                      AvatarWidget.fromRxChat(chat,
                          radius: AvatarRadius.smallest),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: style.fonts.small.regular.onPrimary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right part of the title bar that displays buttons.
              Padding(
                padding: const EdgeInsets.only(right: 3, left: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedButton(
                      onPressed: onPrimary,
                      child: const SvgIcon(SvgIcons.callGallery),
                    ),
                    const SizedBox(width: 16),
                    AnimatedButton(
                      onPressed: onFloating,
                      child: const SvgIcon(SvgIcons.callFloating),
                    ),
                    const SizedBox(width: 16),
                    AnimatedButton(
                      onPressed: onSecondary,
                      child: const SvgIcon(SvgIcons.callSide),
                    ),
                    const SizedBox(width: 16),
                    AnimatedButton(
                      onPressed: toggleFullscreen,
                      child: SvgIcon(
                        fullscreen
                            ? SvgIcons.fullscreenExitSmall
                            : SvgIcons.fullscreenEnterSmall,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
