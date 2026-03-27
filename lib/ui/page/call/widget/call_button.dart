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

import '/themes.dart';
import '/ui/page/call/controller.dart';
import '/ui/widget/svg/svg.dart';
import 'round_button.dart';

/// [RoundFloatingButton] optionally displaying its [hint] according to the
/// specified [hinted] and [expanded].
class CallButtonWidget extends StatelessWidget {
  const CallButtonWidget({
    super.key,
    required this.asset,
    this.offset,
    this.onPressed,
    this.hint,
    this.hinted = true,
    this.expanded = false,
    this.opaque = false,
    this.color,
    this.border,
    this.constrained = false,
    bool big = false,
    this.builder = _defaultBuilder,
    this.shadows = false,
  }) : size = constrained
           ? null
           : (big ? 60 : CallController.buttonSize) + (expanded ? 40 : 0);

  /// [SvgData] to display.
  final SvgData asset;

  /// [Offset] to apply to the [asset].
  final Offset? offset;

  /// Size of this [CallButtonWidget].
  final double? size;

  /// Callback, called when this [CallButtonWidget] is pressed.
  final void Function()? onPressed;

  /// Text that will show above the button on a hover.
  final String? hint;

  /// Indicator whether [hint] should be displayed above the button, or under it
  /// otherwise.
  final bool hinted;

  /// Indicator whether the [hint] should be always displayed under the button.
  final bool expanded;

  /// Indicator whether this [CallButtonWidget] should be constrained.
  final bool constrained;

  /// Indicator whether this [CallButtonWidget] should be less transparent.
  final bool opaque;

  /// Background color of this [CallButtonWidget].
  final Color? color;

  /// Border style of this [CallButtonWidget].
  final BoxBorder? border;

  /// Builder building the [asset] and the rounded button around it.
  final Widget Function(BuildContext context, Widget child) builder;

  /// Indicator whether the [hint] should be displayed with shadows or not.
  final bool shadows;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return SizedBox.square(
      dimension: size,
      child: RoundFloatingButton(
        icon: asset,
        offset: offset,
        color:
            color ??
            (opaque
                ? style.colors.onSecondaryOpacity88
                : onPressed == null
                ? style.colors.onBackgroundOpacity7
                : style.colors.onPrimaryOpacity10),
        hint: !expanded && hinted ? hint : null,
        text: expanded || constrained ? hint : null,
        minified: !constrained,
        showText: expanded,
        border: border,
        onPressed: onPressed,
        builder: builder,
        shadows: shadows,
      ),
    );
  }

  /// Returns the [child].
  static Widget _defaultBuilder(BuildContext context, Widget child) => child;
}
