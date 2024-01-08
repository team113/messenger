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
  ChatButtonWidget(ChatButton button, {super.key})
      : onPressed = button.onPressed,
        onLongPress = null,
        icon = Transform.translate(
          offset: button.offset,
          child: SvgImage.asset(
            'assets/icons/${button.asset}.svg',
            height: 22,
          ),
        );

  /// Constructs a send/forward [ChatButtonWidget].
  ChatButtonWidget.send({
    super.key,
    bool forwarding = false,
    this.onPressed,
    this.onLongPress,
  }) : icon = SvgImage.asset(
          'assets/icons/${forwarding ? 'forward' : 'send'}.svg',
          width: forwarding ? 26 : 25.44,
          height: forwarding ? 22 : 21.91,
        );

  /// Callback, called when this [ChatButtonWidget] is pressed.
  final void Function()? onPressed;

  /// Callback, called when this [ChatButtonWidget] is long-pressed.
  final void Function()? onLongPress;

  /// Icon to display.
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      // onLongPress: onLongPress,
      child: SizedBox(width: 50, height: 56, child: Center(child: icon)),
    );
  }
}
