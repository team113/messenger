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

import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';
import 'buttons.dart';

/// [AnimatedButton] with an [icon].
class ChatButtonWidget extends StatelessWidget {
  /// Constructs a [ChatButtonWidget] from the provided [ChatButton].
  ChatButtonWidget(ChatButton button, {super.key})
    : onPressed = button.onPressed,
      icon = Transform.translate(
        offset: button.offset,
        child: SvgIcon(button.asset),
      ),
      disabledIcon = Transform.translate(
        offset: button.offset,
        child: SvgIcon(button.disabled ?? button.asset),
      );

  /// Constructs a send/forward [ChatButtonWidget].
  ChatButtonWidget.send({super.key, this.onPressed})
    : icon = SvgIcon(SvgIcons.send),
      disabledIcon = SvgIcon(SvgIcons.sendDisabled);

  /// Callback, called when this [ChatButtonWidget] is pressed.
  final void Function()? onPressed;

  /// Icon to display.
  final Widget icon;

  /// Disabled icon to display.
  final Widget? disabledIcon;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;

    return AnimatedButton(
      onPressed: disabled ? null : onPressed,
      enabled: !disabled,
      child: SizedBox(
        width: 50,
        height: 56,
        child: Center(child: disabled ? (disabledIcon ?? icon) : icon),
      ),
    );
  }
}
