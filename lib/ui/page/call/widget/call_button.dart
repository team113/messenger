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
import 'package:messenger/themes.dart';

import 'round_button.dart';

/// [RoundFloatingButton] optionally displaying its [hint] according to the
/// specified [hinted] and [expanded].
class CallButtonWidget extends StatelessWidget {
  const CallButtonWidget({
    super.key,
    required this.asset,
    this.assetWidth = 60,
    this.onPressed,
    this.hint,
    this.hinted = true,
    this.expanded = false,
    this.withBlur = false,
    this.color,
    this.border,
  });

  /// Asset to display.
  final String? asset;

  /// Width of the [asset].
  final double assetWidth;

  /// Callback, called when this [CallButtonWidget] is pressed.
  final void Function()? onPressed;

  /// Text that will show above the button on a hover.
  final String? hint;

  /// Indicator whether [hint] should be displayed above the button, or under it
  /// otherwise.
  final bool hinted;

  /// Indicator whether the [hint] should be always displayed under the button.
  final bool expanded;

  /// Indicator whether background should be blurred.
  final bool withBlur;

  /// Background color of this [CallButtonWidget].
  final Color? color;

  /// Border style of this [CallButtonWidget].
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return RoundFloatingButton(
      asset: asset,
      assetWidth: assetWidth,
      color: color ?? style.colors.onSecondaryOpacity50,
      hint: !expanded && hinted ? hint : null,
      text: expanded ? hint : null,
      withBlur: withBlur,
      border: border,
      onPressed: onPressed,
    );
  }
}
