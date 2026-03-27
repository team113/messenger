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

import '/domain/repository/chat.dart';
import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';

/// Title bar to put to the [desktopCall].
class TitleBar extends StatelessWidget {
  const TitleBar({
    super.key,
    required this.chat,
    required this.titleBuilder,
    this.height,
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
  final Widget Function(BuildContext) titleBuilder;

  /// Callback, called when fullscreen button is pressed.
  final void Function()? toggleFullscreen;

  /// Callback, called when [SvgIcons.callFloating] icon button is pressed.
  final void Function()? onFloating;

  /// Callback, called when [SvgIcons.callSide] icon button is pressed.
  final void Function()? onSecondary;

  /// Callback, called when [SvgIcons.callGallery] icon button is pressed.
  final void Function()? onPrimary;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      key: const ValueKey('TitleBar'),
      color: style.colors.backgroundAuxiliaryLight,
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left part of the title bar that displays the recipient or the
          // caller, its avatar and the call's state.
          Expanded(
            child: _recognizer(
              context,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 10),
                  AvatarWidget.fromRxChat(chat, radius: AvatarRadius.smallest),
                  const SizedBox(width: 8),
                  Flexible(
                    child: DefaultTextStyle(
                      style: style.fonts.small.regular.onPrimary,
                      overflow: TextOverflow.ellipsis,
                      child: titleBuilder(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right part of the title bar that displays buttons.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _recognizer(context, const SizedBox(width: 6)),
              AnimatedButton(
                enabled: onPrimary != null,
                onPressed: onPrimary,
                child: const SvgIcon(SvgIcons.callGallery),
              ),
              _recognizer(context, const SizedBox(width: 16)),
              AnimatedButton(
                enabled: onFloating != null,
                onPressed: onFloating,
                child: const SvgIcon(SvgIcons.callFloating),
              ),
              _recognizer(context, const SizedBox(width: 16)),
              AnimatedButton(
                enabled: onSecondary != null,
                onPressed: onSecondary,
                child: const SvgIcon(SvgIcons.callSide),
              ),
              _recognizer(context, const SizedBox(width: 16)),
              AnimatedButton(
                enabled: toggleFullscreen != null,
                onPressed: toggleFullscreen,
                child: SvgIcon(
                  fullscreen
                      ? SvgIcons.fullscreenExitSmall
                      : SvgIcons.fullscreenEnterSmall,
                ),
              ),
              _recognizer(context, const SizedBox(width: 13)),
            ],
          ),
        ],
      ),
    );
  }

  /// Returns the [GestureDetector] invoking [toggleFullscreen] over the
  /// [child].
  Widget _recognizer(BuildContext context, Widget child) {
    final style = Theme.of(context).style;

    return GestureDetector(
      onDoubleTap: toggleFullscreen,
      child: Container(
        color: style.colors.transparent,
        height: double.infinity,
        child: child,
      ),
    );
  }
}
