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

/// [AnimatedButton] with an [asset] icon.
class ChatButtonWidget extends StatelessWidget {
  const ChatButtonWidget({
    super.key,
    required this.asset,
    this.assetWidth,
    this.asseHeight,
    this.offset = Offset.zero,
    this.onPressed,
    this.onLongPress,
  });

  /// Asset name of this [ChatButtonWidget].
  final String asset;

  /// Optional width of the [asset] icon.
  final double? assetWidth;

  /// Optional height of the [asset] icon.
  final double? asseHeight;

  /// Optional [offset] of the [asset] icon.
  final Offset offset;

  /// Callback, called when this [ChatButtonWidget] is pressed.
  final void Function()? onPressed;

  /// Callback, called when this [ChatButtonWidget] is long-pressed.
  final void Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      child: SizedBox(
        width: 50,
        height: 56,
        child: Center(
          child: Transform.translate(
            offset: offset,
            child: SvgImage.asset(
              'assets/icons/$asset.svg',
              width: assetWidth,
              height: asseHeight,
            ),
          ),
        ),
      ),
    );
  }
}

/// Visual representation of a [ChatButton] with a [ChatButton.hint].
class HintedChatButtonWidget extends StatefulWidget {
  const HintedChatButtonWidget(
    this.button, {
    super.key,
    this.pinned = false,
    this.onPinned,
    this.onPressed,
  });

  /// [ChatButton] of this [HintedChatButtonWidget].
  final ChatButton button;

  /// Indicator whether this [HintedChatButtonWidget] is pinned.
  final bool pinned;

  /// Callback, called when this [HintedChatButtonWidget] is pinned.
  final void Function()? onPinned;

  /// Callback, called when this [HintedChatButtonWidget] is pressed.
  final void Function()? onPressed;

  @override
  State<HintedChatButtonWidget> createState() => _HintedChatButtonWidgetState();
}

/// State of a [HintedChatButtonWidget] maintaining a [_hovered] indicator.
class _HintedChatButtonWidgetState extends State<HintedChatButtonWidget> {
  /// Indicator whether this [HintedChatButtonWidget] is hovered.
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;
    bool disabled = widget.button.onPressed == null;

    return IgnorePointer(
      ignoring: disabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        opaque: false,
        child: WidgetButton(
          onPressed: () {
            widget.button.onPressed?.call();
            widget.onPressed?.call();
          },
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
                    child: Transform.translate(
                      offset: widget.button.offsetMini,
                      child: SvgImage.asset(
                        'assets/icons/${widget.button.assetMini ?? widget.button.asset}${disabled ? '_disabled' : ''}.svg',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.button.hint,
                  style: disabled
                      ? style.fonts.bodyLargePrimaryHighlightLightest
                      : style.fonts.bodyLargePrimary,
                ),
                const Spacer(),
                const SizedBox(width: 16),
                WidgetButton(
                  onPressed: widget.onPinned ?? () {},
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
                                    'assets/icons/pin${widget.onPinned == null || disabled ? '_disabled' : ''}.svg',
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
