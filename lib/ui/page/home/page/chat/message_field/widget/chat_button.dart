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

import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';
import 'buttons.dart';

/// [AnimatedButton] with an [icon].
class ChatButtonWidget extends StatelessWidget {
  /// Constructs a [ChatButtonWidget] from the provided [ChatButton].
  ChatButtonWidget(
    ChatButton button, {
    super.key,
    this.enabled = true,
    this.height = 56,
    void Function(Map<String, dynamic>? arguments)? onPressed,
  })  : onPressed = onPressed ?? button.onPressed,
        onLongPress = null,
        icon = Transform.translate(
          offset: button.offset,
          child: button.icon == null
              ? SvgIcon(button.asset)
              : SvgImage.network(button.icon!),
        ),
        disabledIcon = Transform.translate(
          offset: button.offset,
          child: button.icon == null
              ? SvgIcon(button.disabled ?? button.asset)
              : Opacity(opacity: 0.7, child: SvgImage.network(button.icon!)),
        );

  /// Constructs a send/forward [ChatButtonWidget].
  ChatButtonWidget.send({
    super.key,
    bool forwarding = false,
    this.onPressed,
    this.onLongPress,
  })  : icon = SvgIcon(forwarding ? SvgIcons.forward : SvgIcons.send),
        enabled = true,
        disabledIcon = null,
        height = 56;

  /// Callback, called when this [ChatButtonWidget] is pressed.
  final void Function(Map<String, dynamic>? arguments)? onPressed;

  /// Callback, called when this [ChatButtonWidget] is long-pressed.
  final void Function()? onLongPress;

  /// Icon to display.
  final Widget icon;

  /// Disabled icon to display.
  final Widget? disabledIcon;

  final bool enabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool disabled = !enabled || onPressed == null;

    return AnimatedButton(
      onPressed: disabled ? null : () => onPressed?.call(null),
      onLongPress: onLongPress,
      enabled: !disabled,
      child: SizedBox(
        width: 50,
        height: height,
        child: Center(child: disabled ? (disabledIcon ?? icon) : icon),
      ),
    );
  }
}
