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
import 'package:get/get.dart';

import '/themes.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import 'buttons.dart';

/// [AnimatedButton] with an [icon].
class ChatMoreWidget extends StatefulWidget {
  /// Constructs a [ChatMoreWidget] from the provided [ChatButton].
  ChatMoreWidget(
    ChatButton button, {
    super.key,
    this.pinned = false,
    this.onPin,
    void Function()? onPressed,
  })  : label = button.hint,
        icon = Transform.translate(
          offset: button.offsetMini,
          child: SvgImage.asset(
            'assets/icons/${button.assetMini ?? button.asset}${button.onPressed == null ? '_disabled' : ''}.svg',
            height: 20,
          ),
        ) {
    this.onPressed = button.onPressed == null
        ? null
        : () {
            onPressed?.call();
            button.onPressed?.call();
          };
  }

  /// Callback, called when this [ChatMoreWidget] is pressed.
  late final void Function()? onPressed;

  /// Indicator whether this [ChatMoreWidget] is pinned.
  final bool pinned;

  /// Callback, called when this [ChatMoreWidget] is pinned.
  final void Function()? onPin;

  /// Label to display.
  final String label;

  /// Icon to display.
  final Widget icon;

  @override
  State<ChatMoreWidget> createState() => _ChatMoreWidgetState();
}

/// State of a [ChatMoreWidget] maintaining the [_hovered].
class _ChatMoreWidgetState extends State<ChatMoreWidget> {
  /// Indicator whether this [ChatMoreWidget] is hovered.
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final bool disabled = widget.onPressed == null;

    return IgnorePointer(
      ignoring: disabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        opaque: false,
        child: WidgetButton(
          onPressed: widget.onPressed,
          child: Container(
            width: double.infinity,
            color: _hovered ? style.colors.onBackgroundOpacity2 : null,
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16),
                SizedBox(
                  width: 26,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 100),
                    scale: _hovered ? 1.05 : 1,
                    child: widget.icon,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  // style: disabled
                  //     ? style.fonts.bodyLargePrimaryHighlightLightest
                  //     : style.fonts.bodyLargePrimary,
                ),
                const Spacer(),
                const SizedBox(width: 16),
                WidgetButton(
                  onPressed: widget.onPin ?? () {},
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: Center(
                      child: AnimatedButton(
                        child: AnimatedSwitcher(
                          duration: 100.milliseconds,
                          child: widget.pinned
                              ? const SvgImage.asset(
                                  'assets/icons/unpin.svg',
                                  key: Key('Unpin'),
                                  width: 15.5,
                                  height: 17,
                                )
                              : Transform.translate(
                                  offset: const Offset(0.5, 0),
                                  child: SvgImage.asset(
                                    'assets/icons/pin${widget.onPin == null || disabled ? '_disabled' : ''}.svg',
                                    key: const Key('Pin'),
                                    width: 9.65,
                                    height: 17,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
