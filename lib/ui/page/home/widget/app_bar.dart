// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:ui';

import 'package:flutter/material.dart';

import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';

/// Custom stylized and decorated [AppBar].
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.leading = const [],
    this.actions = const [],
    this.padding,
    this.border,
    this.margin = EdgeInsets.zero,
    this.top = true,
    this.borderRadius,
    this.applySafeArea = true,
  });

  /// Primary centered [Widget] of this [CustomAppBar].
  final Widget? title;

  /// [Widget]s displayed in a row before the [title].
  final List<Widget> leading;

  /// [Widget]s displayed in a row after the [title].
  final List<Widget> actions;

  /// Padding to apply to the contents.
  final EdgeInsets? padding;

  /// Margin to apply to the contents.
  final EdgeInsets margin;

  /// [Border] to apply to this [CustomAppBar].
  final Border? border;

  /// Indicator whether [SafeArea.top] padding should be applied.
  final bool top;

  /// [BorderRadius] to display the borders of this [CustomAppBar] with.
  final BorderRadius? borderRadius;

  /// Indicator whether [SafeArea] should be applied to the bar.
  final bool applySafeArea;

  /// Height of the [CustomAppBar].
  static double get height {
    double padding = 0;
    if (router.context != null) {
      padding = MediaQuery.of(router.context!).padding.top;
    }

    return 60 + padding;
  }

  /// Height of the [CustomAppBar] without any safe additions.
  static double get rawHeight => 60;

  @override
  Size get preferredSize =>
      Size(double.infinity, applySafeArea ? height : rawHeight);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      height: applySafeArea ? height : rawHeight,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          CustomBoxShadow(
            blurRadius: 8,
            color: style.colors.onBackgroundOpacity13,
            blurStyle: BlurStyle.outer.workaround,
          ),
        ],
      ),
      child: ConditionalBackdropFilter(
        condition: style.cardBlur > 0,
        filter: ImageFilter.blur(
          sigmaX: style.cardBlur,
          sigmaY: style.cardBlur,
        ),
        borderRadius: borderRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border:
                border ??
                Border(
                  top: BorderSide.none,
                  left: style.cardBorder.left,
                  right: style.cardBorder.right,
                  bottom: style.cardBorder.bottom,
                ),
            color: style.cardColor,
          ),
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Spacer(),
              SizedBox(
                height: 59 - (padding?.top ?? 0) - (padding?.bottom ?? 0),
                child: NavigationToolbar(
                  centerMiddle: true,
                  middleSpacing: 0,
                  middle: DefaultTextStyle.merge(
                    style: style.fonts.large.regular.onBackground,
                    child: title ?? const SizedBox.shrink(),
                  ),
                  leading: leading.isEmpty
                      ? null
                      : Row(mainAxisSize: MainAxisSize.min, children: leading),
                  trailing: actions.isEmpty
                      ? null
                      : Row(mainAxisSize: MainAxisSize.min, children: actions),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
